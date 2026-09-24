Contributing
============

Thanks for taking the time to contribute. Open an issue if you want to
discuss a change before writing it, or go straight to a pull request
for anything obvious.

Getting set up
--------------

Development and testing use [Cinc Workstation][1], the community
distribution of Chef Workstation. It is free and requires no license
acceptance.

```bash
curl -fsSL https://omnitruck.cinc.sh/install.sh | sudo bash -s -- \
  -P cinc-workstation
```

[TESTING.md][2] records the version this cookbook is tested against,
how each test layer is built, what each integration fixture covers, how
to run a single Test Kitchen instance, and what to do when a converge
will not start. Integration tests run in containers through
kitchen-dokken, so Docker needs to be running for those.

Running the tests
-----------------

```bash
cinc exec cookstyle    # linting
cinc exec rspec        # spec tests
cinc exec kitchen test # integration tests, needs Docker
```

Where things live
-----------------

| Path | What it holds |
| --- | --- |
| `libraries/` | Plain Ruby classes that do the parsing and formatting |
| `resources/` | The `limits_file` and `limit` custom resources |
| `spec/libraries/` | RSpec tests for the library classes |
| `spec/resources/` | ChefSpec tests for what only a converge decides |
| `test/fixtures/cookbooks/limits_test/` | Wrapper cookbook the suites converge |
| `test/integration/default/` | InSpec profile that asserts the result |
| `.github/workflows/` | The pipeline: tests on every pull request, release and publish on merges to `main` |
| `.github/scripts/` | What those jobs run, plus the shell library they share |
| `.github/actions/setup-cinc/` | Composite action that installs and caches the pinned Cinc Workstation |
| `AGENTS.md` | Conventions worth reading before changing any of the above |

Specs mirror the library one file each, named after the class or
constant they cover, with one exception. `spec/libraries/writable_spec.rb`
holds the rules that belong to no single class: what may be written into
a limits file, and what has to come back when it is read again. The test
for where a new spec goes is whether it can be stated as a fact about one
class without naming another. If it can, it goes in the mirror file. If
the failure only shows up when two classes meet, usually by writing a
file and parsing it again, it goes in `writable_spec.rb`.

A test belongs in the cheapest of three layers that can catch the
regression. `spec/libraries/` is plain Ruby with no Chef in it and runs
in milliseconds; anything that is a fact about parsing, formatting or
validation goes here, which is most of the cookbook. `spec/resources/`
is ChefSpec, kept to what only a converge decides: what
`converge_if_changed` reports as updated, property validation, which
limits the purge action counts as declared, and that a limit writes
through Chef's file resource. `test/integration/` is Test Kitchen and
InSpec, for what is only true of a real filesystem: the bytes that land,
ownership and mode, and idempotency across a second converge.

Versioning
----------

This cookbook follows [semantic versioning][3]. Bump the version in
`metadata.rb` in the same pull request as the change it describes.

Changelog
---------

Every user-visible change gets an entry in `CHANGELOG.md` under the
version that will ship it. The format is a reference-style heading and
a bullet list, newest first:

```markdown
[vX.Y.Z]
--------

* Describe the change from the point of view of someone using the
  cookbook
```

Add the link reference at the foot of the file, alongside the others:

```markdown
[vX.Y.Z]: https://github.com/jrwesolo/limits/tree/vX.Y.Z
```

A major release should also carry a short paragraph above the bullets
describing the break and naming the constraint users can pin to in
order to stay on the old behavior.

Documentation-only changes do not need a version bump or a changelog
entry.

What CI checks
--------------

Every pull request runs:

* **lint**, `cookstyle` across the cookbook
* **unit**, the RSpec suite
* **integration**, every suite and platform combination from
  `kitchen.yml`, each on its own runner
* **version**, described below

The **version** job asserts one of two things, depending on whether the
pull request changes the version in `metadata.rb`. When it does, the new
version must not already be tagged, and it must be the newest entry in
`CHANGELOG.md` with a matching link reference.

When it does not, nothing the cookbook would publish may change. The job
lists what the base branch would ship and what the pull request would
ship, by blob hash and path, and fails when the two differ. What counts as
published is decided by `chefignore`, so editing a file it excludes, such
as this one or anything under `.github/`, is free. Editing `README.md`, a
resource or a library needs a version for the change to arrive under.

The integration matrix is generated from `kitchen.yml` at runtime, so
adding a platform or a Cinc major version there is picked up with no
workflow edit. Each instance reports its own status check, named after
the instance, and those names change whenever `kitchen.yml` does.

Because of that, the branch ruleset requires a check named
**integration** that is not one of those instances. It is a gate job that
waits for the whole matrix and fails unless every instance succeeded, so
the four required checks, `lint`, `unit`, `version` and `integration`,
stay correct no matter which platforms are being tested. GitHub has no
pattern matching for required checks, and a required name that stops
reporting blocks every pull request until someone edits the ruleset, so
requiring the instances by name would turn a platform bump into a
settings change.

`release` and `publish` must stay out of the required list. They only
run on pushes to `main`, so they would never report on a pull request.

Pull requests
-------------

* Keep the subject line in the imperative mood, as in `Add support for
  ...` rather than `Added ...`.
* Explain why in the body, not just what. The diff already says what.
* One logical change per pull request where that is practical.

Releases
--------

Releases are automated and handled by the maintainer. Merging a
version bump to `main` tags the commit, publishes a GitHub release
using that version's changelog section as the notes, and then shares
the cookbook to [Chef Supermarket][4] once the deployment is approved.
Contributors do not need to tag or publish anything.

[1]: https://cinc.sh/start/workstation/
[2]: TESTING.md
[3]: https://semver.org/
[4]: https://supermarket.chef.io/cookbooks/limits
