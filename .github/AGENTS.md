CI conventions
==============

The workflow, the scripts its jobs run, and the composite action that
installs the toolchain. Together they decide whether a pull request may
merge and what gets released, so they are held to a higher standard than a
local helper. Each script and each workflow job carries its own detail in
a header comment; this file carries what they have in common.

What is here
------------

| Script | What it does |
| --- | --- |
| `check-version` | Fails a pull request proposing a version that cannot be released, or changing what would be published without a new version. Lists the published files that change, in the log and the job summary |
| `list-payload` | Prints what a commit would publish, one `sha<TAB>path` line per file |
| `list-instances` | Prints the Test Kitchen instances as a JSON array, and records it as a workflow output |
| `check-shell` | Runs shellcheck, in a pinned container, over every tracked shell script, found by shebang rather than by a list |
| `check-workflows` | Runs actionlint over the workflows, in a pinned container |
| `check-renovate` | Validates the Renovate configuration, fails on configuration Renovate would refuse when it looks dependencies up, and checks that every file carrying a marker still yields a dependency |
| `check-needs` | Fails unless every job in a `needs` context succeeded |
| `release` | Tags a merge to `main` and writes its release notes. Says what it released, or that nothing was, in the job summary |
| `publish` | Shares a tagged cookbook to Supermarket. Links the published version in the job summary |
| `lib.bash` | Shared helpers. Sourced, never executed |
| `detect-platform` | Prints the platform whose Cinc package the cache is keyed on |
| `install-cinc` | Installs the pinned Cinc Workstation, reusing a cached package |

The last two ship with the `setup-cinc` action and sit beside its
`action.yml` rather than in `.github/scripts`, for the reason "The
composite action" below gives.

Fail loudly, or do not bother
-----------------------------

An exit status nobody reads is a check that passes on nothing, and on a
pull request that is indistinguishable from a check that passed.

* **A process substitution hides the exit status of the command inside
  it**, and `pipefail` does not help, because it governs pipelines. Put
  the output in a variable first, so `set -e` sees the failure:

  ```bash
  out="$(thing)"          # a failure here ends the script
  other="$(diff <(thing) <(thing))"   # a failure here is invisible
  ```

* **`set -e` ends the script on a failing assignment**, before any guard
  written below it. Test the assignment in the condition instead:

  ```bash
  if ! value="$(thing)" || [[ -z ${value} ]]; then
    echo "::error::explain what could not be read"
    exit 1
  fi
  ```

* **A pattern that matches nothing prints nothing.** An error path that
  explains a failure by filtering its input can leave a failure with no
  explanation attached. Print the raw material instead.

The first two have both shipped here, and both passed CI while checking
nothing at all.

Style
-----

* Bash with `set -euo pipefail`, written with modern bash idioms rather
  than POSIX portability. Bash 3.2 all the same, which is what a macOS
  contributor has unless they installed another one: the runners have
  bash 5, so nothing here would catch a 4-or-later construct before it
  reached somebody's workstation, and shellcheck has no option to target
  a version. In practice that costs nothing, because the things bash 4
  adds buy little here: an associative array in place of a membership
  test means keeping a list and a set of it in step, for one expression.
* Prefer bash's own facilities to a subprocess where they read as clearly.
  A `[[ ... =~ ... ]]` with `BASH_REMATCH` says what a one-capture `sed`
  substitution says, and returns one value rather than one line per match.
  Keep `jq` for JSON and `awk` for a range of lines between markers.
* Executable, shebang, no extension. Runnable by hand from a checkout, so
  that a failure can be reproduced without a workflow.
* Never interpolate an argument into a command line. Ruby's backticks and
  `system` with one string hand it to a shell, so a ref or a filename
  carrying a semicolon runs whatever follows it. Pass an array instead.
* Workflow logic lives in a script or a composite action, not inline in
  YAML.

Shared parsing
--------------

`lib.bash` exists so the pull request check, the release and the publish
cannot disagree about which cookbook and which version they are talking
about. Parsed separately, a release could tag a version that was never
validated, or publish an artifact describing different code than the tag.
Add a helper there rather than a second parser in a script.

