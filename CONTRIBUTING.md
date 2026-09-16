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

[TESTING.md][2] records the exact versions this cookbook is tested
against. Integration tests run in containers through kitchen-dokken,
so Docker needs to be running for those.

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
| `spec/` | RSpec tests for the library classes |
| `test/fixtures/cookbooks/limits_test/` | Wrapper cookbook the suites converge |
| `test/integration/` | InSpec controls that assert the result |

There are no ChefSpec tests, deliberately. The custom resources read
and write the real filesystem at converge time, so stepping into them
under ChefSpec would touch the host's own
`/etc/security/limits.conf`. Resource behavior is covered by the
integration suites instead, and the specs exercise the library classes
directly.

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
[v3.1.0]
--------

* Describe the change from the point of view of someone using the
  cookbook
```

Add the link reference at the foot of the file, alongside the others:

```markdown
[v3.1.0]: https://github.com/jrwesolo/limits/tree/v3.1.0
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

The **version** job only does anything when a pull request changes the
version in `metadata.rb`. When it does, it asserts that the new
version is not already tagged and that it is the newest entry in
`CHANGELOG.md` with a matching link reference. When the version is
unchanged from the base branch, both assertions are skipped, so
documentation-only pull requests are unaffected.

The integration matrix is generated from `kitchen.yml` at runtime, so
adding a platform or a Cinc major version there is picked up with no
workflow edit.

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
