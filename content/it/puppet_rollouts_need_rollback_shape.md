+++
title = 'Puppet rollouts need a rollback shape'
date = 2023-02-16T20:10:00+01:00
type = 'posts'
tags = ['ops']
+++

Configuration management fails differently from application code. A bad service
release can often be rolled back by deploying the previous artifact. A bad
Puppet change can touch packages, files, permissions, services, cron jobs, and
feature flags across many machines in one run. The rollback plan has to be part
of the change, not an incident-time invention.

The minimum review checklist:

```text
scope: which node class or role changes?
blast radius: how many hosts match?
state transition: create, update, delete?
rollback: previous manifest or explicit revert?
canary: which host proves the change?
verification: which command proves user impact is unchanged?
```

The dangerous changes are not always large. Removing one file resource or
changing one template default can have wider impact than adding a new service.
The review should classify resources by reversibility:

```text
low risk: additive file, disabled service unit, new metric
medium risk: template change, package version pin, cron schedule
high risk: delete resource, permission change, network listener, storage mount
```

The canary should run with observable output before the broad rollout:

```sh
puppet agent --test --noop
puppet agent --test
systemctl status gitlab-runsvdir
git clone "$REMOTE" /tmp/gitlab-puppet-check
```

`--noop` is not a guarantee. It proves the catalogue shape, not the runtime
behavior. The non-noop canary must still run a user-level workflow check after
the catalogue applies.

Good rollout notes include both the forward and reverse actions:

```text
forward:
  merge manifest
  run canary on gitlab-edge-01
  wait for user workflow probe
  expand to role batch

rollback:
  revert manifest commit
  run canary on same host
  verify file/service returned to previous state
  rerun user workflow probe
```

This keeps configuration management operational rather than ceremonial. The goal
is not to make Puppet changes slow. The goal is to make a failed change bounded,
observable, and reversible.

Reference: [Puppet agent command documentation](https://www.puppet.com/docs/puppet/latest/man/agent.html).
