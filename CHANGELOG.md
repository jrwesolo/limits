limits cookbook CHANGELOG
=========================

[v3.1.0]
--------

Input that was silently mishandled is now refused. A limit whose domain
or value carries whitespace or a `#` cannot be written to a limits file
and read back, so it was either dropped on the next read or returned
with a different value, and the resource never settled. Such a limit now
fails property validation instead. One shape of it was still enforced:
pam_limits reads a value only up to the end of its leading number, so a
value such as `10 `, `10 20` or `10#20` reached pam as 10 while the
resource reported a change on every run. A recipe carrying one now fails
until the value is corrected. Nothing valid is refused: limits.conf has
no line continuation, its first three fields are separated by
whitespace, and a `#` ends the line wherever it falls, so a field
carrying either character cannot describe a limit in the first place.

A limits file written with CRLF line endings also no longer loses
limits. Such a file parsed as only those of its limits that carried an
inline comment, and the rest were dropped the next time the file was
written.

A comment no longer keeps a limit converging forever. Chef coerces both
the comment a recipe asks for and the comment read back off disk on their
way into the same property, so whatever that coercion does it has to do
twice and give the same answer. It did not: trailing whitespace was kept
where the file dropped it, and a leading `#` was taken off, then taken
off again on the second pass.

**The `comment` property now holds the comment's own text.** The `#` that
opens every comment line in a limits file belongs to the file and is
written for you, so a comment carrying one of its own keeps it.
`comment '#4127 see the ticket'` is written as `# #4127 see the ticket`,
where before it was quietly written as `# 4127 see the ticket`. A recipe
that spelled the `#` out, as `comment '# note'`, writes `# # note` now
and rewrites such a file once on the first run after upgrading.

* Reject a `domain` or `value` that cannot survive being written to a
  limits file and read back, in the `limit` resource as a property
  validation failure and in `Limits::Entry` for anything reaching the
  library another way. A limit with no value is untouched, since that
  is how a lookup and the delete action name a limit without saying
  what it should be
* Keep a file path inside the header comment that opens a managed file.
  A newline in a filename is legal on Linux and pam_limits reads such a
  file like any other, but the header was built by hand, so the name
  could end the comment and leave a line behind that read back as a
  limit nobody declared
* Normalize a `comment` to the form it is written in, stripping trailing
  whitespace from each of its lines. The property kept its own, but every
  line is written stripped, so the comment a limit was asked for and the
  comment read back off disk never compared equal and the limit converged
  on every run
* Read a comment's `#` as syntax only when reading a file. Taking one off
  is now `Limits::Helpers.unformat_comment`, used by `Limits::File` and
  nowhere else, which leaves the coercion the `comment` property applies
  as nothing but an rstrip, and applying an rstrip twice changes nothing.
  Before, the property took a `#` off whatever a recipe gave it and
  `Limits::Entry` took another off on the way to the file, so
  `## warning` was written as `# warning`, and `#1 priority` was written
  as `# 1 priority` and never noticed, because a wrong comment still
  settles
* Read a `#` line with nothing after it, directly above a limit, as no
  comment at all. It was read as an empty comment, which the `comment`
  property refuses, so any `limit` on the line below it failed the
  converge, and it was written back as a blank line, so the file took a
  second rewrite to settle
* Read a comment line indented in front of its `#` as the comment after
  the `#`. The indentation kept the `#` from being recognized, so a
  hand-edited `  # note` was rewritten as `#   # note`. It is now
  rewritten as `# note`, once, on the first run after upgrading
* Coerce a value to an Integer only when the whole string is a number.
  The match was anchored to line boundaries rather than to the ends of
  the string, so a value carrying a newline could be read as a number on
  one of its lines and coerced as a whole, turning `foo\n10` into 0
* Keep the limits in a file written with CRLF line endings. A line ends
  at a `\n`, so a `\r` in front of one stopped the line matching, except
  where an inline comment consumed it. A CRLF file therefore parsed as
  some of its limits and not others, and the rest were dropped the next
  time the file was written. The endings are normalized on read and the
  file is rewritten with `\n`
* Rewrite the file through Chef when purging, rather than writing it
  directly once per removed limit. Each deletion rendered and replaced
  the whole file, so an interrupted run left some unmanaged limits gone
  and the rest still there, `backup` was ignored by the one action that
  deletes configuration somebody else wrote, and the run showed no
  content diff. **A file managed by `:purge` alone now takes the
  resource's owner, group and mode, where before it kept whatever it
  already had.** Those are applied on every run rather than only on one
  that finds something to remove, since the run that corrects them is
  otherwise the same run that leaves nothing to purge, and a file changed
  by hand afterwards would stay that way. The content is still rewritten
  only when there is something to remove, and a path with no file on it
  is still left alone rather than given an empty one. Purge now replaces
  the file in one step as well
* Replace the file in one step when a limit changes, rather than
  truncating it and writing it again. The file was rewritten with
  `File.write`, which truncates the destination and only then renders
  what it was handed, so a failure while rendering left an empty file
  where the limits had been, and a client killed partway through left a
  prefix of one that pam reads without complaint. It is now written
  through Chef's `file` resource, run rather than declared against an
  event dispatcher nobody is subscribed to, so a file written once per
  limit does not report itself once per limit. One consequence of
  replacing the file rather than writing over it: POSIX ACLs set with
  `setfacl` are not carried across, which is true of every other file
  Chef manages
* Accept the `nonewprivs` and `rttime` items, the two the limits.conf
  man page documents that this cookbook did not. Neither is available on
  every platform and the resource does not check: pam_limits logs an
  unknown item and skips the line, so writing one is honored by a newer
  module rather than failing the run
* Document the valid types and items in the README with a description
  for each, along with a Requirements section. They were reachable only
  by opening `libraries/constants.rb`, which a reader on Supermarket
  cannot do
* Test against Rocky Linux 10 as well as Rocky Linux 9, which covers the
  EL10 client packages rather than only the EL9 ones
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

[v3.1.0]: https://github.com/jrwesolo/limits/tree/v3.1.0
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
