Limits Cookbook
===============

[![pipeline][1]][2]

This cookbook is used to configure limits for the `pam_limits` module.
By default, the configuration file is located at
`/etc/security/limits.conf`. It can also configure limits in any
arbitrary path such as files in the directory `/etc/security/limits.d`.
It is available on the [Chef Supermarket][3] or [GitHub][4].

Requirements
============

Chef Infra Client 18 or newer and older than 20, or the equivalent Cinc
Client release. No gems or other cookbooks are required.

Any platform whose `pam_limits` reads `/etc/security/limits.conf` and
`/etc/security/limits.d`, which in practice means Linux. The cookbook
declares support for CentOS, Debian, Fedora, RedHat, Rocky and Ubuntu, and
is tested on Debian 13, Fedora 43, Rocky Linux 9, Rocky Linux 10 and
Ubuntu 24.04.

Usage
=====

**This cookbook does not provide any recipes.** Instead, it should be
added as a dependency of another cookbook. This will make the custom
resources provided by the `limits` cookbook available to be used in
another cookbook's recipes.

Here is an example of managing the system's limit.conf file, adding two
limits, managing a limits.d file, deleting any manually-added limits,
and adding one limit:

```ruby
# System limits.conf example

limits_file '/etc/security/limits.conf' do
  action :create
end

limit 'example-1' do
  domain '*'
  type 'hard'
  item 'nofile'
  value 512
end

limit 'example-2' do
  domain '@student'
  type 'soft'
  item 'nproc'
  value 20
end

# Separate limits.d example

limits_file '/etc/security/limits.d/001_vader.conf' do
  action [:create, :purge]
end

limit 'example-3' do
  path '/etc/security/limits.d/001_vader.conf'
  domain 'vader'
  type 'hard'
  item 'nofile'
  value 1000
end
```

Custom Resource: `limits_file`
------------------------------

This resource is used to manage a limits file. It is not required in
order to use the `limit` resource, but it is required to purge limits
that were not set via Chef. It can also be used without any `limit`
resources to just maintain the formatting of a limits file.

Property | Type                | Default           | Required
-------- | ------------------- | ----------------- | --------
`path`   | String              | *(name property)* | No
`owner`  | String, Integer     | `root`            | No
`group`  | String, Integer     | `root`            | No
`mode`   | String, Integer     | `0644`            | No
`backup` | Integer, FalseClass | `false`           | No

### Backups

`backup` is the number of copies Chef keeps when **this resource** changes
the file, or `false` to keep none. It is worth knowing which writes that
covers, because it is fewer than it looks.

The `create` action renders the file from what is already on disk, so it
changes the file on the first converge, when it reformats, and rarely
again: on later runs it reads the file, renders the same bytes, and has
nothing to write. The `purge` action changes the file every time it
removes a limit. So in practice `backup` is a purge feature, which is
also the action where a copy of the previous file is worth the most.

Writes made by the `limit` resource are never backed up, and that resource
has no `backup` property. It rewrites the whole file once per limit, so
twenty limits on one path is twenty writes in one run. Backups assume a
resource that writes a file once; keeping them here would leave nineteen
snapshots of half-applied state and push the one useful pre-run copy out
of the retention window. Point a `limits_file` at the path if you want the
file's writes backed up.

### Action: `create` (default)

This action will create the desired limits file. The file will be
formatted to a known style. Any comments not attached to limits or lines
that are not limits will be removed from the file. Existing limits and
attached comments will remain. File owner, group, and mode will be
maintained by Chef.

### Action: `purge`

This action will remove any limits in the limits file that were not
configured via Chef. This is useful if you want to ensure that a limits
file is completely managed by Chef and any manually-added limits are
removed.

A limit counts as configured via Chef when a `limit` resource declaring
it appears anywhere in the run with the same `path`, whichever recipe
declared it. The resource collection is what is consulted, not the file,
so it makes no difference whether that `limit` has converged yet or
converges at all: a limit declared with `action :nothing` is left alone
on the runs where nothing notifies it, rather than being removed and
written back the next time it fires.

When it removes something it rewrites the file through Chef, so `backup`
is honored and owner, group, and mode are maintained the same way the
`create` action maintains them. A file with nothing to purge is left
alone rather than reformatted, since this action was not asked to create
anything.

### Action: `delete`

This action will delete the desired limits file.

### Examples

```ruby
limits_file '/etc/security/limits.conf' do
  action :create
end

limits_file '/etc/security/limits.d/001_vader.conf' do
  action [:create, :purge]
end

limits_file '/etc/security/limits.d/002_anakin.conf' do
  action :delete
end
```

Custom Resource: `limit`
------------------------

This resource is used to manage a specific limit in a limits file. The
`limits_file` resource is not required to be used in conjunction with
this resource, but they do complement each other.

