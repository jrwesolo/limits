Testing
=======

Testing was performed using [Chef Workstation 20.12.205][1].

```
$ chef --version
Chef Workstation version: 20.12.205
Chef Infra Client version: 16.8.14
Chef InSpec version: 4.24.8
Chef CLI version: 3.0.33
Chef Habitat version: 1.6.181
Test Kitchen version: 2.8.0
Cookstyle version: 7.3.11
```

Perform tests using the following commands:

```bash
chef exec cookstyle    # linting
chef exec rspec        # spec tests
chef exec kitchen test # integration tests
```

[1]: https://downloads.chef.io/products/workstation/stable?v=20.12.205
