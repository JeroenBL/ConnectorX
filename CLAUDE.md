# ConnectorX

Researches target application APIs and generates HelloID provisioning target connectors (PowerShell V2) from the templates in `/templates`.

## Skills

| Skill | Does | Never |
|---|---|---|
| **Scout** | Researches an API and writes a feasibility report | Generates or modifies connector code |
| **gen** | Generates or updates connector scripts | Runs without an explicit user request |

Both skills require a **target system name** and a **connector type** (`rest`, `scim`, `soap`, or `other`). If either is missing, ask for it. Never guess the connector type.

A Scout task ends when the report is delivered. A positive verdict never starts gen automatically.

## Rules for every task

- Never call the target application's live environment. You may fetch public documentation and shared specification or response examples.
- If authentication, endpoints, correlation fields, or other essential API behavior is unclear, ask. Don't invent it.
- Report a step, file, or test as done only after checking it yourself. A subagent's or tool's summary is not proof.

## Read when relevant

- [Repo layout](docs/repo-layout.md): where `examples/` and `generated/` files go.
- [Conventions](docs/conventions.md): binding requirements.
- [Best practices](docs/conventions-best-practices.md): strong defaults; explain any departure.