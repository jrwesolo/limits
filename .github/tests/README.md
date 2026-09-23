Tests for the CI scripts
========================

Reference only. This branch is not meant to be merged, and nothing on it
runs in CI. It exists so the suites that were used to develop the scripts
in `.github/scripts` are not lost, and so anyone changing those scripts
has a starting point rather than a blank page.

The tip of this branch is the tooling branch plus this directory.

Running them
------------

```
.github/tests/run-all
```

`run-all` warms the toolchain first, then runs each suite and sums the
results. A single suite works the same way:

```
.github/tests/test-check-version
```

Both take the checkout they are in, derived from their own location. Set
`REPO_ROOT` to point them at a different tree.

A suite that cannot run where it finds itself says so and skips, rather
than reporting failures that all mean the same thing. `run-all` exits 0 on
a machine with neither Docker nor Cinc, having run everything that does not
need them.

`test-linters-for-real` drives real containers and skips without Docker.
`test-lint-scripts` and `test-check-renovate` look like they need Docker
and do not: they stub it and assert what the script asked it to run.
`test-list-payload`, `test-e2e` and `test-install-cinc` need Cinc
Workstation, and check that it runs rather than that it is on PATH, since
an install that cannot execute is the interesting way for it to be absent.

What the suites are
-------------------

`harness.bash` carries the assertions and the mutation helpers. Every
failure assertion names the exit status it expects rather than accepting
any non-zero one, because a suite run against a checkout with no `main`
branch once had `check-version` die inside `git fetch` and report green.
Every mutation goes through a helper that fails when the edit changed
nothing, because an in-place edit that matches nothing exits zero and
leaves a script that reads exactly like one that caught the mutant.

Each suite builds a sandbox under `mktemp -d` and works there. Nothing
writes to the checkout.

Two suites take their subject from the committed tree rather than from the
working copy: `test-e2e` clones and checks out, and `test-lint-scripts`
lints what is tracked. Editing a script and running them without
committing tests the previous state, which reads as a change that had no
effect. Commit first.

Known rough edges
-----------------

These are why the directory is here rather than in the pipeline:

* `test-e2e` assumes the checkout declares the same version as `main`. Run
  it from a release branch, where the version is bumped and not yet merged,
  and eleven assertions fail: `check-version` correctly takes its other
  path, the one that checks the tag and the changelog, so the payload
  comparison this suite is mostly about never happens. Nothing is wrong
  with either side, but the suite has no way to say so.
