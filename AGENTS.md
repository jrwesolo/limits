Agent guidance
==============

Conventions for anyone working in this repository. What the cookbook does
and how to use it is in `README.md`; how to contribute is in
`CONTRIBUTING.md`; how to run the tests is in `TESTING.md`. This file
carries the things that are easy to get wrong and expensive to rediscover.

`CLAUDE.md` beside this file is a one-line pointer at it, so that a single
copy of the guidance serves tools looking for either name.

Toolchain
---------

Every tool runs inside Cinc Workstation, which ships its own Ruby:
`cinc exec rspec`, `cinc exec cookstyle`, `cinc exec kitchen`. A bare
`rspec` is a different toolchain and will not reproduce what CI does.

Test Kitchen reaches Docker through the docker-api gem, which does not
read Docker contexts: it connects to `unix:///var/run/docker.sock` unless
`DOCKER_HOST` says otherwise. Docker Desktop on macOS creates that socket
only when its default socket option is enabled, so `docker` on the command
line can work while a converge fails with `No such file or directory -
connect(2) for /var/run/docker.sock`. Point it at whatever the active
context names:

```bash
export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')"
```

A workstation is not the CI runner
----------------------------------

CI runs on Ubuntu, with GNU command line tools, bash 5 and a case
sensitive filesystem. Where a workstation differs, a local pass proves
less than it appears to:

* **Filesystem case sensitivity.** macOS and Windows default to
  insensitive, so a `require` or a path whose case is wrong resolves there
  and fails on the runner. Ruby's `English` library is the example: the
  file is `English.rb`, so `require 'english'` works only where case does
  not matter.
* **GNU against BSD command line tools.** macOS and the BSDs ship their
  own versions, and the flags differ. `sed -i` takes a backup suffix
  argument on BSD, commonly written `-i ''`, while GNU `sed -i` takes none
  and consumes that empty string as the script or as a filename, failing
  either way. `date`, `readlink` and `env` differ too.
* **Bash version.** macOS ships bash 3.2 as `/bin/bash`, so modern syntax
  cannot be exercised there, and a script that passes under 3.2 can behave
  differently under 5.

Running the thing in a container matching the runner settles all three,
whatever the workstation is.

Where to look next
------------------

| Before you | Read |
| --- | --- |
| edit a workflow, a CI script or the setup action | `.github/AGENTS.md` |
| add, move or remove a test | `TESTING.md` |
| open a pull request or cut a release | `CONTRIBUTING.md` |
| change what the resources accept | `README.md` |

Keep nothing local in the repository
------------------------------------

No detail belonging to one machine or one person may reach a committed
file, a commit message or a pull request: a home directory, a username, a
hostname, an absolute path outside the checkout, a personal email address
or a token. Documentation, comments, fixtures and test data all count, and
a path copied out of a terminal is the usual way one arrives.

Write the derivation rather than the value. The Docker line above asks the
active context for the socket instead of naming a path under somebody's
home directory, which is both private and correct on more machines. A
relative path, an environment variable, or an obvious placeholder such as
`/path/to/checkout` serves everywhere else.

Testing
-------

Write the failing test first wherever the work allows it. A bug gets a
test that reproduces it, seen red, before any fix exists. A feature gets
the assertion that will hold once it works. The red run is the part worth
having: it shows the test fails for the reason claimed, rather than
because it was written wrong or because it is asserting nothing.

Where a test has to come second, prove it the same way afterwards. Break
the code it covers on purpose, confirm that test turns red and that the
failure is the expected one, then restore the code and watch it go green
again. A test never seen failing has an unknown subject, and more than one
here has turned out to assert something other than what its name claimed.

That applies to anything with a pass and a fail, not only to test suites:
a CI check, a script, a lint rule. Exercise the case that must fail and
the case that must pass, and be able to switch between them on demand. If
a case cannot be made to fail, either the check is not checking what it
says or the test belongs somewhere else.

Adding to this guidance
-----------------------

Keep this documentation current. When something in this repository costs
more to learn than it should have, write it down here, so the next person
is not charged for it twice. The bar is a lesson that is not obvious from
the code and was expensive to discover: a failure the tooling reports
without explaining, a constraint a framework imposes on how the code has
to be shaped, a trap that has cost a build or an afternoon. What the
linter enforces, what a script's own header comment explains at the moment
it applies, and anything a reader can see by looking do not belong here.

Write it the way the rest of this file is written:

* **Generic.** State the rule and the failure it prevents, not the
  incident that produced it. No pull request numbers, no unreleased
  version numbers, no names, no dates, nothing local to one machine.
* **At the narrowest scope that covers it.** Guidance belonging to one
  directory goes in an `AGENTS.md` there, which is read when that
  directory is worked on and costs nothing otherwise. This file is for
  what spans the repository, and it should stay short enough to be worth
  reading every time.
* **With its reason attached.** A rule with no failure behind it reads as
  arbitrary, and the next person to find it inconvenient will remove it.

A new guidance file at the root, or under a new directory, is published to
Supermarket unless `chefignore` excludes it. Add the pattern in the same
change, and confirm it with `.github/scripts/list-payload HEAD`.
