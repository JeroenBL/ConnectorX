# Connector conventions (HelloID PowerShell V2)

These rules apply to every generated connector, for every action (create,
update, disable, enable, delete). Action-specific rules live in separate
files — see section 13.

If a rule conflicts with the API spec, follow the rule and list the
conflict in your summary.

## 1. File structure

Every script follows this order:

1. Header comment: `HelloID-Conn-Prov-Target-<System>-<Action>` and `PowerShell V2`
2. TLS 1.2 line
3. `#region functions` (helpers only, no logic)
4. Main `try { ... } catch { ... }`

File names: `create.ps1`, `update.ps1`, `disable.ps1`, `enable.ps1`, `delete.ps1`.
One folder per target: `generated/<target>/`.

## 2. Naming

- Helper functions: `Verb-<System>Thing` with approved verbs
  (e.g. `Resolve-<System>Error`, `Invoke-<System>Request`).
- Splatted parameter hashtables: `$splat<Purpose>Params`
  (e.g. `$splatRetrieveTokenParams`, `$splatGetAccountParams`).
- `<System>` is the PascalCase application name, used consistently in helper
  names, audit messages and log lines.

## 3. Configuration and secrets

- All URLs, client IDs, secrets and tenant values come from
  `$actionContext.Configuration.*`. Never hard-code them.
- Never write secrets, tokens, request bodies or full error records to any
  output stream (no `$_ | ConvertTo-Json | Write-Warning`).
- In examples, tests and prompts, use placeholders such as
  `<CLIENT_ID>`, never real values.

## 4. Authentication

- Authentication is a separate step that runs before any account lookup.
- The security scheme shown in a digest's "--- security ---" block
  (e.g. "Bearer", "ApiKey", "Basic") only describes how a credential is
  PRESENTED on each call. It never tells you where that credential
  comes from. Depending on the auth method, the source is one of:
  - OAuth2 (client credentials or similar): a token endpoint, typically
    tagged "OAuth" and found among the other operations (commonly
    POST .../token). Document its path, method, request fields, and
    response fields in endpoints.md.
  - Static API key: a value from $actionContext.Configuration (e.g. a
    header or query parameter). No token endpoint exists; document
    which header/query parameter name the spec expects.
  - Basic Auth: a username/password from $actionContext.Configuration,
    base64-encoded into the Authorization header. No token endpoint.
  - Any other scheme found in the spec: document exactly what is
    needed to construct it, even if it does not fit the patterns above.
- If endpoints.md documents only the presentation scheme (e.g. "Bearer,
  JWT") without saying where the credential comes from, treat it as
  incomplete per section 12 — regardless of which auth method applies.
- For OAuth-style flows: cache nothing between runs; request a token
  per execution. For static credentials (API key, Basic): read them
  from $actionContext.Configuration per execution; there is nothing to
  request or refresh.
- Every Invoke-RestMethod call made after the auth step must include
  the correct header (or query parameter) for whichever auth method is
  confirmed in endpoints.md — e.g. Headers = @{ Authorization = "Bearer
  $($token.access_token)" } for OAuth, or Headers = @{ "X-Api-Key" =
  $actionContext.Configuration.ApiKey } for an API key. A call missing
  this is incomplete, even if it would otherwise run successfully
  against a lenient test API.

## 5. Account lookup

- Every action except create looks up the account by
  `$outputContext.AccountReference` (the target system's internal ID),
  not by the correlation field. The correlation decision (create vs.
  correlate) only happens in create — see
  docs/conventions-create.md.
- If the lookup returns nothing, follow the rule in the relevant
  `conventions-<action>.md` file. Do not guess the right behavior.

## 6. Dry run

- When `$actionContext.DryRun -eq $true`, make no write calls
  (POST, PUT, PATCH, DELETE).
- Read calls (token, lookup) still run.
- Log a `[DryRun]` message describing what would have happened.

## 7. Output context

Set these on every successful path, for every action:

| Property | Rule |
|---|---|
| `$outputContext.success` | Set explicitly to `$true` or `$false` on every path |
| `$outputContext.AccountReference` | The target system's unique ID |
| `$outputContext.Data` | The account object returned by the API |

Action-specific output fields (e.g. `AccountCorrelated` for create) are
listed in the matching `conventions-<action>.md` file.

## 8. Audit logs

- Every path ends with exactly one `AuditLogs.Add`, with `Action`, `Message`
  and `IsError`.
- Success messages include the AccountReference:
  `"<Action> account was successful. AccountReference is: [<id>]"`.
- Error messages start with what failed:
  `"Could not <action> <System> account. Error: <friendly message>"`.
- Audit messages contain no secrets and no personal data beyond IDs.

## 9. Error handling

- One `Resolve-<System>Error` helper per connector, returning
  `ScriptLineNumber`, `Line`, `ErrorDetails`, `FriendlyMessage`.
- In the catch block, handle both `HttpResponseException` (PS 7) and
  `WebException` (PS 5.1).
- `Write-Information` for progress, `Write-Warning` for errors.
  No `Write-Host`.

## 10. HTTP calls

- Always use `Invoke-RestMethod` with a splatted hashtable.
- Always set `ContentType = 'application/json'` when sending a body.
- Convert bodies with `ConvertTo-Json` (add `-Depth` if nested objects exist).
- Use the endpoints chosen from the spec digest; do not call endpoints that
  were not confirmed.
- Do not wrap calls inside functions.
- Never send a field marked readOnly in endpoints.md as part of a
  request body (e.g. an internal `Id` field on create).

## 11. Things to always report

End every generation with a short list of:

- Assumptions you made
- Places where the spec was ambiguous, incomplete, or contradicted the
  template
- Fields you mapped without confirmation
- What must be tested in the sandbox before merge

## 12. Known pitfalls (add to this list over time)

- `elseif ($obj)` is true for arrays of any size; check `.Count` before it.
- `-not($actionContext.DryRun -eq $true)` works, but keep the pattern
  identical across connectors so it is greppable.
- APIs often return 200 with an empty body for "not found"; check the body,
  not just the status code.
- Field names in the spec (e.g. client_id, access_token) do not always
  match the template's variable names (e.g. ClientId, token). Always
  verify against the digest, never assume the template is still correct.
- An endpoints.md auth section that only lists the security scheme
  (e.g. "Bearer, JWT") without a token endpoint, request fields, and
  response fields is incomplete and will silently produce a connector
  with no Authorization header. Always confirm the full token flow.

## 13. Action-specific rules

This file only covers what is shared across every action. Rules specific
to one action live in their own file, and must be read in addition to
this one when generating that action:

- Create: docs/conventions-create.md
- Update: docs/conventions-update.md
- Disable: docs/conventions-disable.md
- Enable: docs/conventions-enable.md
- Delete: docs/conventions-delete.md

If the matching file does not exist yet, or is still a placeholder, stop
and ask instead of inventing the missing behavior.

## 14. No placeholder implementations

- Every HTTP call described or implied by a template — including calls
  only sketched as a comment (e.g. "# Example to replace the
  placeholder code with...") — must be fully implemented with
  Invoke-RestMethod, using the confirmed endpoint and fields from
  endpoints.md.
- A comment describing what should happen is not a finished
  implementation. Hardcoded or fabricated values (e.g. New-Guid,
  literal test data, a stub object) in place of a real API call are
  never acceptable output, even as a "draft" — treat them the same as
  a missing feature and either implement the real call or stop and ask.