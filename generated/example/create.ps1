#################################################
# HelloID-Conn-Prov-Example-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-ExampleError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
            Write-Warning $_.Exception.Message
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.AccountField
        $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue
        $token = $actionContext.Token # Assume token is pre-fetched in the main flow

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        # Determine if a user needs to be [created] or [correlated]
        Write-Information "Verifying if an example account exists where $correlationField is: [$correlationValue]"

        # API call to retrieve user details by EmployeeId (Correlation Lookup)
        $splatGetAccountParams = @{
            Uri     = "$($actionContext.Configuration.BaseUrl)/api/users/employeeid/$($correlationValue)"
            Method  = 'GET'
            Headers = @{ Authorization = "Bearer $($token.access_token)" }
        }

        $correlatedAccountResponse = Invoke-RestMethod @splatGetAccountParams

        # The response for this endpoint is a single object, not a collection, when found
        $correlatedAccount = @($correlatedAccountResponse)
    }

    # Check for multiple matches first, then null, then single match:
    if ($correlatedAccount.Count -gt 1) {
        throw "Multiple accounts found for person where $correlationField is: [$correlationValue]"
    } elseif ($null -eq $correlatedAccount) {
        $lifecycleProcess = 'CreateAccount'
    } else {
        $lifecycleProcess = 'CorrelateAccount'
    }

    # Process
    switch ($lifecycleProcess) {
        'CreateAccount' {
            Write-Information 'Creating and correlating example account'

            # API call to create a new user (Create Endpoint)
            $splatCreateParams = @{
                Uri    = "$($actionContext.Configuration.BaseUrl)/api/users"
                Method = 'POST'
                Headers = @{ Authorization = "Bearer $($token.access_token)" }
                ContentType = 'application/json'
                Body   = $actionContext.Data | ConvertTo-Json
            }

            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information 'Executing API call to create account'
                $createdAccount = Invoke-RestMethod @splatCreateParams

                $outputContext.Data = $createdAccount
                $outputContext.AccountReference = $createdAccount.Id
            }
            else {
                Write-Information '[DryRun] Create and correlate example account, will be executed during enforcement'
                $outputContext.Data = $actionContext.Data # Simulate data return in DryRun
                $outputContext.AccountReference = $actionContext.Data.Id # Simulate ID assignment
            }

            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }

        'CorrelateAccount' {
            Write-Information 'Correlating example account'

            # The correlated account data is already in $correlatedAccount response
            $outputContext.Data = $correlatedAccount[0] # Use the single found object
            $outputContext.AccountReference = $correlatedAccount[0].Id
            $outputContext.AccountCorrelated = $true
            $auditLogMessage = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
        Action  = $lifecycleProcess
        Message = $auditLogMessage
        IsError = $false
    })
}
catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-ExampleError -ErrorObject $ex
        $auditLogMessage = "Could not create or correlate example account: [$($actionContext.References.Account)]. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditLogMessage = "Could not create or correlate example account: [$($actionContext.References.Account)]. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
        Message = $auditLogMessage
        IsError = $true
    })
}