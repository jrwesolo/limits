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

CI runs on Linux. Three differences have each turned a local pass into a
red build:

* **The macOS filesystem is case insensitive.** A `require` or a path
  whose case is wrong resolves here and fails there. Ruby's `English`
  library is the example: the file is `English.rb`, so `require 'english'`
  works only on a case-insensitive filesystem.
* **The command line tools are BSD, not GNU.** `sed -i` takes an argument
  here and not there, and `env` and `date` differ too. Anything a workflow
  will run has to be exercised against GNU tools.
* **`/bin/bash` here is 3.2.** The runners have bash 5, so a script may use
  modern syntax, but a local run does not prove it works, and a local run
  can pass on a construct the runner reads differently.

Running the thing in a Linux container answers all three cheaply.

Where to look next
------------------

| Before you | Read |
| --- | --- |
| edit anything under `.github/scripts/` | `.github/scripts/AGENTS.md` |
| add, move or remove a test | `TESTING.md` |
| open a pull request or cut a release | `CONTRIBUTING.md` |
| change what the resources accept | `README.md` |

Keep this file short. Guidance that belongs to one directory belongs in
that directory, beside the code it describes.
