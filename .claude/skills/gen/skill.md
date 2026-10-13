---
name: gen
description: Research a target API and generate a complete HelloID provisioning connector based on the API capabilities and existing connectors.
argument-hint: <target-system> <connector-type: rest|scim|soap|other>
disable-model-invocation: true
---

Generate a HelloID provisioning connector for: $ARGUMENTS

Parse $ARGUMENTS into a target system name and a connector type (rest,
scim, soap, or other). If either is missing or unclear, stop and ask —
the connector type determines which examples directory is used in
Step 5, and must not be guessed.

Generate a complete connector. Do not ask the user to specify individual
actions. Determine the required actions from the API capabilities,
project conventions, and existing connector implementations.

Do all work directly yourself. Do not invoke subagents.

## Step 1: Use scout for API research

Before researching the target API yourself, check whether
reports/<target>-feasibility.md exists.

Treat an existing report as current only if it explicitly references
the same spec/doc file (by name) that is available now for this
target, AND that spec/doc file's modification date is not newer than
the report's, AND it was researched for the same connector type given
here. If the report doesn't state which spec/doc or connector type it
was based on, or the spec file has changed since, treat it as outdated.

If the report is missing or outdated, invoke the scout skill for the
target, passing it the same connector type given here. Wait for it to
finish before continuing. Reuse its findings instead of repeating its
research. If the report is current, use it directly. If essential API
information is still missing after this, stop and ask for clarification.

scout is responsible for researching the API and comparing relevant
existing connectors. It must not generate or modify connector code —
if it did, treat that as a failure of scout to flag, not something to
build on.

## Step 2: Verify the research

Read:

- docs/conventions.md (hard rules)
- docs/conventions-best-practices.md (team best practices — applies
  alongside conventions.md, not instead of it)
- The scout feasibility report
- The templates relevant to the target
- The existing connector implementations referenced by scout

Verify the specific endpoints and schemas needed for implementation
against the original API specification using tools/Get-SpecDigest.ps1.

Do not assume that candidate endpoints in the scout report are
approved implementation choices. Identify any remaining uncertainties
before proposing the implementation.

Determine all applicable provisioning actions from the API capabilities,
project conventions, and existing connector implementations. Do not ask
the user to specify individual actions.

## Step 3: Propose the implementation — STOP HERE

Present:
- The relevant authentication flow and fields
- The account lookup and correlation strategy
- The proposed API endpoints for each provisioning action
- Which actions the API supports and any limitations
- Which existing connectors were used as references
- Any uncertainties or missing information

Determine the proposed actions by combining API capabilities,
project conventions, and existing connector patterns.

Do not assume every API operation maps directly to a provisioning
action. Likewise, do not omit a required action merely because the API
uses an unfamiliar endpoint or operation name.

Justify endpoint choices using paths, parameters, and request/response
fields rather than summaries or operation IDs alone.

Wait for my confirmation before generating code.

## Step 4: Inspect confirmed endpoints

After confirmation, run `Get-SpecDigest.ps1` in detail mode using
`-Route` and `-Method` for every confirmed endpoint.

Inspect the relevant schemas and authentication details.

Save the confirmed endpoint choices and API details to:

    specs/<target>/endpoints.md

Ask if essential information remains unclear.

## Step 5: Generate the connector

Generate all required connector files in:

`generated/<target>/`

Use:

1. `docs/conventions.md` for hard project rules
2. `docs/conventions-best-practices.md` for team best practices and
   design judgement calls
3. `specs/<target>/endpoints.md` for confirmed API details
4. Relevant existing connectors as implementation references
5. Templates in `templates/` as a starting point

- Implement the complete set of applicable provisioning actions according to the project conventions and the target API's capabilities.
- Reuse established patterns where appropriate, but do not blindly copy target-specific assumptions from other connectors.
- Keep the implementation simple and consistent with the project. Do not silently invent API behavior.

Inspect existing connectors for formatting and content references,
using the same connector-type examples directory that scout uses:

* rest → `./examples/rest`
* scim → `./examples/scim`
* soap or other → `./examples/<type>`, if it exists

If the relevant directory doesn't exist or is empty, use the most
relevant connector under `generated/` of the same connector type
instead, and note in Step 7's report that no dedicated examples
directory was found for this type.

