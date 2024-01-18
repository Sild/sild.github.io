+++
title = 'GitLab project migrations need reversible batches'
date = 2024-01-18T20:15:00+01:00
type = 'posts'
tags = ['ops']
+++

Project migration work around GitLab is easy to underestimate because a single
project move looks small. The hard part is not moving one repository. The hard
part is repeating that operation across many projects without losing ownership,
permissions, hooks, CI variables, repository integrity, or user confidence.

The migration unit should be a batch, not a one-off script invocation:

```text
batch id:
source group:
target group:
project count:
expected repository sizes:
owners notified:
freeze window:
rollback action:
verification probes:
```

The batch must have an inventory before it has automation:

```sh
gitlab-projects export \
  --group platform-tools \
  --fields path,visibility,default_branch,archived,storage,size \
  > batch-2024-01-platform-tools.tsv
```

The exact tool does not matter as much as the contract. The migration code should
consume an explicit inventory and write an explicit result file:

```text
project_path,status,old_url,new_url,repo_check,clone_check,push_check
tools/api,ok,old.example/tools/api,new.example/tools/api,ok,ok,ok
tools/web,blocked,old.example/tools/web,,pending,not_run,not_run
```

That result file becomes the handoff between migration execution, support, and
rollback. A chat message is not enough; it cannot be replayed or audited.

The verification path should use user-visible operations:

```sh
git clone "$NEW_REMOTE" repo
cd repo
git fetch --all --prune
git push --dry-run origin HEAD
```

Repository integrity checks still matter, but they do not replace workflow
checks. A repository can be internally valid and still unreachable from the
network or unavailable to the expected group.

Rollback also needs a contract. If the old project stays read-only for a window,
the rollback can point users back to it. If the old project is deleted
immediately, rollback becomes a restore operation and the batch risk increases.

References:

* [GitLab repository storage](https://docs.gitlab.com/administration/repository_storage_paths/);
* [GitLab repository checks](https://docs.gitlab.com/administration/repository_checks/);
* [GitLab Gitaly overview](https://docs.gitlab.com/administration/gitaly/).
