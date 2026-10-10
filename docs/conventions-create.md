# Create-specific conventions

## Correlation decision
If $actionContext.CorrelationConfiguration.Enabled, validate both
AccountField and PersonFieldValue first. Throw a clear message if either
is empty.

Check for multiple matches first, then null, then single match:

if ($correlatedAccount.Count -gt 1) {
    throw "Multiple accounts found for person where $correlationField is: [$correlationValue]"
} elseif ($null -eq $correlatedAccount) {
    $action = 'CreateAccount'
} else {
    $action = 'CorrelateAccount'
}

## Output context
$outputContext.AccountCorrelated: set to $true only when correlating an
existing account, $false (or omitted) when creating a new one.