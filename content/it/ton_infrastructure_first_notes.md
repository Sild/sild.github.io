+++
title = 'First notes from moving into TON infrastructure'
date = 2024-06-18T21:10:00+02:00
type = 'posts'
tags = ['crypto', 'ops']
+++

TON infrastructure becomes easier to reason about when "blockchain" is not
treated as one large new domain. Most day-to-day work still looks like backend
engineering: read binary formats, move data through queues, keep services
observable, and make recovery repeatable.

The unfamiliar part was the shape of the data. A regular backend service can
often define its own schema and evolve it through migrations. A chain indexer
has to follow data that already exists, including historical decisions and edge
cases. If parsing is vague, every downstream component becomes vague too.

The first checklist is simple:

* keep raw inputs available long enough to debug parser mistakes;
* separate "we cannot parse this" from "this object is valid but not useful for
  this feature";
* make reindexing a normal operation, not a disaster scenario;
* add metrics around progress, lag, and skipped objects before optimizing speed.

The lesson is not TON-specific. Any system that ingests an external source of
truth needs explicit boundaries. The indexer should say what it saw, what it
understood, and what it deliberately ignored. That makes later mistakes smaller.

The first local notes for any new crypto component:

```text
source of truth:
unit of progress:
replay command:
verification command:
irreversible writes:
safe-to-ignore errors:
```

For TON context, the public [TON docs](https://docs.ton.org/) and
[ston-fi/ton](https://github.com/ston-fi/ton) source are better starting points
than private diagrams because they force terms to match public code.
