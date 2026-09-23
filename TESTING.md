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

Spec tests
----------

`spec/libraries` exercises the library classes directly, which is where
the parsing, formatting and validation live. Those specs construct a
`Limits::File` and stub the two calls it makes to read its path, so they
touch no disk and run in milliseconds.

`spec/resources` covers what only a converge can decide, and ChefSpec
provides the converge. `platform` compiles this cookbook's libraries and
resources while skipping recipes, which is what makes a cookbook that
ships no recipes testable at all, and `converge_block` runs recipe code
written inline in the example. The specs `step_into` the resource under
test and stub `::File` for the managed path, so the host's own
`/etc/security/limits.conf` is never read. Nothing is written either,
because ChefSpec skips every resource it has not been told to step into,
including the file resource each custom resource writes through.

The `limits_file` specs cover the purge action's rule. It decides what
to remove by asking the resource collection which limits Chef declares,
rather than by reading them out of the file, so there is nothing to test
without a converge. `limits_file` declares its file resource, so ChefSpec
sees it, and the assertions are made against the content and permissions
that resource was handed. That covers the rules the README states and
the integration suites cannot reach cheaply: a limit protects its entry
from being purged even when it carries `action :nothing` and never
converges, and only for the path it names.

The `limit` specs assert something different, because `limit` runs its
file resource rather than declaring it. That resource never enters the
resource collection, so no matcher can see it and these specs say
little about the bytes written; the content is `Limits::File#to_s`,
which `spec/libraries` covers directly. What they cover is what
`converge_if_changed` decides, which is the only thing that can mark the
resource updated now that its write reports nothing, and property
validation, which the integration suites cannot test at all: a limit
that fails validation fails the converge, and a converge that fails is a
Test Kitchen run that fails.

One `limit` spec catches the file resource on its way through instead,
by wrapping `Chef::Resource::File.new`, and asserts that the content is
handed to it and run rather than written with `::File.write`. That is
what makes the write replace the file in one step, and a direct write
lands the same bytes, so nothing else would notice it going.

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
| `limits.d/400_created.conf` | no | `limits_file :create` | building a file from nothing, a word value, and a boolean item |
| `limits.d/500_purged.conf` | yes | `limits_file :purge` | purging a file with no create action beside it |
| `limits.d/600_absent.conf` | no | `limits_file :purge` | purging a path with no file on it |

`limits.conf` is seeded with limits no resource declares, an unparseable
line and a comment attached to nothing, so the purge, the rewrite and the
dropping of both lines can be asserted. `100_unpurged.conf` is the same
setup without `:purge`, which is what proves the difference between the
two. `200_unmanaged.conf` is the one file with no managed permissions,
since nothing but a `limit` resource touches it, and the profile pins the
mode it ends up with to keep that visible. `300_deleted.conf` has to be
seeded or the test would assert that a file nobody created is absent.
`400_created.conf` is the only file the create action builds rather than
adopts. It carries a value of `unlimited` so that a non-numeric value is
covered end to end, and a `nonewprivs` limit, which is an item that takes
a flag rather than a size and that an older `pam_limits` does not know.
`500_purged.conf` is the only file managed by `:purge` on its own, which
is what proves the purge action maintains ownership and mode rather than
leaving whatever the file already had; like the other seeds it is laid
down with the wrong owner and mode on purpose. `600_absent.conf` is never
created by anything, so the purge pointed at it proves the action neither
creates a file nor notifies.

Four `ruby_block` resources record that a `limits_file` notified them,
one per action plus one for the action that correctly does nothing. They
exist because `limits_file` has no `converge_if_changed` of its own: the
`file` resource declared inside it is the only thing that knows whether
anything changed, and therefore the only thing that can mark the
resource updated. A `limits_file` that quietly reported itself up to
date would still write the right file, so every content assertion in the
profile would still pass while every `notifies` a user had hung off one
silently stopped firing.

The same question about `limit` is settled in `spec/resources` rather
than here, where ChefSpec can put `converge_if_changed` to every case for
the price of a few milliseconds. A `limit` marks itself updated through
`converge_by`, which ChefSpec leaves alone.

There is no equivalent for `limits_file` at any price. ChefSpec replaces
`Chef::Provider#compile_and_converge_action` with a bare `instance_eval`,
so no child run context is built and the step that marks a resource
updated because a resource it declared was updated never runs. Its own
source calls this out as a known limitation. A `limits_file` under
ChefSpec always reports itself up to date, whatever it did, which is why
these recorders stay here.

The negative case matters as much as the positive one, because it is
what decides whether a first converge is quiet. A second converge is
already covered, though only by accident: Test Kitchen converges twice
and fails a run whose second converge changes anything, so a recorder
that fired every time would fail the run.

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
