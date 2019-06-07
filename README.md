Limits Cookbook
===============

This cookbook is used to configure limits for the `pam_limits` module.
By default, the configuration file is located at
`/etc/security/limits.conf`. It can also configure limits in any
arbitrary path such as files in the directory `/etc/security/limit.d`.
It is available on the [Chef Supermarket][1] or [GitHub][2].

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
this resource, but they do compliment each other.

Property  | Type             | Default                     | Required
--------- | ---------------- | --------------------------- | --------
`path`    | String           | `/etc/security/limits.conf` | No
`domain`  | String           | *none*                      | Yes
`type`    | *see note below* | *none*                      | Yes
`item`    | *see note below* | *none*                      | Yes
`value`   | Integer, String  | *none*                      | Yes
`comment` | String           | *none*                      | No

Please see `libraries/constants.rb` for valid types and limits. More
documentation on domain, type, item, and value can be found at the
following [man page][3].

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

Testing
=======

Testing was performed using [Chef Workstation 0.3.2][4].

```
$ chef --version
Chef Workstation: 0.3.2
  chef-run: 0.2.13
  chef-client: 14.13.11
  delivery-cli: 0.0.52 (9d07501a3b347cc687c902319d23dc32dd5fa621)
  berks: 7.0.8
  test-kitchen: 1.25.0
  inspec: 3.9.3
```

Perform tests using the following commands:

```bash
chef exec foodcritic .    # linting for common issues
chef exec cookstyle       # linting based on RuboCop
chef exec rspec           # spec tests
chef exec kitchen test    # integration tests
```

[1]: https://supermarket.chef.io/cookbooks/limits
[2]: https://github.com/jrwesolo/limits
[3]: https://linux.die.net/man/5/limits.conf
[4]: https://downloads.chef.io/chef-workstation/stable/0.3.2
