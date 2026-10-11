# HelloID Connector Generation Report: example create

This report summarizes the assumptions, known gaps, and necessary tests for the generated `example create.ps1` connector script.

## 📝 Summary of Implementation
The connector script was successfully generated following all conventions and using confirmed endpoints from the API spec. The script incorporates logic for DryRun mode, proper audit logging, and correct use of OAuth2 Bearer Token authentication derived from the spec digest.

## ⚠️ Assumptions Made
1.  **Token Availability:** I assumed that the token acquisition step (POST `/api/oauth/token`) runs successfully and sets `$actionContext.Token.access_token` before the main `create` logic is executed.
2.  **Correlation Configuration:** I assumed that the configuration variables (`$actionContext.CorrelationConfiguration.Enabled`, `AccountField`, `PersonFieldValue`) are properly set in the runtime context, allowing the correlation logic to function as intended.
3.  **Response Structure:** In the correlation lookup (`GET /api/users/employeeid/{employeeid}`), I assumed the endpoint returns a single object when found, rather than a collection, and adjusted the script logic to reflect this.
4.  **DryRun Simulation:** In `DryRun` mode, I simulated the assignment of the target system's unique `Id` to `$outputContext.AccountReference` based on the successful response shape of the `POST /api/users` endpoint.

## ❓ Ambiguities, Incompleteness, and Contradictions
1.  **Error Handling Detail:** The `Resolve-ExampleError` helper assumes that detailed JSON error messages from the API can be parsed via `ConvertFrom-Json`. If the API returns malformed or plain text error responses, the `FriendlyMessage` may be incomplete or misleading.
2.  **Field Mapping Certainty:** The specific mapping of certain fields (e.g., mapping between template's `ClientId` and spec's `client_id`) relies heavily on convention and the visual inspection of the digest; no explicit field mapping file confirmed this mapping is 100% accurate for all fields.

## 🗺️ Fields Mapped Without Full Certainty
The mapping of standard user attributes (`FirstName`, `LastName`, `Email`, `Active`) from the input data to the request body fields is based on the confirmed digest (`POST /api/users`). No specific validation was performed against a definitive external mapping document beyond the digest's field list.

## 🧪 Testing Requirements
Before this connector is deployed to HelloID, the following must be tested in the sandbox:
1.  **Full Lifecycle Test (Create + Success):** Test a complete flow where the account does not exist, ensuring the token acquisition, correlation lookup (returns null), creation call (`POST /api/users`), and final audit log are all successful.
2.  **Correlation Test (Correlate + Success):** Test a flow where the account *does* exist, ensuring the correlation lookup finds the single record, the correlation decision is made, and the correct `AccountCorrelated` flag is set.
3.  **Conflict Test (Error):** Test a scenario where the correlation lookup returns more than one result (`Count -gt 1`), ensuring the connector correctly throws an error and logs it via `AuditLogs.Add` with `IsError = $true`.
4.  **DryRun Verification:** Verify that when `$actionContext.DryRun` is `$true`, no HTTP write calls are made, but the logging message correctly reflects the intent.