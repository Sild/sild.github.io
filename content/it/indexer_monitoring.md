+++
title = 'Monitoring an indexer beyond "is it alive"'
date = 2025-02-19T20:30:00+01:00
type = 'posts'
tags = ['crypto', 'ops']
+++

A process can be alive and still useless. That is especially true for an indexer:
the binary may run, the database may accept connections, and the HTTP endpoint
may return 200 while the indexed state is hours behind.

The first metric is progress. For blockchain data this means the latest
observed height, the latest processed height, and the difference between them.
Lag is more useful than uptime because it describes the user-visible problem
directly.

The second group is quality:

* parse failures by reason;
* skipped objects by category;
* retries and retry age;
* queue size and oldest item age;
* database write failures and slow writes.

The third group is operational cost. Disk growth, compaction, cache hit rate,
and batch size tell whether the service is becoming more expensive before it
becomes broken.

Alerts should mention the next action. "Indexer lag is high" is a symptom.
"Indexer lag is high and input queue is growing" points to processing capacity.
"Indexer lag is high and source RPC errors increased" points to an upstream
dependency. Both alerts can wake someone up; only the second version narrows the
first debugging step.

The baseline dashboard needs these panels:

```text
source_height - indexed_height
oldest_queue_item_age
parse_errors by reason
db_write_latency p50/p95/p99
disk_used and disk_growth_per_day
```

For alerting, the useful threshold is often age rather than count. A queue with
10,000 fresh items may be normal; one item stuck for an hour is a stronger
signal.
