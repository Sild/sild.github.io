+++
title = 'Crypto introduction'
date = 2024-03-23T16:15:01+01:00
type = 'posts'
aliases = ['/posts/crypto_introduction/']
tags = ['crypto']
+++

Crypto infrastructure onboarding works better as a practical reading path than
as a theory dump. The useful split is:

* exchange mechanics: what a [DEX](https://www.coinbase.com/en-gb/learn/crypto-basics/what-is-a-dex) changes compared with a centralized exchange;
* network shape: how [The Open Network architecture](https://blog.ton.org/the-architecture-behind-the-open-network) organizes the TON system;
* implementation exercise: building a toy chain from a guide such as [Write your own blockchain](https://bigishdata.com/2017/10/17/write-your-own-blockchain-part-1-creating-storing-syncing-displaying-mining-and-proving-work/).

The implementation exercise is not about production code. It is a quick way to
make the vocabulary concrete:

```text
transaction -> block -> hash link -> validation -> fork choice
```

After that, TON-specific docs and source code are easier to read because the
questions become sharper: where is finality decided, what is stored, and what
must an indexer reconstruct?
