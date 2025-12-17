+++
title = 'Avoiding duplicate work in hot search paths'
date = 2025-12-17T20:45:00+01:00
type = 'posts'
tags = ['search', 'dev']
+++

Performance work in a hot path often starts with larger ideas: new data
structures, better algorithms, lower-level tricks. Sometimes those are needed.
Often the first measurable win is simpler: stop doing the same work twice.

Duplicate work hides in places that look harmless:

* normalizing the same request fields in several layers;
* checking the same eligibility rules for every candidate;
* converting between internal formats repeatedly;
* recalculating values that are stable for the whole request;
* loading metadata that could be batched or cached for one pass.

The safest way to find it is tracing one request through the code and writing
down where data changes shape. Every conversion should have a reason. Every loop
over candidates should answer whether the condition depends on the candidate or
only on the request.

This pass should happen before deeper optimization because it makes the code
easier to profile. Removing repeated checks can expose the real phases of the
algorithm: prepare request context, select candidates, score, filter, render.
Once those phases are explicit, later profiling has stable labels.

The goal is not to cache everything. The goal is to avoid paying per candidate
for facts that are already known per request.

The simplest investigation tool is still a request trace. The useful granularity
is one line per phase, not one line per function:

```text
parse_request=0.2ms
prepare_context=1.1ms
candidate_scan=8.4ms
score=5.7ms
render=0.6ms
```

After that, profiling can be targeted. If a value is computed in both
`prepare_context` and `score`, it belongs in the request context unless it really
depends on the candidate.
