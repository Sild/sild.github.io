+++
title = 'Backups and restore thinking for large indexer data'
date = 2024-12-12T22:15:00+01:00
type = 'posts'
tags = ['crypto', 'ops']
+++

For an indexer, backup strategy is not only about saving bytes. The real question
is how long it takes to trust the service again after something goes wrong.

There are two main recovery paths. The first is replaying from the source of
truth. It is conceptually clean, but it can be too slow when the historical data
is large. The second is restoring a snapshot. It is faster, but only if the
snapshot format, metadata, and validation process are deterministic enough to run
under pressure.

Backup plans should be written around restore questions:

* what exact version of code produced this data?
* which chain height or source offset does it represent?
* can we verify the snapshot before exposing it to users?
* how much data can be lost without breaking downstream assumptions?
* how often do we test restore on machines that are not the original host?

The last point matters most. A backup that only restores on the same machine is
closer to a local cache than a disaster-recovery plan.

Restore drills should be small and frequent. If restore is practiced only during
incidents, every unknown arrives at the worst possible time.

The restore runbook should be executable, not literary:

```sh
# example shape, not a universal command
systemctl stop indexer
restore-snapshot --snapshot snapshot-2024-12-12 --target /data/indexer
indexer verify --height 123456 --db /data/indexer
systemctl start indexer
```

The important command is `verify`. A restore that only starts the process does
not prove the indexed state is usable.
