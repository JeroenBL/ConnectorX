# Changelog

All notable changes to ConnectorX (the HelloID connector generator) are
documented here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [0.0.2]
 
### Added
- `AGENTS.md` as the shared, tool-neutral source of truth for project
  rules (previously only `CLAUDE.md`), enabling reuse across Claude
  Code, OpenAI Codex, GitHub Copilot.
- Cross-tool skill layout for `/new-connector`: the skill now exists as
  a `SKILL.md` directory (the shared `agentskills.io` format) instead
  of a single command file, mirrored across each tool's expected
  location:
  - `.claude/skills/new-connector/SKILL.md` (Claude Code)
  - `.agents/skills/new-connector/SKILL.md` (Codex)
  - `.github/skills/new-connector/SKILL.md` (Copilot)

## [0.0.1]

### Added
- `.claude/commands/new-connector.md` — the `/new-connector` skill:
  reads conventions and templates, builds a spec digest, proposes
  endpoints and stops for human confirmation, fetches endpoint detail,
  generates the connector script(s), runs PSScriptAnalyzer and Pester,
  and reports assumptions/ambiguities at the end.
- `tools/Get-SpecDigest.ps1` — parses an OpenAPI/Swagger spec (JSON or
  YAML) into a compact digest (method, path, params, body/response
  field names) for use by the skill, plus an optional detail mode for
  a specific route/method.
- `docs/conventions.md` — shared rules for every generated connector
  (file structure, naming, secrets handling, auth, dry-run, output
  context, audit logs, error handling, HTTP call shape).
- `docs/conventions-create.md` — create-specific rules: the
  correlation decision (create vs. correlate) and the
  `AccountCorrelated` output field.
- Introduction and "How it works" / "Getting started" sections for
  ConnectorX's own documentation.
- A reference diagram of the end-to-end intake pipeline: TopDesk
  request → feasibility check (digest + report) → development →
  testing, with a feedback loop back to the request when required API
  information is missing.

### Changed
- `tools/Get-SpecDigest.ps1`: fixed a variable name collision
  (`$Path` parameter vs. `$path` loop variable, case-insensitive in
  PowerShell) that silently produced an empty digest.
- `tools/Get-SpecDigest.ps1`: detail mode now accepts arrays for
  `-Route`/`-Method` (matched by position) so multiple confirmed
  endpoints can be fetched in one call, with an explicit warning when
  a route or method isn't found in the spec instead of failing
  silently.
- `docs/conventions.md` §4 (Authentication): generalized beyond OAuth.
  The security-scheme block in a digest only describes how a
  credential is *presented*, never where it comes from — the rule now
  covers OAuth2 token endpoints, static API keys, Basic Auth, and
  other schemes, and requires `endpoints.md` to document the actual
  credential source, not just the presentation scheme.
- `docs/conventions.md`: added §14 "No placeholder implementations" —
  every HTTP call implied by a template (including ones only sketched
  as a comment) must be fully implemented against confirmed endpoints;
  hardcoded stand-ins (e.g. `New-Guid`) are never acceptable output.
- `docs/conventions.md` §10: added a rule against sending fields marked
  `readOnly` in request bodies.
- `docs/conventions-create.md`: added an explicit requirement that the
  correlation lookup must be a real `Invoke-RestMethod` call (with
  Authorization header and 404 handling), not a placeholder object —
  closing a gap where generated scripts left the lookup as a stub.
- `.claude/commands/new-connector.md` — Step 2: the spec digest is now
  built with two separate keyword passes (business/account fields,
  and auth-related fields run separately) after discovering that a
  single keyword filter could return a non-empty but still incomplete
  result, silently dropping the authentication endpoint.
- `.claude/commands/new-connector.md` — Step 4: detail-mode lookup is
  now conditional (only run for nested/ambiguous schemas) rather than
  mandatory for every endpoint, and explicitly requires checking the
  full spec entry (not just the digest line) for `readOnly` markers
  and free-text business rules.
- `.claude/commands/new-connector.md` — Step 5: added a verification
  step requiring the generated file's existence to be checked before
  treating an action as complete, after a run silently reported
  completion without producing a file.
- `.claude/commands/new-connector.md`: reverted from a three-subagent
  architecture (`researcher` / `developer` / `tester`) back to a
  single-session skill, after a subagent invocation completed with
  zero tool calls and no output file, with no visibility into why from
  the main session. Subagent definitions remain in `.claude/agents/`
  but are no longer invoked by this skill.
- Removed references to a `/snippets` auth-snippet directory
  throughout the skill and conventions; authentication details are
  now sourced entirely from the spec digest and `endpoints.md`.

### Removed
- `connector-writer` subagent reference (superseded by `developer`,
  then removed entirely with the subagent architecture).

### Known issues / open items
- `docs/conventions-update.md`, `-enable.md`, `-disable.md`, and
  `-delete.md` do not exist yet — the skill will stop and ask rather
  than generate those actions until they're written.
- No CI integration yet (PSScriptAnalyzer/Pester run manually or via
  the skill, not on pull request).
