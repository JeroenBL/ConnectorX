# ConnectorX

## Goal

Assist with HelloID provisioning Target Connectors through two
capabilities:

- **Scout:** investigate target application APIs using specifications
  and documentation, and existing connectors in this repo. Produces a
  feasibility report only — never generates or modifies connector
  code.
- **gen:** generate HelloID provisioning connector scripts
  (PowerShell V2) using the templates in `/templates`.

Both skills require a target system name and a connector type (rest,
scim, soap, or other) as arguments — the connector type determines
which `./examples/<type>` directory is used for reference and must
never be guessed or inferred silently. The connector type is only used
to pick the right examples directory; it has no effect on where
generated connectors themselves are stored.

These capabilities can be used independently or together. Scout's
report is a human-reviewed input to gen, never an automatic
hand-off — a positive feasibility verdict does not by itself trigger
code generation.

## General workflow

1. Read the relevant documentation in `/docs` — both
   `docs/conventions.md` (hard rules) and
   `docs/conventions-best-practices.md` (team judgement calls) apply
   to every task, not just one or the other.
2. Use Scout when API research is needed.
3. Identify missing information and ask questions when necessary.
4. Use gen when connector code needs to be generated or updated.
5. Save generated scripts in `/generated/<target>/` — flat by target
   name, regardless of connector type. Reference material for
   formatting and prior patterns lives separately, under
   `/examples/<connector-type>/`. Never confuse the two: `generated/`
   holds real, in-progress or finished connectors; `examples/` holds
   reference-only material, split by type purely so Scout and gen
   look in the right place.
6. Run the applicable checks and tests for the task.
7. Summarize findings, assumptions, unresolved questions, and test
   results.

## Hard rules

- Follow `docs/conventions.md` and `docs/conventions-best-practices.md`,
  and the relevant templates, when generating connector code.
- Never hard-code credentials, URLs, or tenant-specific details. Use
  `$actionContext.Configuration.*` where appropriate.
- Never print secrets or expose full error records in output or logs.
- Support DryRun: do not execute write operations when
  `$actionContext.DryRun -eq $true`.
- If authentication, endpoints, correlation fields, or other essential
  API behavior is ambiguous, ask instead of inventing.
- Never make live API calls to the target application itself during
  research or generation — all understanding of its behavior must come
  from the supplied specification, documentation, or digest output.
  Fetching a public documentation page or a shared spec/response
  example (not the target's live environment) is not covered by this
  rule and is expected where a skill's own instructions call for it.
- Never claim a step was completed, a file was written, or a test
  passed unless it was actually executed and verified — check for the
  file or the test result directly rather than assuming success from
  a subagent's or tool's summary alone.
- Keep output focused: no unnecessary abstractions or rewrites in
  generated code, and no unrequested scope in a Scout report beyond
  what its own SKILL.md defines.