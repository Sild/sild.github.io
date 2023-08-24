+++
title = 'Keeping GitLab test environments useful'
date = 2023-08-24T19:45:00+02:00
type = 'posts'
tags = ['ops']
+++

A test environment is useful only while people trust it. Once it drifts too far
from production or becomes hard to reset, engineers stop using it for serious
changes and fall back to local assumptions.

For internal GitLab work, the useful test environment is not a perfect clone of
production. It is a controlled place where common operational changes can be
repeated:

* deploy a known version;
* seed enough data to exercise real workflows;
* run clone, push, and migration checks;
* reset state without asking another team;
* keep configuration differences visible.

The reset path is the most important part. If every experiment leaves the
environment slightly different, the next experiment starts with unknown state.
That makes failures harder to interpret and slowly turns the environment into a
pet server.

Setup scripts should be treated as product code. They need review, versioning,
and deterministic defaults. The test environment becomes more valuable when it is easy
to destroy and recreate than when it survives for a long time.

The commands should be stable enough to paste into a runbook:

```sh
envctl create gitlab-test --version 16.x
envctl seed gitlab-test --fixture small-team
envctl check gitlab-test --workflow clone,push,fetch
envctl destroy gitlab-test
```

Even if the real tool has a different name, the interface should stay close to
four operations: create, seed, check, destroy.
