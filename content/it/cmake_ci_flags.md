+++
title = 'Making CMake CI faster and less mysterious'
date = 2024-10-17T19:35:00+02:00
type = 'posts'
tags = ['dev', 'ops']
+++

CI time is easy to accept as background noise. A build takes ten minutes, people
open another tab, and eventually everybody forgets that the delay is a tax on
every small change. The useful question is not "can we make CI fast?" but "which
part of this delay is accidental?"

With CMake projects, accidental cost often hides in flags and defaults:

* building targets that are not needed for the check;
* compiling examples or tests in jobs that only need a library;
* missing cache keys for dependencies;
* doing clean builds where incremental state would be safe;
* using one generic pipeline for very different validation tasks.

The first fix is measurement. Split the job into visible phases before changing
anything: configure, dependency restore, compile, test, package, upload. Once
each phase has timing, the slow part becomes a concrete target instead of a
general complaint.

The second fix is making the intended build shape explicit. A CI command with
named CMake options is easier to review than a pipeline that depends on local
defaults. When the flags say exactly which targets are required, the next person
can remove work without guessing whether it was important.

The best CI optimization is not clever. It is deleting work that never belonged
to that job.

For CMake jobs, the first useful output is the build shape itself:

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build build --target all --parallel
ctest --test-dir build --output-on-failure
```

If a CI job does not need tests, examples, or packaging, those switches should be
visible in the command. Hidden defaults are where slow pipelines become hard to
review.
