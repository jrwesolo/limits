limits cookbook CHANGELOG
=========================

[v2.2.1][] (2022-11-04)
-----------------------
* Added testing for Chef Infra Client 18


[v2.2.0][] (2020-12-30)
-----------------------

* Add support for Chef 17
* Update Chef Workstation to 20.12.205
* Cookstyle-recommended fixes
* Test kitchen will test more platforms
* Test kitchen will perform two converges and ensure idempotency
* Add TESTING.md file

[v2.1.1][] (2020-06-22)
-----------------------

* Chef 16.2.x had a backwards-incompatible change related to custom
  resources. This version supports the new style while maintaining
  backwards-compatibility.
* Update Chef Workstation to 20.6.62

[v2.1.0][] (2020-05-15)
-----------------------

* Add support for Chef 16.x
* Update Chef Workstation to 0.18.3

[v2.0.0][] (2019-06-04)
-----------------------

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

[v1.0.0][] (2014-12-07)
-----------------------

This cookbook has changed to be an LWRP-only usage. No longer will
limits be able to be specified using attributes. Please see the
`README.md` for usage details.

* Development and testing using ChefDK
* Add ChefSpec tests
* Add Serverspec tests
* Change license from Apache to MIT

[v0.2.0][] (2014-04-09)
-----------------------

* Initial release of limits

[v2.2.0]: https://github.com/jrwesolo/limits/tree/v2.2.0
[v2.1.1]: https://github.com/jrwesolo/limits/tree/v2.1.1
[v2.1.0]: https://github.com/jrwesolo/limits/tree/v2.1.0
[v2.0.0]: https://github.com/jrwesolo/limits/tree/v2.0.0
[v1.0.0]: https://github.com/jrwesolo/limits/tree/v1.0.0
[v0.2.0]: https://github.com/jrwesolo/limits/tree/v0.2.0
