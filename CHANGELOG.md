limits cookbook CHANGELOG
=========================

[v3.0.1]
--------

* Ship `CHANGELOG.md` in the published cookbook, so that Supermarket
  renders it as the Changelog tab on the cookbook page. Along with the
  README it is one of only two files Supermarket reads out of the
  tarball

[v3.0.0]
--------

The minimum supported Chef Infra Client is now 18. Nodes running an
older client will fail the `chef_version` metadata constraint. Pin to
`~> 2.4` to stay on a release that supports Chef Infra Client 12
through 17.

* Move development and testing from Chef Workstation to Cinc Workstation
  26.2.4
* Test Kitchen selects Cinc via `product_name: cinc`, which derives both
  the image (`cincproject/cinc`) and the client binary
  (`/opt/cinc/bin/cinc-client`)
* Remove the Chef 19 Habitat image workaround and its hardcoded client
  path, as Cinc 19 ships as an omnibus package
* Drop the Chef Infra Client 17 test suite, as `cincproject/cinc:17` is
  published for amd64 only
* Raise the minimum supported Chef Infra Client to 18
* Test Kitchen suites track major versions instead of exact pins
* Replace CentOS Stream 10 with Rocky Linux 9 and Ubuntu 25.10 with
  Ubuntu 24.04 LTS for Test Kitchen
* Add Rocky Linux to the list of supported platforms
* Add GitHub Actions CI with separate lint, unit, and integration
  stages. The integration matrix is derived from `kitchen list --json`,
  so each suite and platform combination runs in parallel
* Check on every pull request that a bumped version is not already
  tagged and that it is the newest entry in this changelog
* Tag the commit and publish a GitHub release automatically when a
  version bump merges to main, taking the release notes from the
  matching section of this changelog
* Drop release dates from this changelog, as the tag and the GitHub
  release already record when a version shipped
* Share the cookbook to Chef Supermarket after a release is tagged,
  behind a GitHub environment that requires a human to approve the
  deployment. Publishing after tagging is what lets Supermarket's
  version tag quality metric find the tag it looks for
* Run the test jobs weekly, so that upstream drift in the dokken base
  images is caught without waiting for someone to push
* Add a CI status badge to the README
* Remove the unused `default_source :supermarket` from the Policyfile
* Correct `chefignore` so that the workflow directory, an undotted
  `kitchen.local.yml`, and `chefignore` itself are kept out of the
  published cookbook artifact
* Ignore the undotted `kitchen.local.yml`, matching the undotted
  `kitchen.yml` already in use
* Cookstyle-recommended fixes

[v2.4.1]
--------

* Repackage previous version without macOS-related issues. Root-cause
  was using the BSD flavor of `tar` which was including macOS extended
  attributes. Changing to the GNU flavor of `tar` does not include
  these extended attributes.

[v2.4.0]
--------

* Add support for Chef Infra Client 19
* Update Chef Workstation to 25.13.7
* Refactor platform and suites for Test Kitchen
* Update platform versions for Test Kitchen
* Update Chef Infra Client versions for Test Kitchen

[v2.3.0]
--------

* Add support for Chef Infra Client 18
* Update Chef Workstation to 22.10.1013
* Update platform versions for Test Kitchen
* Update Chef Infra Client versions for Test Kitchen
* Move to policy files for Test Kitchen
* Cookstyle-recommended fixes

[v2.2.0]
--------

* Add support for Chef 17
* Update Chef Workstation to 20.12.205
* Cookstyle-recommended fixes
* Test kitchen will test more platforms
* Test kitchen will perform two converges and ensure idempotency
* Add TESTING.md file

[v2.1.1]
--------

* Chef 16.2.x had a backwards-incompatible change related to custom
  resources. This version supports the new style while maintaining
  backwards-compatibility.
* Update Chef Workstation to 20.6.62

[v2.1.0]
--------

* Add support for Chef 16.x
* Update Chef Workstation to 0.18.3

[v2.0.0]
--------

This cookbook has been completely refactored. It is not backwards
compatible. Please see the `README.md` for usage details. The code has
been uplifted to the latest best practices. The LWRP and definition was
removed in favor of the new custom resource syntax introduced in Chef
12.

* Add `limit` custom resource for managing individual limits
* Add `limits_file` custom resource for managing a limits file
* Remove attributes in favor of default values in custom resources
* Remove `set_limit` definition and `limits_config` LWRP
* Replace ChefDK with Chef Workstation
* Replace RuboCop with Cookstyle
* Replace Serverspec with InSpec
* Replace Vagrant with Dokken
* Test support on Chef 12-15

[v1.0.0]
--------

This cookbook has changed to be an LWRP-only usage. No longer will
limits be able to be specified using attributes. Please see the
`README.md` for usage details.

* Development and testing using ChefDK
* Add ChefSpec tests
* Add Serverspec tests
* Change license from Apache to MIT

[v0.2.0]
--------

* Initial release of limits

[v3.0.1]: https://github.com/jrwesolo/limits/tree/v3.0.1
[v3.0.0]: https://github.com/jrwesolo/limits/tree/v3.0.0
[v2.4.1]: https://github.com/jrwesolo/limits/tree/v2.4.1
[v2.4.0]: https://github.com/jrwesolo/limits/tree/v2.4.0
[v2.3.0]: https://github.com/jrwesolo/limits/tree/v2.3.0
[v2.2.0]: https://github.com/jrwesolo/limits/tree/v2.2.0
[v2.1.1]: https://github.com/jrwesolo/limits/tree/v2.1.1
[v2.1.0]: https://github.com/jrwesolo/limits/tree/v2.1.0
[v2.0.0]: https://github.com/jrwesolo/limits/tree/v2.0.0
[v1.0.0]: https://github.com/jrwesolo/limits/tree/v1.0.0
[v0.2.0]: https://github.com/jrwesolo/limits/tree/v0.2.0
