+++
title = 'GitLab SRE baseline: test the user workflow'
date = 2023-01-19T20:30:00+01:00
type = 'posts'
tags = ['ops']
+++

A large internal GitLab installation should not be measured only by component
health. A green status page for Rails, Sidekiq, Redis, PostgreSQL, Gitaly, and
load balancers does not prove that engineers can clone a repository and push a
change from their normal workstation or CI environment.

The baseline SRE check is the user workflow:

```text
authenticate -> clone -> change -> push -> fetch -> view result
```

That path crosses more boundaries than a normal service liveness probe. It uses
DNS, TLS, SSH or HTTPS authentication, GitLab Shell, Rails authorization, Gitaly,
repository storage, and sometimes corporate network policy. A failure in any
one of those layers can look like "GitLab is down" to the user.

The useful probe matrix is small:

```text
protocol: ssh, https
location: office, vpn, ci-runner
repo size: tiny fixture, normal project
operation: clone, fetch, push
identity: normal user, bot token
```

Each result should record latency and failure class, not only pass/fail:

```text
workflow=ssh_clone location=vpn repo=tiny status=fail
class=auth_rejected duration_ms=840
```

The classification matters during incidents. `auth_rejected` points toward
identity, token, SSH key, or GitLab Shell state. `connect_timeout` points toward
network or load balancer state. `gitaly_unavailable` points toward repository
storage. Without that split, every failed clone creates the same generic alert.

The shell-level version is enough to start:

```sh
set -euo pipefail
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

git clone "$REMOTE" "$workdir/repo"
cd "$workdir/repo"
date -u > sre-probe.txt
git add sre-probe.txt
git commit -m "sre probe"
git push origin HEAD:sre-probe
git fetch --all --prune
```

The production version needs cleanup, separate credentials, bounded runtime, and
structured output. The core workflow should stay this direct. A probe that does
not behave like a real user will miss exactly the failures users report.

Public references that map to this mental model:

* [GitLab Gitaly overview](https://docs.gitlab.com/administration/gitaly/) for repository access boundaries;
* [GitLab repository checks](https://docs.gitlab.com/administration/repository_checks/) for repository integrity checks;
* [GitLab Gitaly troubleshooting](https://docs.gitlab.com/administration/gitaly/troubleshooting/) for storage and RPC failure modes.
