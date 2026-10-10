---
name: new-connector
description: Generate a HelloID provisioning connector for a target system
argument-hint: <target-system> <action(s), comma-separated: create,update,enable,disable,delete>
disable-model-invocation: true
---

You are generating a HelloID provisioning connector for: $ARGUMENTS

Parse $ARGUMENTS into: target, and one or more actions (comma-separated).
If either is missing or unclear, stop and ask before continuing.

Follow these steps exactly, and stop wherever a step tells you to. Do
all work directly yourself — do not invoke any subagents.

## Step 1: Load context
Read, in this order:
1. docs/conventions.md
2. docs/conventions-<action>.md for each requested action. If any of
   these files does not exist or is still a placeholder, stop and ask
   before continuing for that action.
3. templates/<action>.ps1 for each requested action

CLAUDE.md is loaded automatically at session start; do not re-read it
here.

## Step 2: Build the spec digest
Locate the spec file in specs/<target>/ (the original OpenAPI/Swagger
file, e.g. .json or .yaml). If none is found, stop and ask for it.

Run: ./tools/Get-SpecDigest.ps1 -SpecPath specs/<target>/<file> -Keyword user,account,employee,person
If this returns nothing relevant, retry without -Keyword.

## Step 3: Propose endpoints — STOP HERE
Based on the digest, propose the endpoints for:
- token/authentication (including the request/response field names).
- lookup by correlation field
- create
- lookup by internal ID (needed for any of update/enable/disable/delete,
  if requested)
- the requested write endpoints for each other requested action

Justify each choice using path shape and field names from the digest,
NOT the summary or operationId (these are not always reliable).

Wait for my confirmation before continuing. Do not run any further steps
in this turn.

## Step 4: Fetch details
After confirmation: run Get-SpecDigest.ps1 in detail mode (-Route and
-Method) for each confirmed endpoint. Save the confirmed choice,
including the full auth request/response field names, to
specs/<target>/endpoints.md.

## Step 5: Generate the connector(s)
For each requested action, write generated/<target>/<action>.ps1,
following:
- the matching template in templates/<action>.ps1
- docs/conventions.md and docs/conventions-<action>.md
- the confirmed endpoints and auth details in specs/<target>/endpoints.md

Do not invent endpoints or auth beyond what is confirmed there. After
writing each file, verify it actually exists before treating that
action as done.

## Step 6: Validate
For each generated file, run:
- Invoke-ScriptAnalyzer -Path generated/<target>/<action>.ps1
- Invoke-Pester tests/ (if tests already exist for this target)

Fix straightforward style/syntax issues yourself. If an issue touches
business logic (correlation order, dry-run behavior, auth flow), stop
and show it to me instead of fixing it silently.

## Step 7: Report
End with a numbered list of:
- assumptions you made
- places where the spec was ambiguous, incomplete, or contradicted
  the template or conventions
- fields mapped without full certainty
- what I need to test in HelloID before this goes to review

Do not silently invent anything. When in doubt, ask instead of guessing.