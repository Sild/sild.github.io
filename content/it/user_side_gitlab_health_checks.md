+++
title = 'User-side GitLab health checks from SRE work'
date = 2023-06-22T19:50:00+02:00
type = 'posts'
tags = ['ops']
+++

Internal health checks often answer the wrong question. A service can report
that all components are green while users still cannot finish the workflow they
care about. For Git hosting, the workflow is not "is the web process alive?" It
is closer to "can users clone, push, fetch, and authenticate from the environments
where people actually work?"

User-side checks answer that workflow question directly. They are small probes
that behave like a normal user:

* create or reuse a test repository;
* clone it over the same protocol users use;
* make a tiny change;
* push and fetch;
* record latency, error class, and environment.

The important detail is classification. "Clone failed" is less useful than
"clone failed because DNS resolution failed from this network" or "push failed
after authentication". Even rough categories reduce the search space during an
incident.

These checks should not replace internal metrics. They connect internal metrics
to the user journey. When both exist, the debugging path is shorter: the probe
says which workflow is broken, and service metrics explain where to look next.

A probe can be implemented as a shell-level smoke test before it becomes a
service:

```sh
git clone "$REMOTE" repo
cd repo
date > probe.txt
git add probe.txt
git commit -m "probe"
git push
git fetch --all
```

The production version should record timing and classify failures, but the
workflow itself should stay this simple.
