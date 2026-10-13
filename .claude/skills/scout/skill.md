---
name: scout
description: Research a target application's API and compare its provisioning capabilities with existing HelloID connectors. Produces a feasibility report for use by gen. Never generates connector code.
argument-hint: <target-system> <connector-type: rest|scim|soap|other> [spec-or-documentation-path-or-url]
disable-model-invocation: true
---

Research the API of the target system specified by $ARGUMENTS.

Parse the arguments into a target system, a connector type (rest, scim,
soap, or other), and an optional API specification or documentation
reference.

If the target system or connector type is missing or unclear, stop and
ask — the connector type determines which examples directory is used
in Step 4, and must not be guessed or inferred silently.
If no API specification or usable documentation can be located, stop and
ask for it.

Scout is a research-only skill. Never generate, write, or modify connector
implementation code.

The goal is to produce a factual research report that `gen` can use
without repeating the initial API research.

## Step 1: Locate the API specification

Look for the specification in `specs/<target>/`.

If the user supplied a specification or documentation reference, use it
as the primary source.

Prefer machine-readable specifications when available:

* OpenAPI / Swagger JSON or YAML
* Other machine-readable API descriptions, where appropriate

If no specification exists, use available vendor documentation, including
PDFs, Word documents, and web pages.

If a document cannot be read reliably, state that limitation. Do not guess.

Do not make API calls to the target application.

While researching, if the spec or documentation suggests a different
connector type than the one given in $ARGUMENTS (e.g. the argument says
"rest" but the API is clearly SCIM-shaped), flag this mismatch
explicitly in the report rather than silently trusting either side.

## Step 2: Research API capabilities

### Machine-readable specifications

For OpenAPI / Swagger specifications, use `tools/Get-SpecDigest.ps1`.

First inspect account and business operations:

```
./tools/Get-SpecDigest.ps1 -SpecPath <spec-file> -Keyword user,account,employee,person,group,groups
```

If the result is insufficient, retry without `-Keyword`.

Investigate authentication separately:

```
./tools/Get-SpecDigest.ps1 -SpecPath <spec-file> -Keyword token,auth,oauth,login,credential
```

If necessary, retry without `-Keyword` and inspect the full digest.

Never conclude an endpoint does not exist based on a single filtered
result.

Use detailed mode with `-Route` and `-Method` to inspect relevant
operations, parameters, and request/response schemas.

### Investigate these capabilities

Identify what the available evidence establishes about:

* API type and supported account resources
* Authentication and credential acquisition
* Account listing and lookup
* Internal identifiers and potential correlation fields
* Account creation and updates
* Enable and disable operations
* Account deletion
* Required, read-only, and immutable fields
* Pagination, filtering, rate limits, and other restrictions

Do not assume every API operation maps directly to a HelloID action.

For each relevant provisioning action, distinguish between:

* **Confirmed:** the available evidence documents the required operation.
* **Potential:** the operation may be possible through a documented endpoint or field update, but needs verification.
* **Not found:** no supporting operation was found in the sources examined.
* **Unclear:** the available evidence is insufficient to determine support.

Do not treat "not found" as proof that an operation is impossible.

### SCIM

For SCIM APIs, investigate:

* `/Users` and `/Groups` support
* Filtering support and relevant RFC 7644 operators
* PATCH semantics: add, replace, and remove
* Bulk operations
* Pagination style
* Read-only and immutable attributes
* Custom schema extensions
* Authentication method
* ServiceProviderConfig and Schemas, when available in the supplied documentation

Distinguish standard SCIM behavior from vendor-confirmed behavior.

### SOAP and other API types

Investigate the equivalent capabilities for the identified API type,
including authentication, operations, request/response structures,
account identifiers, and documented limitations.

Do not force REST or SCIM assumptions onto other API types.

## Step 3: Compare against baseline expectations

Read `examples/BasicTargetReadme.md` — this describes the shape of a
"basic" target API: what we generally expect a target system to
expose (authentication, user CRUD, role/authorization handling,
schemas, and governance/reconciliation support via full-list exports)
when a connector is built against it.

If `examples/BasicTargetReadme.md` doesn't exist, state that explicitly
and skip this step — do not reconstruct baseline expectations from
memory or assume what it would have said.

If it exists, compare the target's actual capabilities (from Step 2)
against it, and classify each baseline capability as one of:

* **Present and equivalent** — the target has a directly comparable
  operation (even if the path/method/field names differ).
* **Present but different shape** — the capability exists, but works
  meaningfully differently (e.g. baseline expects a dedicated
  lookup-by-employeeId endpoint; the target only supports filtering
  on a general list endpoint instead).
