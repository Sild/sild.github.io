+++
title = 'GitLab upgrades start with background migrations'
date = 2023-04-20T20:25:00+02:00
type = 'posts'
tags = ['ops']
+++

GitLab upgrades are not only package upgrades. A release can include database
schema changes, batched background migrations, Gitaly compatibility constraints,
and application-level behavior changes. The safe starting point is to verify
that asynchronous work from the previous version has finished before the next
upgrade begins.

The failure mode is predictable: package deployment succeeds, services restart,
and then the application spends operational time catching up on old background
work. That can degrade user workflows long after the deployment window appears
finished.

The pre-upgrade checklist should include:

```text
current version:
target version:
required stop versions:
background migrations pending:
database migrations pending:
Gitaly version compatibility:
repository check status:
user workflow probe:
rollback package:
```

For GitLab, background migration state is a first-class signal. The check should
be run before scheduling the upgrade and again immediately before the change
window:

```sh
sudo gitlab-rake gitlab:background_migrations:status
sudo gitlab-rake gitlab:check SANITIZE=true
sudo gitlab-rake gitlab:git:fsck
```

Exact commands vary by GitLab version and deployment model, so the runbook should
link to the version-specific documentation instead of relying on memory.

The operational decision is simple:

```text
pending background migration -> do not start next upgrade
failed migration             -> fix or document vendor-approved workaround
unknown migration state      -> treat as blocker
clean migration state        -> proceed to canary and user probes
```

The post-upgrade check should use the same probes as the pre-upgrade check.
Repository pages, clone/fetch/push, CI clone, and project search provide better
coverage than a single login test.

References:

* [GitLab background migrations before upgrade](https://docs.gitlab.com/update/background_migrations/);
* [GitLab integrity check Rake task](https://docs.gitlab.com/ee/administration/raketasks/check.html);
* [GitLab Gitaly troubleshooting](https://docs.gitlab.com/administration/gitaly/troubleshooting/).
