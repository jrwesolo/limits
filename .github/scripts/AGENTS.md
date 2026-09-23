CI script conventions
=====================

These scripts decide whether a pull request may merge and what gets
released, so they are held to a higher standard than a local helper. Each
script's own header comment carries its detail; this file carries what
they have in common.

What is here
------------

| Script | What it does |
| --- | --- |
| `check-version` | Fails a pull request proposing a version that cannot be released, or changing what would be published without a new version |
| `list-payload` | Prints what a commit would publish, one `sha<TAB>path` line per file |
| `check-needs` | Fails unless every job in a `needs` context succeeded |
| `release` | Tags a merge to `main` and writes its release notes |
| `publish` | Shares a tagged cookbook to Supermarket |
| `lib.bash` | Shared helpers. Sourced, never executed |

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
  than POSIX portability.
* Prefer bash's own facilities to a subprocess where they read as clearly.
  A `[[ ... =~ ... ]]` with `BASH_REMATCH` says what a one-capture `sed`
  substitution says, and returns one value rather than one line per match.
  Keep `jq` for JSON and `awk` for a range of lines between markers.
* Executable, shebang, no extension. Runnable by hand from a checkout, so
  that a failure can be reproduced without a workflow.
* Workflow logic lives in a script or a composite action, not inline in
  YAML.

Shared parsing
--------------

`lib.bash` exists so the pull request check, the release and the publish
cannot disagree about which cookbook and which version they are talking
about. Parsed separately, a release could tag a version that was never
validated, or publish an artifact describing different code than the tag.
Add a helper there rather than a second parser in a script.

Nothing under `.github/` is published, so changes here never need a new
cookbook version.
