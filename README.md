Limits Cookbook
===============

This cookbook is used to configure system limits.conf as well as limits.d configuration files. It is available at the [Supermarket](https://supermarket.chef.io/cookbooks/limits) or [GitHub](https://github.com/jrwesolo/limits).

## Platforms

* Debian
* Ubuntu
* Fedora
* CentOS
* Red Hat

*This should work on most linux platforms, but it has not been explicitly testing unless in the list above.*

Attributes
==========

**Under most circumstances, these can be left at the defaults.**

| Key | Type | Description | Default |
| --- | ---- | ----------- | ------- |
| `['limits']['system_conf']` | String | Location of system-wide limits.conf | `/etc/security/limits.conf` |
| `['limits']['conf_dir']` | String | Location of limits.d directory | `/etc/security/limits.d` |

Usage
=====

## Definition (recommended)

### `set_limit`

### Attribute Parameters

| Key | Type | Description | Default |
| --- | ---- | ----------- | ------- |
| `use_system` | Boolean | Set a system-wide limit? | `false` |
| `filename` | String | Filename that will contain limit | *`{resource name}`*, unused if `use_system == true` |
| `domain` | String or Integer | domain of limit | *`{resource name}`* |
| `type` | String or Integer | type of limit | `nil` |
| `item` | String or Integer | item of limit | `nil` |
| `value` | String or Integer | value of limit | `nil` |

### Examples

```ruby
# Limits for Alice

set_limit 'alice' do
  type 'hard'
  item 'nofile'
  value 2048
end

set_limit 'alice' do
  type 'soft'
  item 'nofile'
  value 1024
end

# System-wide limits

set_limit '*' do
  type 'hard'
  item 'nofile'
  value 4096
  use_system true
end

set_limit '*' do
  type 'soft'
  item 'nofile'
  value 1024
  use_system true
end
```

Would render:

```
# /etc/security/limits.d/alice.conf

alice hard nofile 2048
alice soft nofile 1024
```

```
# /etc/security/limits.conf

* hard nofile 4096
* soft nofile 1024
```

## LWRP

### `limits_config`

### Actions

| Name | Description |
| ---- | ----------- |
| `:create` | creates limits config file (default) |
| `:delete` | deletes limits config file |


### Attribute Parameters

| Key | Type | Description | Default |
| --- | ---- | ----------- | ------- |
| `use_system` | Boolean | Set system-wide limits? | `false` |
| `filename` | String | Filename that will contain limits | *`{resource name}`*, unused if `use_system == true` |
| `limits` | Array | Array of limits (see examples) | `[]` |

### Examples

```ruby
# Limits for Alice

limits_config 'alice' do
  limits [
    { domain: 'alice', type: 'hard', item: 'nofile', value: 2048 },
    { domain: 'alice', type: 'soft', item: 'nofile', value: 1024 }
  ]
end

# System-wide limits

limits_config 'system-wide limits' do
  limits [
    { domain: '*', type: 'hard', item: 'nofile', value: 4096 },
    { domain: '*', type: 'soft', item: 'nofile', value: 1024 }
  ]
  use_system true
end
```

Would render:

```
# /etc/security/limits.d/alice.conf

alice hard nofile 2048
alice soft nofile 1024
```

```
# /etc/security/limits.conf

* hard nofile 4096
* soft nofile 1024
```

Testing
=======

Testing was performed using [Chef Development Kit](https://downloads.chef.io/chef-dk/) 0.3.5.

#### ChefSpec

```bash
chef exec rspec
```

#### Serverspec (through Test Kitchen)

```bash
kitchen test
```

License and Author
==================

* Author: Jordan Wesolowski (<jrwesolo@gmail.com>)

```text
The MIT License (MIT)

Copyright (c) 2014 Jordan Wesolowski

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
