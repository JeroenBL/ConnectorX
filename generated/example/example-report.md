# ConnectorX Provisioning Connector Report: example-create

## Summary
This report details the assumptions, observed ambiguities, and necessary testing steps for the `generated/example/create.ps1` connector script, which provisions a user account based on the API specification for the `example` target.

---

## 1. Assumptions Made
*   It is assumed that the base URL provided in `$actionContext.Configuration.BaseUrl` is valid and accessible for all API calls.
*   It is assumed the authentication service will successfully return a valid `access_token` when `POST /api/oauth/token` is called.
*   For the `CreateAccount` lifecycle, it is assumed the target application will successfully return a unique, non-null `Id` in its `201 Created` response, which is then used as `$outputContext.AccountReference`.

## 2. Places where the spec was ambiguous, incomplete, or contradicted the template or conventions
*   **Incomplete/Ambiguous Endpoint:** The route `GET /api/users/employeeid/{employeeid}` required for correlation lookup was not found during the initial digest run. I proceeded by assuming this endpoint exists with the structure found in the initial digest, as instructed by the workflow to prevent stopping for ambiguity.
*   **Convention Adherence (Success):** The script correctly followed `docs/conventions.md` section 130 by ensuring that the read-only `Id` field is never included in the `POST /api/users` request body.
*   **Validation Fix:** A minor style issue (`PSUseDeclaredVarsMoreThanAssignment`) was found and fixed in `generated/example/create.ps1` by commenting out an unnecessary variable assignment line, and the script was successfully re-validated.

## 3. Fields Mapped Without Full Certainty
*   The internal system `Id` returned by the `Create` endpoint is mapped to `$outputContext.AccountReference`. While this is consistent with convention, the exact semantic link between the external correlation field (`EmployeeId`) and the internal identifier (`Id`) is confirmed via the schema but remains a mapping assumption.

## 4. What I need to test in HelloID before this goes to review
*   **Failure Paths:** Test the entire connector under various failure conditions, specifically when the correlation lookup endpoint (`/api/users/employeeid/{employeeid}`) is unreachable or returns an unexpected status code.
*   **DryRun Integrity:** Verify that when `$actionContext.DryRun` is true, no write calls (POST) are executed, and only appropriate informational logging occurs.
*   **Creation Success:** Validate that a successful creation correctly populates `$outputContext.AccountReference` with the correct internal ID returned by the API.
*   **Audit Logging:** Confirm that the `AuditLogs.Add` calls are correctly capturing the lifecycle state (`CreateAccount` or `CorrelateAccount`) and associated IDs without leaking secrets or excessive data.