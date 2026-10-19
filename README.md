# ConnectorX

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/x.png" width="">
</p>

- [ConnectorX](#connectorx)
  - [Introduction](#introduction)
  - [How it works](#how-it-works)
  - [Requirements](#requirements)
  - [Directory structure](#directory-structure)
  - [How to use](#how-to-use)
    - [Available skills](#available-skills)
      - [Scout](#scout)
        - [Using __scout__](#using-scout)
      - [Gen](#gen)
        - [Using __gen__](#using-gen)
  - [Remarks](#remarks)
    - [Gen requires a current scout report](#gen-requires-a-current-scout-report)
    - [Gen does not start scout](#gen-does-not-start-scout)
    - [Blocking questions must be answered first](#blocking-questions-must-be-answered-first)
    - [Never the live environment](#never-the-live-environment)
    - [Generated is not the same as tested](#generated-is-not-the-same-as-tested)


## Introduction

Hi 👋

If you're looking to create a new target connector for HelloID provisioning and don't know where to start, you're in the right place.

__ConnectorX__ is the perfect starting point for building out your new connector, with all the essential resources you'll need to get started.

And the best part... __you don't have to code anything!__ :partying_face:

No more staring at a blank wondering which code goes where. No more copy-pasting logic and hoping it still works.
__ConnectorX__ reads the target's API specification, asks you the few things only a human should decide, and writes the rest. :sunglasses:

## How it works

ConnectorX uses two skills, run one after the other. [Scout](#scout) researches the API and writes a feasibility report. [Gen](#gen) builds the connector from that report, but only when you start it, only when the report is current, and only when the verdict is _Feasible_ or _Feasible with caveats_.

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/pipeline.png" alt="Flowchart from scout to gen. Scout checks the connector type and spec, researches the API, compares it, proposes endpoints and a verdict, writes the feasibility report and stops. You then run gen. Gen checks its arguments, whether the report is current, and the verdict. Not feasible or Insufficient information stops gen. Feasible or Feasible with caveats continues to a plan that waits for your confirmation, then endpoints.md, code generation, tests, and the generation report." width="620">
</p>

When does __gen__ run?

| Condition | Gen |
|---|---|
| Target or connector type missing | Asks for it. The type is never guessed |
| No feasibility report for the target | Stops: run `/scout <target> <type>` first |
| Report type differs from the type given to gen | Stops: run scout again |
| The report's source spec no longer exists in `specs/` | Stops: run scout again |
| The spec was changed after the report's _Spec last modified_ date | Stops: run scout again |
| The report's header table is incomplete | Stops: run scout again |
| Verdict _Not feasible_ or _Insufficient information_ | Stops and explains why. Nothing is generated |
| Verdict _Feasible_ or _Feasible with caveats_ | Continues to the plan, then waits for your confirmation |
| Blocking question unanswered: authentication or correlation | Stops |
| Blocking question unanswered: any other action | Builds the connector without the affected actions |

## Requirements

- Claude CLI
- PowerShell 7
  - [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer)
  - [Pester](https://www.powershellgallery.com/packages/Pester) (5 or later)
  - [powershell-yaml](https://www.powershellgallery.com/packages/powershell-yaml) (used by `tools/Get-SpecDigest.ps1` to read YAML specs)

## Directory structure

| Path | Contains | Written by |
|---|---|---|
| `.claude/skills/scout/` | The scout skill | — |
| `.claude/skills/gen/` | The gen skill | — |
| `docs/` | Conventions (`conventions.md`) and team best practices (`conventions-best-practices.md`) | — |
| `templates/` | Connector templates gen starts from | — |
| `examples/<connector-type>/` | Reference connectors, split by type (`rest`, `scim`, ...) | — |
| `tools/` | Supporting tools, such as `Get-SpecDigest.ps1` | — |
| `specs/` | API specifications, as `specs/<target>/<file>` or a loose `specs/<file>`, plus gen's `specs/<target>/endpoints.md` | You (spec), gen (`endpoints.md`) |
| `reports/` | Feasibility reports: `reports/<target>-feasibility.md` | Scout only |
| `generated/<target>/` | Generated connectors | Gen only |
| `tests/<target>/` | Pester tests for generated connectors | Gen only |

The connector type only decides which `examples/` folder is used. Generated connectors always go to `generated/<target>/`, whatever their type.

## How to use

### Available skills

Both skills need a __target system name__ and a __connector type__: `rest`, `scim`, `soap` or `other`. If either is missing, the skill asks for it. The connector type is never guessed.

#### Scout

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/scout.png" width="150">
</p>

__Scout__ is the API research skill. It reads the target's API specification and establishes:

- The authentication method, including where the credential comes from
- Account listing, correlation lookup, and get by ID
- Create, update, enable/disable, delete, and permissions
- Constraints such as pagination, rate limits, and uniqueness

Each finding gets a status (_Confirmed_, _Potential_, _Not found_ or _Unclear_) and the evidence behind it. Scout then compares the API with the baseline in `examples/BasicTargetReadme.md`, checks it against the project conventions, and reviews the existing connectors in `examples/<type>/`.

Scout produces a feasibility report in `reports/<target>-feasibility.md` for the [gen](#gen) skill to use during development. The report proposes one endpoint per action and gives a verdict: _Feasible_, _Feasible with caveats_, _Not feasible_ or _Insufficient information_, with a confidence level.

> [!IMPORTANT]
> Scout is research-only. It does not generate or modify code, and it never starts __gen__.

##### Using __scout__

1. Open a terminal in the repo.
2. Put the API specification in `specs/`, as `specs/<target>/<file>` or as a loose `specs/<file>`. Scout accepts an OpenAPI JSON or YAML file, a WSDL, a PDF or a DOCX. You can also give it a public documentation URL.
3. Type the command `/scout <target> <type>`
   - `<target>`
   a short name for the system you're connecting to, e.g. `ACME`. It matches the folder or file name in `specs/`.
   - `<type>`
   the connector type: `rest`, `scim`, `soap` or `other`.

    **Example**
    ```
    /scout ACME rest
    ```
4. Answer scout's questions, if it has any. For example, which spec to use when there's more than one.
5. Read the report in `reports/<target>-feasibility.md`. Pay attention to the verdict and the _blocking_ open questions. Those are the ones gen will ask you to answer.

#### Gen

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/gen.png" width="150">
</p>

__Gen__ is the code generation skill. It uses Scout's API research, project conventions, templates, and existing connectors to determine the required provisioning actions and generate a complete PowerShell V2 connector. You don't pick individual actions: gen builds every action the report and your answers support.

Before generating code, it presents the proposed authentication flow, account lookup and correlation strategy, API endpoints, and supported actions for confirmation. Once approved, __gen__:

- Writes the confirmed choices to `specs/<target>/endpoints.md`
- Generates the lifecycle actions, configuration, field mapping, `README.md`, and `CHANGELOG.md` in `generated/<target>/`
- Writes and runs Pester tests in `tests/<target>/`, and runs PSScriptAnalyzer
- Writes a report of what was built and tested to `generated/<target>/<target>-report.md`

##### Using __gen__

1. Run [scout](#using-scout) first and make sure its report is current.
2. Type the command `/gen <target> <type>`. Use the same target and type you used for scout.

    **Example**
    ```
    /gen ACME rest
    ```
3. Wait for the implementation plan.
    >  ConnectorX will come back with something like:<br>
    > Proposed implementation for `ACME`:
    > - Token: `POST /oauth/token` (client_id, client_secret, grant_type, scope)
    > - Correlation lookup: `GET /api/hello-id/users/{employeeId}`
    > - Create: `POST /api/hello-id/users`
    > - Enable / Disable: `PATCH /api/hello-id/users/{employeeId}` ⚠ _Potential_
    >
    > Blocking questions: Is `employeeId` immutable? Does PATCH accept a partial body?
    >
    > Confirm?
4. Answer the blocking questions and confirm the plan.
5. Let __ConnectorX__ finish the work.
6. Read `generated/<target>/<target>-report.md` for what was built, what was tested, and what still needs testing in HelloID.

## Remarks

### Gen requires a current scout report

__Gen__ does not research the API itself. It builds on the feasibility report in `reports/<target>-feasibility.md`. The report must be current, which __gen__ checks against the report's header table:

- The connector type matches the one you pass to __gen__.
- The source spec still exists under `specs/`.
- The spec hasn't been modified since the report was written.

If the verdict is _Not feasible_ or _Insufficient information_, __gen__ stops and doesn't generate anything.

### Gen does not start scout

If the report is missing or outdated, __gen__ stops and asks you to run `/scout <target> <type>` first. It never starts __scout__ for you. In the same way, a positive scout verdict never starts __gen__ automatically.

### Blocking questions must be answered first

The proposal lists every endpoint that scout couldn't confirm and every _blocking_ open question from the report. Answer them before you confirm. __Gen__ never guesses an answer:

- An unanswered question about authentication or correlation stops __gen__ completely.
- Any other unanswered question leaves out the actions it affects, and the final report records this.

### Never the live environment

Neither skill calls the target application's live environment. They read the spec in `specs/` and may fetch public documentation. Gen's Pester tests mock every API call.

### Generated is not the same as tested

Passing Pester tests and a clean PSScriptAnalyzer run do not make a connector production-ready. Always test every action, including reconciliation and reboarding, in a HelloID environment with both the cloud agent and the on-premises agent.
