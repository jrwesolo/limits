Testing
=======

Testing was performed using [Cinc Workstation 26.2.4][1].

```
$ cinc --version
Cinc Workstation version: 26.2.4
Cinc Client version: 19.3.14
Cinc Auditor version: 7.0.107
Cinc CLI version: 6.1.39
Biome version: unknown
Test Kitchen version: 4.1.4
Cookstyle version: 9.0.0
```

Perform tests using the following commands:

```bash
cinc exec cookstyle    # linting
cinc exec rspec        # spec tests
cinc exec kitchen test # integration tests
```

[1]: https://cinc.sh/start/workstation/