### Required deliverables

Generate all applicable files and supporting documentation, including:

* All required provisioning action scripts
* Any required shared scripts or configuration files, following project conventions
* A comprehensive `README.md`
* A `CHANGELOG.md`
* Pester tests for the generated implementation

**README requirements**

The README must be comprehensive and consistent with the example connector README. Document the actual implementation, including:

* Connector purpose and supported functionality
* Supported provisioning actions and their behavior
* Prerequisites and required permissions
* Configuration and required parameters
* Authentication and credential configuration
* Account lookup and correlation behavior
* API endpoints used by each action
* Field mapping and relevant request/response behavior
* Error handling, limitations, and known caveats
* How to configure and use the connector in HelloID

Adapt the content to the target system. Do not copy irrelevant sections or document features that are not implemented. Do not claim behavior that has not been verified.

**Changelog requirements**

Create `CHANGELOG.md` using the exact format and conventions of the relevant existing generated connector changelog.

Inspect the example changelog before writing. Preserve its heading structure, version format, date format, entry style, and other formatting conventions. Record the initial implementation and its relevant functionality accurately. Do not invent release history or claim changes that were not made.

Verify that every generated file exists.

## Step 6: Write and execute tests and validation

### Pester tests — required

Write Pester tests for the generated connector. Do not skip test creation just because no tests already exist for the target.

Cover, where applicable:

* Successful execution of each implemented action
* Correct HTTP methods, URLs, headers, and request bodies
* Authentication handling without exposing credentials
* Account lookup and correlation, including missing or multiple matches
* Successful and unsuccessful API responses
* Missing, null, or unexpected response data
* Error handling and relevant edge cases
* DryRun behavior, where supported
* Correct output context and returned account references
* Action-specific behavior and important business rules

Follow the existing project's Pester version, conventions, and test structure. Reuse relevant test patterns from existing connectors.

Mock external API calls at the cmdlet level (e.g.
`Mock Invoke-RestMethod { ... }`) so tests can run without real
target-system credentials or making calls to the target API. Do not
wrap API calls in helper functions as a way to make mocking easier —
docs/conventions.md §10 forbids wrapping HTTP calls in functions, and
that rule takes precedence over test convenience. Do not introduce
unnecessary test frameworks or dependencies.

Execute the Pester tests after writing them. Fix failures and rerun the tests until they pass, or until a specific blocker prevents further progress.

If a test cannot be executed, explain why. Never report unexecuted tests as passing.

### PSScriptAnalyzer — required

Run PSScriptAnalyzer against every generated PowerShell script, including applicable test scripts.

Resolve reported issues where appropriate and rerun the analysis after making changes. Follow the project's conventions and any documented exceptions.

Report remaining warnings or errors explicitly. Do not claim a clean analysis unless it was actually run and the results support that claim.

### Final validation

Before completing the connector:

* Verify that all required files exist.
* Verify that every implemented action has relevant tests.
* Verify that Pester tests have actually been executed.
* Verify that PSScriptAnalyzer has actually been executed.

* Confirm that no API behavior or test result has been invented.

If an issue affects business logic, correlation, DryRun behavior, or authentication and cannot be resolved confidently, explain the issue rather than silently changing the intended behavior.

## Step 7: Report

Write the report to:

`generated/<target>/<target>-report.md`

Include:

* Files generated
* Actions implemented and unsupported actions
* API endpoints used for each action
* Existing connectors used as references
* Assumptions and unresolved questions
* Pester tests written and their actual execution results
* PSScriptAnalyzer results, including any remaining warnings or errors
* README and changelog completion
* Known limitations and anything requiring manual verification
* What still needs to be tested in HelloID

Clearly distinguish automated test results from manual testing that has not yet been performed.

Do not claim that the connector is fully tested or production-ready solely because Pester and PSScriptAnalyzer completed successfully. External API behavior and end-to-end provisioning must still be verified in an appropriate HelloID environment.

Note: this report (generated/<target>/<target>-report.md) is separate
from scout's feasibility report (reports/<target>-feasibility.md) —
one covers research before code existed, the other covers what was
actually built.