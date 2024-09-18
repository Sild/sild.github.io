+++
title = 'Schema boundaries when the source is external'
date = 2024-09-18T21:30:00+02:00
type = 'posts'
tags = ['crypto', 'dev']
+++

Internal schemas can be negotiated. External schemas have to be respected. This
is a practical difference when building infrastructure around blockchain data,
third-party APIs, or generated protocol objects.

The important boundary is between "source format" and "service format". Source
format code should preserve what the external system actually said. Service
format code should expose the subset and invariants that the application needs.
Mixing those two makes every caller responsible for remembering which fields are
trusted and which fields are still raw.

Some small rules help:

* do not normalize away source quirks before they are observable;
* keep conversion functions explicit and test them with real examples;
* use named domain types instead of maps of loosely related values;
* record which source version or protocol version the parser expects.

The payoff is debugging. When something looks wrong in the indexed state, the
team can compare raw source data, parsed source objects, and final domain
objects without guessing where meaning changed.

The handoff should be explicit in code:

```text
RawBytes -> SourceObject -> ValidatedObject -> DomainObject
```

Tests should cover every arrow. If a caller can construct `DomainObject` without
passing validation, the boundary is only documentation and will eventually be
skipped.