Property  | Type            | Default                     | Required
--------- | --------------- | --------------------------- | --------
`path`    | String          | `/etc/security/limits.conf` | No
`domain`  | String          | *none*                      | Yes
`type`    | String          | *none*                      | Yes
`item`    | String          | *none*                      | Yes
`value`   | Integer, String | *none*                      | Yes
`comment` | String          | *none*                      | No

`type` and `item` are checked against the tables below and the run fails
on anything else.

This resource writes through Chef, so the update is atomic, but it sets no
owner, group, mode or backup. Those belong to `limits_file`. A path managed
only by `limit` resources keeps whatever permissions it already had, or
takes the run's umask if the file is new, and is never backed up.

More documentation on domain, type, item, and value can be found at the
[limits.conf man page][5].

### Valid types

Type   | Meaning
------ | -------------------------------------------------------------
`soft` | The limit in force, which a user may raise up to the hard limit
`hard` | The ceiling the soft limit cannot be raised past
`-`    | Sets both the soft and the hard limit at once

### Valid items

Item           | Meaning
-------------- | ------------------------------------------------------
`as`           | Address space limit (KB)
`chroot`       | Change root to directory
`core`         | Maximum core file size (KB)
`cpu`          | Maximum CPU time (minutes)
`data`         | Maximum data size (KB)
`fsize`        | Maximum file size (KB)
`locks`        | Maximum number of file locks
`maxlogins`    | Maximum number of logins for this user
`maxsyslogins` | Maximum number of logins on the system
`memlock`      | Maximum locked-in-memory address space (KB)
`msgqueue`     | Maximum memory used by POSIX message queues (bytes)
`nice`         | Maximum nice priority allowed to raise to
`nofile`       | Maximum number of open file descriptors
`nonewprivs`   | `0` or `1`; `1` disables acquiring new privileges
`nproc`        | Maximum number of processes
`priority`     | The priority to run the user's processes with
`rss`          | Maximum resident set size (KB), ignored since Linux 2.4.30
`rtprio`       | Maximum realtime priority for non-privileged processes
`rttime`       | Timeout for real-time tasks (microseconds)
`sigpending`   | Maximum number of pending signals
`stack`        | Maximum stack size (KB)

Three of these are not available everywhere, and the resource does not
check: `pam_limits` logs an unknown item and skips the line, so setting
one writes a limit a newer module will honor rather than failing the run.
Which `pam_limits` is installed on a node is the operator's business.

Item         | Available in
------------ | ---------------------------------------------------------
`chroot`     | Debian and Ubuntu only. A distribution patch rather than an upstream item, so it is absent from the man page
`nonewprivs` | Linux-PAM 1.5.0 and newer, released November 2020
`rttime`     | Linux-PAM 1.7.1 and newer, released June 2025, so still ahead of most distributions

A value is a number, or one of `-1`, `unlimited` and `infinity` for no
limit, which the man page allows for every item except `priority`,
`nice` and `nonewprivs`. The resource does not check a value against its
item. No field may be empty or contain whitespace or a `#`, because
`pam_limits` splits a line on whitespace and ends it at a `#`, so such a
limit could not be read back from the file it was written to.

That includes a group whose name has a space in it, which `pam_limits`
has no way to name: there is no quoting or escaping in limits.conf, so
`@domain users` is read as the domain `@domain` followed by a type of
`users`. Groups like this usually come from a directory service. On a
node that resolves them through SSSD, the `override_space` option in
`sssd.conf` replaces the space with another character, and the group can
then be named that way, as `@domain_users`.

### Action: `create` (default)

This action will create the desired limit inside the limits file. This
will also have the affect of reformatting the limits file. Any comments
not attached to limits or lines that are not limits will be removed from
the file. Existing limits and attached comments will remain.

If the limit already exists in the file, any out-of-sync properties will
be updated. A limit is identified by the combination of domain, type,
and item.

### Action: `delete`

This action will delete the desired limit inside the limits file. A
limit is identified by the combination of domain, type, and item.

### Examples

```ruby
limit 'create example' do
  domain 'ftp'
  type 'hard'
  item 'nproc'
  value 0
  action :create
end

limit 'delete example' do
  path '/etc/security/limits.d/001_vader.conf'
  domain 'vader'
  type 'hard'
  item 'nofile'
  action :delete
end
```

[1]: https://github.com/jrwesolo/limits/actions/workflows/pipeline.yml/badge.svg?branch=main
[2]: https://github.com/jrwesolo/limits/actions/workflows/pipeline.yml
[3]: https://supermarket.chef.io/cookbooks/limits
[4]: https://github.com/jrwesolo/limits
[5]: https://man7.org/linux/man-pages/man5/limits.conf.5.html
