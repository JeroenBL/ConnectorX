# ConnectorX

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/x.png" width="">
</p>

- [ConnectorX](#connectorx)
  - [Introduction](#introduction)
  - [Requirements](#requirements)
  - [Directory structure](#directory-structure)
  - [How to use](#how-to-use)
    - [Available skills](#available-skills)
      - [Scout](#scout)
        - [Using __Scout__](#using-scout)
      - [Gen](#gen)
        - [Using __Gen__](#using-gen)
    - [Output](#output)
    - [Running the checks manually](#running-the-checks-manually)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
    - [Bug report](#bug-report)
    - [Feature request](#feature-request)


## Introduction

Hi 👋

If you're looking to create a new target connector for HelloID provisioning and don't know where to start, you're in the right place.

__ConnectorX__ is the perfect starting point for building out your new connector, with all the essential resources you'll need to get started.

And the best part... __you don't have to code anything!__ :partying_face:

No more staring at a blank wondering which code goes where. No more copy-pasting logic and hoping it still works.
__ConnectorX__ reads an OpenAPI spec, asks you the two or three things only a human should decide, and writes the rest. :sunglasses:

## Requirements

- [Claude CLI](https://docs.claude.com/en/docs/claude-code/overview)
- [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
  - [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
  - [Pester](https://pester.dev)
  - [PowerShell-Yaml](https://github.com/cloudbase/powershell-yaml)
Install the PowerShell modules:

```powershell
Install-Module PSScriptAnalyzer, Pester, powershell-yaml -Scope CurrentUser
```

## Directory structure

```text
.
├── .claude/
│   ├── commands/        # Slash commands (e.g. /new-connector)
│   └── skills/
│       ├── scout/       # API research skill
│       └── gen/         # Code generation skill
├── docs/                # Conventions and best practices
├── generated/           # Generated and existing connectors
│   └── <target>/
│       ├── create.ps1
│       ├── update.ps1
│       ├── enable.ps1
│       ├── disable.ps1
│       ├── delete.ps1
│       ├── tests/       # Pester tests
│       └── README.md    # Connector documentation
├── specs/               # API specs for target systems
├── reports/             # Scout feasibility reports
├── templates/           # Connector templates
├── tools/               # Tools used by the skills. Like: `Get-SpecDigest`
└── README.md
```

## How to use

The typical flow is: **Scout** researches the target system, then **Gen** builds the connector from that research.

```text
Scout  ->  reports/<target>-feasibility.md  ->  Gen  ->  generated/<target>/
```

### Available skills

#### Scout

<p align="left">
  <img src="./scout.png" width="150">
</p>

__Scout__ is the API research skill. It investigates a target system's API, authentication methods, account lookup and correlation capabilities, and supported provisioning operations. It also compares the API with existing generated connectors to identify reusable implementation patterns, limitations, and potential risks.

Scout produces a feasibility report in `reports/<target>-feasibility.md` for the [Gen](#gen) skill to use during development.

> [!IMPORTANT]
> Scout is research-only. It does not generate or modify code.

##### Using __Scout__

1. Open a terminal in the repo and start Claude.
2. Run the command:
```text
   /scout <API Type> <spec>
```
   - `<API Type>`: the type of API you want to research. Eg. _rest_ or _scim_.
   - `<spec>`: the location of the API specfication. Either in JSON/YAML format or a PDF/Word document.
3. Review the report in `reports/<target>-feasibility.md`. Check the authentication method, the account correlation strategy, the supported operations, and the listed risks before moving on to Gen.
#### Gen

<p align="left">
  <img src="./gen.png" width="150">
</p>

__Gen__ is the code generation skill. It uses Scout's API research, project conventions, templates, and existing connectors to determine the required provisioning actions and generate a complete PowerShell V2 connector.

Before generating code, it presents the proposed authentication flow, account lookup and correlation strategy, API endpoints, and supported actions for confirmation. Once approved, __Gen__ generates the lifecycle actions, writes and executes Pester tests, runs PSScriptAnalyzer, and creates comprehensive documentation.

##### Using __Gen__

1. Open a terminal in the repo.
2. Drop the OpenAPI specification where ConnectorX expects it (`openapi/<target>.yaml`).
3. Type the command: `/new-connector <target> <action(s)>`
   - `<target>`: a short name for the system you're connecting to, e.g. `example`
   - `APi Type`: the type of API. Eg _rest_ or _scim_.
   **Examples**
```text
   /gen example rest
```

1. Wait for the API endpoints proposal. ConnectorX will come back with something like:
   > Proposed endpoints for `example`:
   > - Token: `POST /oauth/token` (body: client_id, client_secret)
   > - Correlation lookup: `GET /users/employeeid/{id}`
   > - Create: `POST /users`
   >
   > Confirm?
2. Confirm the proposal, or reply with corrections (for example a different correlation field or endpoint).
3. Let __gen__ finish the work. It will:
   - generate the lifecycle actions
   - write and run the Pester tests
   - run PSScriptAnalyzer and fix findings
   - write the connector documentation

### Output

After a successful run you will find:

| Output | Location |
| --- | --- |
| Feasibility report (Scout) | `reports/<target>-feasibility.md` |
| Lifecycle action scripts | `generated/<target>/` |
| Pester tests | `generated/<target>/tests/` |
| Connector documentation | `generated/<target>/README.md` |

### Running the checks manually

```powershell
# Tests
Invoke-Pester -Path ./generated/<target>/tests

# Static analysis
Invoke-ScriptAnalyzer -Path ./generated/<target> -Recurse
```

## Troubleshooting

- **Gen asks for missing information:** run Scout first, or make sure the OpenAPI file is in place.
- **Proposed endpoints look wrong:** don't confirm. Reply with the correct endpoints and Gen will revise the proposal.
- **PSScriptAnalyzer or Pester not found:** install the modules listed under [Requirements](#requirements) and run from PowerShell 7 (`pwsh`).

## Contributing

If you have an idea or suggestion for improving the _ConnectortX_, one of the best ways to get involved is by opening up an issue on the repo.

### Bug report
🪲

To submit a new issue, navigate to the `Issues` tab on the repository page and click the `New Issue` button. Describe the issue in as much detail as possible, including any error messages or steps to reproduce the issue. This will help the development team to diagnose and fix the problem.

### Feature request
🚀

To request a new feature, create a new issue using the same process as for a bug report. Be sure to describe the feature you would like to see added, and explain how it would improve your experience.