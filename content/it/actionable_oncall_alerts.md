+++
title = 'On-call alerts that explain the action'
date = 2023-10-19T21:20:00+02:00
type = 'posts'
tags = ['ops']
+++

An alert is not a dashboard link with a loud sound. It is a request for someone
to stop what they are doing and make a decision. If the alert does not explain
the decision, it is incomplete.

Useful production alerts contain four pieces of information:

* what changed;
* why it matters;
* how urgent it is;
* where to start.

For example, "error rate is above threshold" is technically true but weak. "API
write errors are above threshold for 10 minutes; successful writes are dropping;
check database saturation first" is a better page. It tells the person whether
the alert is user-visible and gives an initial hypothesis.

The action does not need to be perfect. It can be "check the runbook section
about queue growth" or "compare source RPC errors with indexer lag". The value
is that the alert author had to think through the first step while calm.

Alert cleanup belongs in the incident follow-up. If nobody used an alert during
debugging, treat it as noise until proven otherwise. If responders used it but
needed different context, the alert text should change. On-call quality improves
through small edits after real incidents, not through one large alerting rewrite.

A compact alert format is enough for most pages:

```text
Symptom:
Impact:
Likely first check:
Dashboard:
Runbook:
```

If the alert cannot fill these fields, it belongs on a dashboard before it
belongs in the paging path.
