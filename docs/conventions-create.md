# Create-specific conventions

## Correlation lookup — must be a real API call

Before evaluating the decision logic below, you MUST perform the actual
GET call to the correlation-lookup endpoint confirmed in endpoints.md
(e.g. GET /api/users/employeeid/{employeeid}), using Invoke-RestMethod
with the Authorization header set from the auth step (see
docs/conventions.md section 4).

```powershell
$splatGetAccountParams = @{
    Uri     = "$($actionContext.Configuration.BaseUrl)/api/users/employeeid/$correlationValue"
    Method  = 'GET'
    Headers = @{ Authorization = "Bearer $($token.access_token)" }
}
try {
    $correlatedAccount = Invoke-RestMethod @splatGetAccountParams
} catch {
    if ($_.Exception.Response.StatusCode -eq 'NotFound') {
        $correlatedAccount = $null
    } else {
        throw
    }
}
```

(Adjust the URI, field name, and response handling to match what is
actually confirmed in endpoints.md — the example above shows the shape
of what is required, not literal values to copy unchanged.)

Template comments such as "# Example to replace the placeholder code
with..." are instructions to implement, not acceptable final content.
Leaving a hardcoded value (e.g. New-Guid, a literal test object) in
place of this call is a failure to follow conventions, not an
acceptable draft — see docs/conventions.md section 14.

## Correlation decision

If $actionContext.CorrelationConfiguration.Enabled, validate both
AccountField and PersonFieldValue first. Throw a clear message if either
is empty.

Check for multiple matches first, then null, then single match:

```powershell
if ($correlatedAccount.Count -gt 1) {
    throw "Multiple accounts found for person where $correlationField is: [$correlationValue]"
} elseif ($null -eq $correlatedAccount) {
    $action = 'CreateAccount'
} else {
    $action = 'CorrelateAccount'
}
```

## Output context

$outputContext.AccountCorrelated: set to $true only when correlating an
existing account, $false (or omitted) when creating a new one.