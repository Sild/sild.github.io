+++
title = 'Treating parser errors as product data'
date = 2024-07-24T20:50:00+02:00
type = 'posts'
tags = ['crypto', 'ops']
+++

When an indexer cannot parse something, it is tempting to treat the error as a
local bug and move on after the fix. That loses useful information. Parser
errors are also product data: they tell which external structures the system
does not understand yet, how often that happens, and whether the failure affects
real downstream workflows.

Parser failures should stay structured:

* source position or block height;
* object type if it is known;
* short error class;
* raw input reference;
* whether processing stopped or continued.

This keeps the error useful after the immediate debugging session. A plain log
line says "something failed". A structured parser error can answer whether the
same shape appeared before, whether a deploy changed failure rate, and whether
the skipped objects are safe to ignore temporarily.

The important part is not building a complex error system early. It is avoiding
the habit of turning every unknown into one generic "parse failed" bucket.

The log event can stay compact:

```json
{
  "event": "parse_failed",
  "height": 123456,
  "object": "transaction",
  "reason": "unknown_variant",
  "action": "skipped"
}
```

Once the event has fields, dashboards and alerts can group by `reason` instead
of forcing someone to grep free-form text during an incident.