Containers
----------

A container is a dependency like any other, so it matters who builds it.
Prefer, in order: an image Docker publishes as an Official Image, one
published by the tool's own author or project, and only then somebody
else's rebuild. Both images used here are the authors' own, since neither
tool has an official image.

What the runner already carries is not automatically the better answer. It
drifts underneath you and differs from a workstation, which is how a lint
that was clean locally failed a build here.

Pin by tag and digest together. The tag says what the thing is to a reader,
and the digest is what makes it the same bytes tomorrow, since a tag can be
repushed and nothing in a diff would show it. Use the multi-platform index
digest so it resolves on whatever architecture runs it, and mark it for
Renovate so the two move together.

A container reads the checkout over a bind mount, and on a workstation that
mount can be a moment behind. Where the host shares a directory into a
virtual machine, the file's length is cached separately from its contents,
so a container started just after a file is written can read that file cut
off at the length it used to have. A linter then reports a parse error at
the cut, or, when the change was near the end of the file, reports nothing
wrong at all, which is the half that matters: a local run can say a script
is clean when it is not. If a local result disagrees with this pipeline,
run it again before believing either. The runners do not share files this
way, so nothing here is affected.

What Renovate cannot see
------------------------

Everything pinned here is tracked, and `check-renovate` fails when that
stops being true in either direction: a file carrying a marker that yields
no dependency, or a file pinning a digest that Renovate does not track.
What neither rule reaches is a version with no distinctive shape to search
for.

The platform images in `kitchen.yml` are the case that matters. They are
named `dokken/debian-13`, `dokken/fedora-43` and so on, so the release is
part of the repository name rather than a tag, and the only tag is the
implicit `latest`. Renovate moves tags and digests, so there is nothing
here for it to move, and a custom manager would not help. The weekly
scheduled run catches those images changing underneath their names, which
is what it is for, but it cannot tell you that a new Fedora or Debian
exists. Adding a platform stays something somebody notices upstream and
decides to do.

Cinc Workstation itself is tracked, through a custom datasource against the
omnitruck version list, and the marker sits in both `action.yml` and
`TESTING.md` so the documented version cannot drift from the installed one.
The Cinc client majors in the kitchen suites are a different thing and are
outside Renovate: they are floating major tags, no datasource knows which
lines are current, and raising the floor is a major release rather than a
bump. That pair is enforced instead of tracked. A suite running a client
outside the `chef_version` constraint in `metadata.rb` fails at converge,
because Chef validates the running version against the cookbook's metadata
and raises before any recipe runs.

The runner image is pinned by version, `ubuntu-24.04` rather than
`ubuntu-latest`, for the same reason the platform images are a problem.
Renovate reads every `runs-on` label, but it skips `latest` as not being a
version, silently, so a floating label moves when GitHub moves it and never
through a pull request that CI has run against. A version label becomes a
Renovate update instead, and the new runner is tested before it is used.

Script or composite action
--------------------------

Both keep logic out of the YAML, and the script is the default. An action
earns its place only when one of these is true:

* It bundles several steps. Installing the toolchain is three: detect the
  platform, restore the cache, install.
* It has to call another action. `actions/cache` is reachable only from a
  step, so anything that caches has to live in an action.
* More than one job uses it.
* Another repository has to be able to use it. Actions are addressable
  from elsewhere; scripts are not.

Otherwise the action buys an `action.yml`, an inputs and outputs mapping,
and a layer of indirection for nothing, and it costs the property that
makes these scripts debuggable: a script runs by hand from a checkout, so
a failure can be reproduced without pushing a commit and waiting for a
runner. An action cannot, without a harness to feed it.

The composite action
--------------------

A composite action's `run` steps execute in the caller's working directory
rather than in the action's own, so a repository relative path to a script
beside `action.yml` resolves only while the action happens to be checked
out at the root of the repository using it. Address anything the action
ships through `${{ github.action_path }}`.

Its scripts follow everything above: `set -euo pipefail`, no extension,
runnable by hand, and the environment they need declared in the step that
calls them rather than assumed.

Nothing under `.github/` is published, so changes here never need a new
cookbook version.
