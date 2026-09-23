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
  and reads that empty string as the script instead. `date`, `readlink`
  and `env` differ too.
* **Bash version.** macOS ships bash 3.2 as `/bin/bash`, so modern syntax
  cannot be exercised there, and a script that passes under 3.2 can behave
  differently under 5.

Running the thing in a container matching the runner settles all three,
whatever the workstation is.

Where to look next
------------------

| Before you | Read |
| --- | --- |
| edit anything under `.github/scripts/` | `.github/scripts/AGENTS.md` |
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

Keep this file short. Guidance that belongs to one directory belongs in
that directory, beside the code it describes.
