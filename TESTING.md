Testing
=======

<!-- renovate: cinc-workstation -->
Tested with [Cinc Workstation][1] 26.2.4, which is the version CI installs
and the one Renovate keeps in step with `.github/actions/setup-cinc`. Run
`cinc --version` to see the client, auditor, CLI, Test Kitchen and Cookstyle
versions that ship inside it.

Perform tests using the following commands:

```bash
cinc exec cookstyle    # linting
cinc exec rspec        # spec tests
cinc exec kitchen test # integration tests
```

[1]: https://cinc.sh/start/workstation/
