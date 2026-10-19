# Repo layout

## Directory overview

| Path                         | Contains                                                                        | Write here?      |
| ---------------------------- | ------------------------------------------------------------------------------- | ---------------- |
| `.claude/skills/scout/`      | API research skill                                                              | No               |
| `.claude/skills/gen/`        | Code generation skill                                                           | No               |
| `templates/`                 | Connector templates that gen starts from                                        | No               |
| `examples/<connector-type>/` | Reference material only, split by type so Scout and gen find the right patterns | No               |
| `generated/<target>/`        | Real connectors, in progress or finished                                        | Yes (gen only)   |
| `tests/<target>/`            | Pester tests for generated connectors                                           | Yes (gen only)   |
| `specs/`                     | API specifications for target systems, plus gen's `endpoints.md` per target     | As needed        |
| `reports/`                   | Scout feasibility reports                                                       | Yes (Scout only) |
| `tools/`                     | Tools used by the skills, such as `Get-SpecDigest.ps1`                          | No               |
| `docs/`                      | Conventions and best practices                                                  | No               |
| `README.md`                  | Repository overview and usage instructions                                      | As needed        |

The connector type only determines which `examples/` directory to use. It never affects the `generated/` path: that path is flat by target name (`generated/<target>/`) for every connector type.

## Rules

- `templates/` contains source templates. Gen reads them and writes generated connectors to `generated/<target>/`. Scout does not use templates.
- `examples/<connector-type>/` contains reference material only. Scout and gen use the directory matching the specified connector type.
- `generated/<target>/` is the only location for generated connector implementations. Gen may create or update files there; Scout must never modify connector code.
- `tests/<target>/` stores the Pester tests gen writes for each generated connector.
- `specs/` stores API specifications used for research and generation, either as `specs/<target>/<file>` or as a loose `specs/<file>`. Gen also writes `specs/<target>/endpoints.md` with the confirmed endpoints.
- `reports/` stores Scout feasibility reports as `reports/<target>-feasibility.md`.
- `docs/` contains conventions and best practices.
- `tools/` contains supporting tools used by the skills.
