# Team best practices (HelloID PowerShell V2)

This file holds judgement calls and team conventions that sit above
the hard rules in docs/conventions.md — things that depend on context,
involve a design decision, or call for escalating to a specific
person rather than deciding alone. Where this file and
docs/conventions.md disagree, treat it as a flag to resolve with the
team, not something to silently pick a side on.

## General

- Always build connectors to work for both cloud and on-premises
  environments, and test with both the cloud agent and the local
  agent. This has real implications for error handling (see
  docs/conventions.md §9) — pay extra attention there.
- Always surface the target web service's own error message in the
  audit log / error logging (see docs/conventions.md §8) — the
  vendor's own wording is often the only real diagnostic signal.
- Include a GET call in every lifecycle action to retrieve the most
  current state before acting (see docs/conventions.md §5, §15, §16).
- Keep field mapping as close to 1:1 with the target API as possible,
  and as dynamic as possible (see docs/conventions.md §11). If the
  mapping needs to deviate, discuss the approach with the team first.
- If a field is required by the API (e.g. for create) but isn't part
  of the standard mapping, put it in a separate object — conventionally
  named `_extension` — rather than hardcoding it.
- If the target has no GET endpoint at all, always perform an update
  rather than trying to compare against a known state.
- If there's no GET call for the user ID / external ID, consider
  whether a resource script fits better than inline logic — and
  consider whether some logic belongs in an import script instead,
  especially where reboarding is involved. Which approach makes sense
  often depends on user volume and the target API's response times —
  this is a judgement call, not a fixed rule.
- If the target API has no GET call available at all, raise this with
  the vendor — don't just work around it silently.
- Make sure the connector fits properly within HelloID's own model
  (lifecycle actions, field mapping, references) rather than working
  against it.
- For connector-specific design choices, consult Rick van den D.
- For connectors with many business rules, consult Rick van den D.
  before finalizing the design.
- Avoid using mapping files where possible.
- Perform a uniqueness check for every field that must be unique in
  the target system.
- Validate mapping files, and log invalid mappings to a separate audit
  log (see docs/conventions.md §11).
- Maintain a changelog.md documenting all changes made to the
  connector over time.
- Avoid `$value -is [PSCustomObject]` for type-checking a value such
  as a date string — it can produce unexpected results (see
  docs/conventions.md §11).
- If HelloID is the primary target/system of record, make sure every
  relevant field actually ends up in HelloID, not just in the target
  system.

## Field mapping

- Send the field mapping 1:1 to the target API, keeping it as dynamic
  as possible. If it deviates, agree the approach with the team.
- Required-but-unmapped fields (e.g. only needed for create) go into a
  separate `_extension` object.
- Source UserName / UPN / email from Microsoft AD where applicable,
  rather than re-deriving them.
- Map `lastName` using a complex mapping (not a plain 1:1 field).
- `$outputContext.Data` must never contain arrays — this is a hard
  rule, see docs/conventions.md §7.
- Fields added to the mapping during implementation should flow
  through automatically. Where that's not possible and a hardcoded
  mapping is required, document why in the connector's README.

## Create

- Always create accounts in a disabled state (hard rule — see
  docs/conventions.md §14).
- Include UserName / UPN / email from Microsoft AD.
- If a GET/lookup call can return multiple accounts (e.g. due to a
  filter-based search), handle it with an explicit `MultipleFound`
  action so it's logged clearly rather than failing generically (see
  docs/conventions.md §14).
- `$outputContext.Data` must always be a single object, never an array.
- If correlation is disabled, always create a new account.
- Remember: when `AccountCorrelated` is `$true`, HelloID does not send
  a create notification — this is expected behavior, not a bug.

## Update

- Always use the compare-account pattern within the update script (see
  docs/conventions.md §15).
- If no GET is available for this target, always perform an update
  rather than trying to compare.

## Enable / Disable

- Do not include active/date fields in the field mapping — handle them
  directly within the enable/disable action logic (see
  docs/conventions.md §16).
- Keep reconciliation behavior in mind when designing the mapping,
  since the same mapping is used there too.

## Entitlement import — accounts

- Do not use arrays in the data object.
- `UserName`: if empty, populate it with the account reference, so the
  link back to the account object is preserved.
- A snapshot can only be taken once per hour — design around this,
  don't assume more frequent snapshots are possible.
- In catch blocks, always use `Write-Error` — this makes the snapshot
  fail cleanly and allows a retry, rather than silently succeeding
  with incomplete data.
- If memory becomes an issue, set the account object to `$null` once
  its data has been written back to HelloID, to free memory.

## Permissions

- Do not add `displayName` to the permission reference.

## Grant / Revoke

- Use `$actionContext.PermissionDisplayName` in logging.
- Note: this variable is not available in preview mode — don't rely on
  it being present there.

## Entitlement import — permissions

- Always account for batching when importing permissions.
- A snapshot can only be taken once per hour (same constraint as
  accounts, above).
- In catch blocks, always use `Write-Error`, for the same retry-safety
  reason as accounts, above.
- If memory becomes an issue, set the object to `$null` once its data
  has been written back to HelloID.

## Testing

- Thoroughly test every action and process in HelloID, including the
  reboarding process specifically.
- Keep logging clear and consistent. For an update, in particular:
  - No changes occurred → log "No changes".
  - Changes occurred → make sure `$propertiesChanged` (or equivalent)
    is properly populated, not just a generic "updated" message.