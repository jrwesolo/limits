Testing
=======

<!-- renovate: cinc-workstation -->
Tested with [Cinc Workstation][1] 26.2.4, which is the version CI installs
and the one Renovate keeps in step with `.github/actions/setup-cinc`. Run
`cinc --version` to see the client, auditor, CLI, Test Kitchen and Cookstyle
versions that ship inside it.

Perform tests using the following commands:

```bash
cinc exec cookstyle    # linting
cinc exec rspec        # spec tests
cinc exec kitchen test # integration tests
```

Integration fixtures
--------------------

The integration suites converge the `limits_test` wrapper cookbook in
`test/fixtures/cookbooks/limits_test` and then assert the result with the
InSpec profile in `test/integration/default`. Each file the converge
touches covers one behavior, and the numeric prefix names it:

| File under `/etc/security` | Seeded | Managed by | Covers |
| --- | --- | --- | --- |
| `limits.conf` | yes | `limits_file` `[:create, :purge]` | purging, comment handling, ownership correction |
| `limits.d/100_unpurged.conf` | yes | `limits_file :create` | a managed file whose unmanaged limits survive |
| `limits.d/200_unmanaged.conf` | no | nothing, only a `limit` | a file created by a limit with no `limits_file` |
| `limits.d/300_deleted.conf` | yes | `limits_file :delete` | the delete action |
| `limits.d/400_created.conf` | no | `limits_file :create` | building a file from nothing, and a word value |

`limits.conf` is seeded with limits no resource declares, an unparseable
line and a comment attached to nothing, so the purge, the rewrite and the
dropping of both lines can be asserted. `100_unpurged.conf` is the same
setup without `:purge`, which is what proves the difference between the
two. `200_unmanaged.conf` is the one file with no managed permissions,
since nothing but a `limit` resource touches it, and the profile pins the
mode it ends up with to keep that visible. `300_deleted.conf` has to be
seeded or the test would assert that a file nobody created is absent.
`400_created.conf` is the only file the create action builds rather than
adopts, and it carries a value of `unlimited` so that a non-numeric value
is covered end to end.

Seeding happens once per container, not once per converge. The seeds
declare `action :nothing` and are notified by a marker file at
`/tmp/limits_test_seeded`, which reports a change only the first time it
is created. Test Kitchen converges twice and fails the run if the second
converge changes anything, so a seed that fired every time would either
fight the cookbook for the files it manages or restore the file the
default recipe deletes. The notifications are immediate rather than
delayed, because a delayed notification runs after `limits_file` and
`limit` have converged and would seed the files again on top of what the
cookbook just wrote.

Running one instance
--------------------

`cinc exec kitchen list` shows every suite and platform combination. A
single one can be run by name, which is worth doing while iterating, as
the full matrix is ten containers:

```bash
cinc exec kitchen test cinc-19-debian-13
```

The InSpec profile can also be linted on its own, without converging
anything:

```bash
cinc-auditor check test/integration/default
```

Troubleshooting
---------------

**`docker` works but Test Kitchen cannot connect.** The two are not
looking in the same place. kitchen-dokken talks to Docker through the
`docker-api` gem, which does not read Docker CLI contexts: it looks for
`/var/run/docker.sock` and then falls back to `tcp://127.0.0.1:2375`.
Docker Desktop only creates that socket when "Allow the default Docker
socket to be used" is enabled under Settings, Advanced. Either enable
that setting, or point the gem at the socket the active context is
using:

```bash
export DOCKER_HOST="$(docker context inspect --format '{{.Endpoints.docker.Host}}')"
```

**A converge fails to install the cookbook from the lockfile.**
`Policyfile.lock.json` is not committed, and it pins the version that
was in `metadata.rb` when it was written. After a version bump it no
longer satisfies the constraint, and the fix is to resolve it again:

```bash
rm -f Policyfile.lock.json && cinc-cli install
```

[1]: https://cinc.sh/start/workstation/