* **Missing** — the baseline capability has no counterpart in the
  target at all.
* **Beyond baseline** — the target offers something not covered by
  the baseline (e.g. bulk operations, extra resource types) — note
  these too, they may be worth exploiting or may add complexity.

Cover at minimum: authentication flow, user create/read/update/delete,
the employeeId-vs-internal-ID lookup distinction, role/authorization
handling, schema completeness (required fields, data types), and
whether the target supports retrieving full lists of accounts/
permissions (needed for reconciliation/governance, per the baseline).

This comparison is meant to quickly size how close or far a target is
from what we normally build against — not to judge the target as
"wrong" for differing. Many legitimate APIs differ from the baseline
in reasonable ways; the point is to surface the differences, not rank
them.

## Step 4: Compare existing connectors

Use the connector type given in $ARGUMENTS to select the examples
directory — do not re-derive it from the spec here (any mismatch was
already flagged in Step 1):

* rest → `./examples/rest`
* scim → `./examples/scim`
* soap or other → `./examples/<type>`, if a directory for that type
  exists

If the relevant directory does not exist or is empty, report this.
Do not silently substitute another connector type's directory as an
equivalent reference — a REST example is not a stand-in for a missing
SCIM example, or vice versa.

For relevant connectors, inspect the README and implementation files
that exist, especially:

* `create.ps1`
* `update.ps1`
* `enable.ps1`
* `disable.ps1`
* `delete.ps1`

Read the actual implementation, not just its README.

Focus on:

* Authentication and token handling
* Account lookup and correlation
* API request and response handling
* Error handling, pagination, and retries
* Workarounds and known API deviations
* Patterns that may be reusable

Select the most relevant examples rather than treating every connector
as equally applicable.

Existing connectors are implementation references, not guaranteed
correct implementations.

Do not generate or modify connector code during this step.

## Step 5: Assess feasibility and implementation risks

Compare the target's documented API capabilities with the relevant
existing connector implementations, and with the baseline comparison
from Step 3.

Identify:

* Capabilities that appear straightforward to implement
* Operations requiring additional investigation
* Differences in authentication or account identification
* API limitations that may affect provisioning
* Reusable implementation patterns
* Missing conventions or templates that may need attention
* Anything flagged as "missing" or "different shape" against the
  baseline in Step 3 that meaningfully increases implementation risk

Do not prescribe a complete implementation. Identify evidence and
options so `gen` can make the implementation proposal.

Clearly distinguish documented facts, interpretations, and unknowns.

## Step 6: Write the report

Save the report to:

```
reports/<target>-feasibility.md
```

Create `reports/` if it does not exist.

Use this structure:

1. **Verdict** — Feasible / Feasible with caveats / Not feasible /
   Insufficient information. Justify the verdict briefly and state
   confidence when the evidence is incomplete or mainly prose documentation.

2. **Sources consulted** — The specification, documentation, URLs, and
   prior connector files actually inspected.

3. **API overview** — API type (and whether it matched the connector
   type given in $ARGUMENTS), resources, authentication, and relevant
   API structure.

4. **Comparison with baseline expectations** — The Step 3 findings
   against `examples/BasicTargetReadme.md`: present/equivalent,
   different shape, missing, and beyond baseline. State explicitly if
   this step was skipped because the baseline file didn't exist.

5. **Confirmed capabilities** — Findings supported by the available evidence.

6. **Provisioning capability matrix** — For each relevant action, state
   Confirmed, Potential, Not found, or Unclear. Include the relevant
   endpoint and method when known, plus evidence or limitations.

7. **Authentication and correlation** — Documented credential flow,
   request/response fields, lookup operations, and candidate identifiers.
   Explicitly mark unresolved details.

8. **Risks and limitations** — Pagination, filtering, rate limits,
   immutable fields, nonstandard behavior, and other relevant concerns.

9. **Comparison with existing connectors** — Reference concrete file paths
   (under the examples directory used in Step 4) and explain what their
   documentation or implementation demonstrates.

10. **Implementation considerations** — Relevant patterns to reuse,
    likely complications, and any genuine gaps in conventions or templates.
    Do not write connector code or treat endpoint choices as approved.

11. **Open questions** — Questions that need answers from the requester
    or vendor before implementation.

12. **Handoff for gen** — A concise summary of confirmed API facts,
    candidate endpoints, reference connectors, unresolved questions,
    and the source files that should be inspected before implementation.

Identify the evidence supporting material API findings. Paraphrase
documentation rather than reproducing substantial text verbatim.

Do not silently invent information. If evidence is insufficient, state so.

After saving the report, show its full contents to the requester.