+++
title = 'Runtime experiments without waiting for releases'
date = 2025-03-19T21:05:00+01:00
type = 'posts'
tags = ['search', 'dev']
+++

In a high-load ranking or bidding system, release speed affects product speed.
If every model estimate or scoring change waits for a full release cycle, small
experiments become expensive and teams test fewer ideas.

The useful pattern is a controlled runtime switch:

* the service has a stable interface for receiving prepared data;
* each experiment has a version and owner;
* fallback behavior is explicit;
* metrics separate experiment traffic from normal traffic;
* rollback is a configuration change, not a rebuild.

This is not the same as making everything dynamic. The hot path should still be
predictable, and the service should not accept arbitrary logic from outside.
Usually the safe boundary is data, weights, thresholds, or precomputed estimates,
not executable behavior.

The best experiments are simple to operate. A teammate should be able to answer
which version is active, how much traffic sees it, and how to disable it. If that
is not visible, runtime flexibility becomes another source of production risk.

The runtime config should be readable in one screen:

```yaml
experiment: bid_model_v42
traffic_percent: 5
data_version: 2025-03-19
fallback: bid_model_v41
owner: search-ranking
```

If the rollback is not obvious from this config, the experiment is too clever for
production.
