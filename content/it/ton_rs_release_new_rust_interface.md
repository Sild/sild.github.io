+++
title = 'Releasing ton-rs as a cleaner Rust interface for TON'
date = 2025-10-27T19:20:00+01:00
type = 'posts'
tags = ['crypto', 'dev']
+++

The new [`ston-fi/ton-rs`](https://github.com/ston-fi/ton-rs) release moved the
Rust TON interface to a cleaner crate split: `ton_core` for cells, addresses,
and TLB primitives, and `ton` for higher-level blockchain, wallet, contract, and
client functionality. The old `tonlib-core` and `tonlib-client` line stays useful
for maintenance fixes, but the new API is the path for new code.

The developer-facing announcement was simple: the Rust library for TON
interaction finally shipped through the new crate line, compatibility with the
old `tonlib-*` APIs was not a goal, and feature requests should go to GitHub
issues instead of disappearing in chat. That is a good release shape: clear
migration direction, explicit maintenance policy, and one public place for
feedback.

The release was intentionally not a compatibility patch. The old interface had
too much historical shape from earlier bindings. Keeping source compatibility
would have preserved the parts that needed to change: broad types, weak
boundaries between raw cells and domain objects, and APIs that made parsing and
serialization decisions less visible than they should be.

The useful split is:

```text
ton_core:
  TonCell
  TonAddress
  TLB trait
  basic stable TON types
  TLB derive macros re-exported from ton_macros

ton:
  block TLB types
  adapters for dictionaries and other Rust collections
  wallet helpers
  TLClient / contract / emulator functionality behind features
```

That split matters because most TON infrastructure code touches two different
levels. It sometimes needs raw cell operations: bits, refs, BOC, hashes. It also
needs domain objects: transactions, messages, state init, jetton payloads,
wallet messages. Mixing those levels makes it too easy to pass a partially
parsed value into code that expects a validated domain object.

## Build and parse cells directly

`TonCell` is the low-level boundary. It exposes a scoped interface for building
and parsing cell data without forcing every caller into a high-level blockchain
type.

```rust
use ton_core::cell::TonCell;

fn build_payload() -> anyhow::Result<TonCell> {
    let mut payload = TonCell::builder();
    payload.write_bit(true)?;
    payload.write_bits([1, 2, 3], 24)?;
    payload.write_num(&4u8, 4)?;
    Ok(payload.build()?)
}

fn parse_payload(cell: &TonCell) -> anyhow::Result<()> {
    let mut parser = cell.parser();
    let flag = parser.read_bit()?;
    let bytes = parser.read_bits(24)?;
    let small: u8 = parser.read_num(4)?;
    parser.ensure_empty()?;

    assert!(flag);
    assert_eq!(bytes, vec![1, 2, 3]);
    assert_eq!(small, 4);
    Ok(())
}
```

The important part is that the parser state is explicit. `read_bit`,
`read_bits`, `read_num`, `read_next_ref`, `data_bits_left`, and `refs_left`
describe what the code consumes. That makes low-level parsing reviewable.

The cell boundary should stay small:

```text
raw BOC bytes -> TonCell -> parser -> typed object
typed object -> TLB -> TonCell -> BOC bytes
```

If a function receives `TonCell`, it should be clear whether it accepts any cell
or a cell that has already passed domain validation. If it receives a typed
object, parsing and validation should already be complete.

## Use `TLB` for domain types

The `TLB` trait is the more interesting interface. It gives domain objects a
uniform way to read from a parser, write into a builder, convert to a cell, and
serialize to BOC:

```rust
use ton_core::traits::tlb::TLB;

let tx = ton::block_tlb::Tx::from_boc_base64(tx_boc)?;
let tx_hash = tx.cell_hash()?;
let serialized = tx.to_boc_hex()?;
let parsed_back = ton::block_tlb::Tx::from_boc_hex(&serialized)?;
```

That pattern is much cleaner than spreading manual BOC handling across services.
The caller can choose the required boundary: `from_boc_base64` when input comes
from an external API, `from_cell` when the code already has a parsed cell,
`to_cell` when another object needs a reference, and `to_boc` when bytes must be
sent to the network or stored.

## Derive TLB where structure is mechanical

For local types, `#[derive(TLB)]` removes repetitive read/write code while still
making prefixes and field adapters visible in the type definition.

```rust
use ton_core::TLB;
use ton_core::traits::tlb::TLB;

#[derive(Debug, Clone, PartialEq, TLB)]
#[tlb(prefix = 0x01, bits_len = 8)]
struct ProbePayload {
    query_id: u64,
    flags: u8,
}

fn roundtrip(payload: ProbePayload) -> anyhow::Result<()> {
    let cell = payload.to_cell()?;
    let parsed = ProbePayload::from_cell(&cell)?;
    assert_eq!(parsed, payload);
    Ok(())
}
```

The prefix belongs in the type. Without it, callers need to remember which
constructor tag belongs to which payload. With it, parsing can fail at the
boundary with a wrong-prefix error instead of producing a plausible but wrong
object.

Enum support is useful for message families, but it needs discipline. Prefixes
must be specific enough that variants do not shadow each other. Null-prefix
variants should be last or avoided in nested enums because they can consume input
before a more specific variant is tried.

## Adapters keep Rust collections explicit

TON dictionaries are not Rust `HashMap`s, but infrastructure code often wants to
work with normal Rust collections. The adapter layer is the right place for that
translation.

```rust
use num_bigint::BigUint;
use std::collections::HashMap;
use ton::tlb_adapters::{DictKeyAdapterUint, DictValAdapterNum, TLBHashMap};
use ton_core::TLB;
use ton_core::traits::tlb::TLB;

#[derive(TLB)]
struct Balances {
    #[tlb(adapter = "TLBHashMap::<DictKeyAdapterUint<_>, DictValAdapterNum<_, 256>>::new(256)")]
    data: HashMap<usize, BigUint>,
}

let mut data = HashMap::new();
data.insert(1, BigUint::from(42u32));
let cell = Balances { data }.to_cell()?;
```

The adapter annotation is intentionally visible. It documents key width, value
encoding, and the fact that the Rust map is not serialized as an arbitrary local
container.

## Sending a message keeps serialization at the edge

Network sending should happen after the message has been built as a typed value.
The `ton_transfer` example in the repository follows that shape: build an
internal `Msg`, let the wallet create an external inbound message, then send BOC
bytes through `TLClient`.

```rust
use ton::block_tlb::{CommonMsgInfo, CommonMsgInfoInt, CurrencyCollection, Msg};
use ton_core::cell::TonCell;
use ton_core::traits::tlb::TLB;
use ton_core::types::tlb_core::{MsgAddress, TLBCoins, TLBEitherRef};

let transfer_msg = Msg {
    info: CommonMsgInfo::Int(CommonMsgInfoInt {
        ihr_disabled: false,
        bounce: false,
        bounced: false,
        src: MsgAddress::NONE,
        dst: wallet.address.to_msg_address(),
        value: CurrencyCollection::from_num(&50010u128)?,
        ihr_fee: TLBCoins::ZERO,
        fwd_fee: TLBCoins::ZERO,
        created_lt: 0,
        created_at: 0,
    }),
    init: None,
    body: TLBEitherRef::new(TonCell::empty().to_owned()),
};

let ext_in_msg = wallet.create_ext_in_msg(
    vec![transfer_msg.to_cell()?],
    seqno,
    expire_at,
    false,
)?;

let msg_hash = tl_client.send_msg(ext_in_msg.to_boc()?).await?;
```

The boundary is visible: domain message first, cell conversion second, BOC bytes
only at the network edge. That makes tests easier too. Unit tests can validate
`Msg` and `TonCell` output without a live node. Integration tests can cover
`TLClient` separately.

## Operational rules for using the crate

The release changes the default style for TON Rust code:

```text
1. Keep raw TonCell operations local to parsing/building boundaries.
2. Use typed TLB objects for business logic and indexing logic.
3. Put constructor prefixes on types, not in caller-side comments.
4. Use adapters when Rust collections cross the TON serialization boundary.
5. Convert to BOC only at storage, API, or network edges.
6. Keep old tonlib-core/tonlib-client code in maintenance paths only.
```

This is the main reason the release is useful. It is not only a new crate name.
It gives the codebase a narrower interface for cells, a reusable trait for BOC
roundtrips, and a cleaner place to put TON-specific serialization decisions.

References:

* [`ston-fi/ton-rs`](https://github.com/ston-fi/ton-rs);
* [`ton` crate documentation](https://docs.rs/crate/ton/0.0.3);
* [TON cells documentation](https://docs.ton.org/v3/documentation/data-formats/cells/exotic);
* [TON TL-B overview](https://docs.ton.org/v3/documentation/data-formats/tlb/overview).
