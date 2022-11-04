Testing
=======

Testing was performed using [Chef Workstation 22.10.1013][1].

```
$ chef --version
Chef Workstation version: 22.10.1013
Chef Infra Client version: 17.10.0
Chef InSpec version: 4.56.20
Chef CLI version: 5.6.1
Chef Habitat version: 1.6.521
Test Kitchen version: 3.3.2
Cookstyle version: 7.32.1
```

Perform tests using the following commands:

```bash
chef exec cookstyle    # linting
chef exec rspec        # spec tests
chef exec kitchen test # integration tests
```

[1]: https://www.chef.io/downloads/tools/workstation?v=22.10.1013
