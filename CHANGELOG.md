limits cookbook CHANGELOG
=========================

v2.1.0 (2020-05-15)
-------------------

* Add support for Chef 16.x
* Update Chef Workstation to 0.18.3

v2.0.0 (2019-06-04)
-------------------

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

v1.0.0 (2014-12-07)
-------------------

This cookbook has changed to be an LWRP-only usage. No longer will
limits be able to be specified using attributes. Please see the
`README.md` for usage details.

* Development and testing using ChefDK
* Add ChefSpec tests
* Add Serverspec tests
* Change license from Apache to MIT

v0.2.0 (2014-04-09)
-------------------

* Initial release of limits
