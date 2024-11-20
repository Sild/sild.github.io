+++
title = 'Load testing indexers before trusting capacity'
date = 2024-11-20T20:20:00+01:00
type = 'posts'
tags = ['crypto', 'ops']
+++

Load testing an indexer is different from load testing a request-response API.
There is still throughput, but the more important questions are about
lag, recovery, write amplification, and how the system behaves after a pause.

The baseline scenario is simple:

* start from an empty or known snapshot;
* feed historical data faster than real time;
* measure processing lag and database writes;
* introduce a short dependency outage;
* verify that the service catches up without manual cleanup.

This reveals problems that a happy-path benchmark hides. A service may process
normal traffic comfortably but fall behind after one slow compaction. It may
recover from a dependency outage only by retrying so aggressively that it hurts
the dependency again.

The result of a load test should be a capacity story, not only a number. "The
indexer processed N objects per second" is useful. "The indexer can absorb a
30-minute source outage and catch up in two hours without operator action" is
much closer to an operational guarantee.

A minimal report template:

```text
input rate:
steady-state lag:
max lag after outage:
catch-up time:
db write p95:
operator action required:
```

This is more useful than a single throughput number because it describes how the
system behaves when production stops being polite.
