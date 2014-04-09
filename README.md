Description
===========

This cookbook is used to configure system limits.conf as well as
limits.d configuration files through LWRP.

Requirements
============

## Platform

* Debian
* Ubuntu
* CentOS
* Red Hat
* Fedora
* should work on most linux platforms, just not explicity tested

Attributes
==========

See `attributes/default.rb` for default values.

* `node['limits']['system_conf']` - Location of limits.conf on
system (defaults to /etc/security/limits.conf)
* `node['limits']['system_limits']` - Array of limits (default empty array)
* `node['limits']['conf_dir']` - Directory of limits.d
(defaults to /etc/security/limit.d)

Recipes
=======

## default

Include the default recipe in a run list in order to configure the
system limits.conf. Attribute node['limits']['system_limits'] will be used.

Resources/Providers
===================

## limits_config

This cookbook contains the `limits_config` LWRP. This LWRP will use
node['limits']['conf_dir'] to lay down a limits.d configuration file.

### Actions

- `:create`: creates limits.d config file
- `:delete`: removes limits.d config file

### Attribute Parameters

- `name`: will be used as the conf file name (limits.d/#{name}.conf)
- `limits`: array of limits (See example below for format)
- `system`: true or false, ignores name attribute in favor of
node['limits']['system_conf'] path

### Examples

    tomcat_limits = [{ 'domain' => 'tomcat',
                        'type'   => '-',
                        'item' => 'nofile',
                        'value' => '4096' }]

    # creates /etc/security/limits.d/tomcat.conf
    limits_config 'tomcat' do
      limits tomcat_limits
      action :create
    end

    # creates /etc/security/limits.conf
    limits_config 'configure system limits.conf' do
      limits tomcat_limits
      system true
      action :create
    end 

Usage
=====

Simply add dependency to gain access to limits_config LWRP (examples above).
In order to configure /etc/security/limits.conf, set node['limits']['system_limits']
and include_recipe 'limits::default'.

Testing
=======

* Used berkshelf >= 3.0.0 (Berksfile uses new source syntax)

License and Author
==================

* Author: Jordan Wesolowski (<jrwesolo@gmail.com>)

Copyright: 2014, Jordan Wesolowski

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.