+++
title = 'GitLab architecture as SRE failure domains'
date = 2023-03-16T20:40:00+01:00
type = 'posts'
tags = ['ops']
+++

GitLab is easier to operate when its architecture is drawn as request paths,
state owners, and asynchronous boundaries. Component liveness is not enough:
`puma` can be healthy while repository reads are blocked on Gitaly, and Sidekiq
can be running while queues are stuck behind Redis or database pressure.

The useful component map is:

```text
HTTP client
  -> NGINX
  -> GitLab Workhorse
  -> Puma / GitLab Rails
  -> PostgreSQL, Redis, Gitaly or Praefect

SSH git client
  -> GitLab Shell
  -> Rails API for authorization
  -> Gitaly or Praefect

background work
  -> Redis queue
  -> Sidekiq
  -> PostgreSQL, Redis, Gitaly, object storage
```

The names matter during incidents:

* `GitLab Workhorse` is the smart reverse proxy in front of Rails. It handles
  expensive HTTP paths such as uploads, downloads, and Git over HTTP when Rails
  delegates that work.
* `Puma` runs the GitLab Rails web and API application.
* `Sidekiq` runs background jobs. It depends on Redis for job queues and on the
  same state backends that the job touches.
* `PostgreSQL` stores application metadata: users, projects, permissions,
  issues, merge requests, CI metadata, and other relational state.
* `Redis` is used for queues, cache-like state, and coordination paths. It is
  not the source of truth for Git repository contents.
* `Gitaly` is the Git RPC service. It owns Git repository access for GitLab and
  should be treated as the supported boundary around repositories on disk.
* `Praefect` is the Gitaly Cluster proxy. It routes repository RPCs to Gitaly
  nodes and tracks replication state in a database separate from the GitLab
  application database.

That split gives a practical incident checklist. Start with the user operation,
then map it to the component chain.

```text
web page slow
  -> NGINX / Workhorse / Puma
  -> PostgreSQL for metadata
  -> Redis for cache/session/queue interactions
  -> Gitaly if the page reads repository data

git clone over SSH fails
  -> network / load balancer / SSH
  -> GitLab Shell
  -> Rails API authorization
  -> Gitaly or Praefect

merge request stuck after push
  -> GitLab Shell or Workhorse accepts the push
  -> Gitaly writes repository data
  -> Redis receives jobs
  -> Sidekiq processes hooks, pipelines, and notifications
  -> PostgreSQL records resulting state
```

The first command set should identify which service group is degraded:

```sh
sudo gitlab-ctl status
sudo gitlab-ctl status puma sidekiq gitaly postgresql redis gitlab-workhorse
sudo gitlab-rake gitlab:check SANITIZE=true
sudo gitlab-rake gitlab:gitaly:check
```

For a repository-specific failure, run a user-level probe and keep Git trace
output. The trace is noisy, but it separates authentication, HTTP transport, SSH
transport, and repository access failures:

```sh
GIT_TRACE=1 GIT_CURL_VERBOSE=1 git ls-remote "$HTTPS_REMOTE" HEAD
GIT_TRACE=1 git ls-remote "$SSH_REMOTE" HEAD
```

Then tail only the logs on the path being tested:

```sh
sudo gitlab-ctl tail gitlab-workhorse
sudo gitlab-ctl tail puma
sudo gitlab-ctl tail sidekiq
sudo gitlab-ctl tail gitaly
```

For Gitaly Cluster, include Praefect explicitly:

```sh
sudo gitlab-ctl tail praefect
sudo gitlab-ctl praefect check
```

The anti-pattern is scaling the first saturated graph without checking its
dependencies. More Puma or Sidekiq workers can increase connection pressure on
PostgreSQL, Redis, Gitaly, Praefect, PgBouncer, or an internal load balancer.
That can move the bottleneck instead of removing it.

The architecture runbook should therefore record dependencies in both
directions:

```text
component: sidekiq
upstream: redis queue, scheduled jobs, web/API enqueues
downstream: postgresql, redis, gitaly/praefect, object storage, smtp
primary symptoms: queue latency, retry growth, job duration, downstream timeout
safe first action: classify queue and downstream saturation before adding workers
```

For repository paths, the important boundary is stricter:

```text
repository metadata -> PostgreSQL
repository objects  -> Gitaly storage
repository RPC path -> Gitaly, or Praefect -> Gitaly in clustered setups
```

Direct access to repository files bypasses the service that owns repository
consistency, caching, and RPC behavior. Operational scripts should use GitLab
APIs, Rake tasks, or Gitaly-aware tooling unless a vendor-approved recovery
procedure says otherwise.

References:

* [GitLab architecture overview](https://docs.gitlab.com/development/architecture/);
* [GitLab Workhorse](https://docs.gitlab.com/development/workhorse/);
* [Gitaly](https://docs.gitlab.com/administration/gitaly/);
* [External Sidekiq instance requirements](https://docs.gitlab.com/administration/sidekiq/);
* [Gitaly Cluster / Praefect configuration](https://docs.gitlab.com/administration/gitaly/praefect/configure/);
* [GitLab reference architectures](https://docs.gitlab.com/administration/reference_architectures/).
