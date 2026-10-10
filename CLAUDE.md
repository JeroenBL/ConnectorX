# ConnectorXGenerator

Goal: generate HelloID provisioning connector scripts (PowerShell V2) for a
target application, based on the templates in /templates.

## Workflow
1. Read docs/CONVENTIONS.md and the relevant template in /templates.
2. Read the API spec in /specs.
3. Generate the script in /generated/<target>/.
4. Run PSScriptAnalyzer and Pester tests; fix failures before presenting.
5. Summarize any assumptions or unknowns at the end. Do not guess silently.

## Hard rules
- Follow the template structure exactly (regions, try/catch, audit logs).
- Never hard-code credentials, URLs, or tenant details. Use
  $actionContext.Configuration.*.
- Never print secrets or full error records to output.
- Support DryRun: no write calls when $actionContext.DryRun is $true.
- If the spec is ambiguous (auth, endpoints, correlation field), ask
  instead of inventing.
- Do not make API calls to the target application.