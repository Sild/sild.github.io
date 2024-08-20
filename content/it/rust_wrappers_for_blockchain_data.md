+++
title = 'Rust wrappers around blockchain data structures'
date = 2024-08-20T20:40:00+02:00
type = 'posts'
tags = ['crypto', 'dev']
+++

Rust makes illegal states visible at type boundaries. That matters when the
input data comes from a blockchain, because the difference between "bytes",
"parsed cell", "validated object", and "domain object used by the service" is
not cosmetic.

Wrappers around binary data should stay thin. A wrapper should not hide the cost
of parsing, clone large payloads silently, or pretend that a partially understood
object is complete. Its main job is to give names to states that already exist
in the system.

The practical pattern:

* parse into a low-level representation with explicit errors;
* convert into domain types only after the invariants are checked;
* keep serialization and debug output close to the type;
* avoid "helper" constructors that skip validation just to make tests shorter.

This is slower to write than a loose struct with public fields, but it pays back
when the codebase grows. New callers can see whether they are working with raw
transport data or an object that is safe to index. That boundary is more useful
than a long comment explaining what callers should remember.

The API shape should make each boundary visible:

```rust
let raw = RawCell::from_bytes(bytes)?;
let parsed = ParsedTransaction::try_from(raw)?;
let tx = IndexedTransaction::try_from(parsed)?;
```

Each conversion is a place to attach a specific error. That is better than one
large constructor that can fail for five unrelated reasons.
