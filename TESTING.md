Testing
=======

Testing was performed using [Chef Workstation 25.13.7][1].

```
$ chef --version
Chef Workstation version: 25.13.7
Chef CLI version: 5.6.23
Chef Habitat version: 1.6.1243
Test Kitchen version: 3.9.1
Cookstyle version: 7.32.8
Chef Infra Client version: 18.10.17
Chef InSpec version: 5.24.7
```

Perform tests using the following commands:

```bash
chef exec cookstyle    # linting
chef exec rspec        # spec tests
chef exec kitchen test # integration tests
```

[1]: https://docs.chef.io/workstation/25/install/
