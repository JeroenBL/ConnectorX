#################################################
# HelloID-Conn-Prov-example-Create
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
            # $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
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
    $token = $null

    # --- 1. Authentication: Retrieve Bearer Token ---
    $tokenUri = "$($actionContext.Configuration.BaseUrl)/api/oauth/token"
    $tokenParams = @{
        Uri    = $tokenUri
        Method = 'POST'
        Body   = @{
            client_id = $actionContext.Configuration.OAuthClientId
            client_secret = $actionContext.Configuration.OAuthClientSecret
        } | ConvertTo-Json
        ContentType = 'application/json'
    }

    if (-not($actionContext.DryRun -eq $true)) {
        Write-Information "Authenticating against $($actionContext.Configuration.BaseUrl)/api/oauth/token..."
        $tokenResponse = Invoke-RestMethod @tokenParams
        $token = @{
            access_token = $tokenResponse.access_token
            token_type = $tokenResponse.token_type
        }
    } else {
        Write-Information '[DryRun] Authenticating against $($actionContext.Configuration.BaseUrl)/api/oauth/token.'
    }

    if ($null -eq $token.access_token) {
        throw 'Authentication failed: No access token retrieved.'
    }

    # --- 2. Correlation lookup by EmployeeId ---
    $correlationField = $actionContext.CorrelationConfiguration.AccountField
    $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

    if ($actionContext.CorrelationConfiguration.Enabled) {
        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        $correlationUri = "$($actionContext.Configuration.BaseUrl)/api/users/employeeid/$($correlationValue)"
        $splatGetAccountParams = @{
            Uri     = $correlationUri
            Method  = 'GET'
            Headers = @{ Authorization = "$($token.token_type) $($token.access_token)" }
        }

        $correlatedAccount = @()
        if (-not($actionContext.DryRun -eq $true)) {
            Write-Information "Verifying if an example account exists where $correlationField is: [$($correlationValue)]"
            try {
                $correlatedAccount = Invoke-RestMethod @splatGetAccountParams
            } catch {
                if ($_.Exception.Response.StatusCode -eq 'NotFound') {
                    $correlatedAccount = @()
                } else {
                    throw # Re-throw other errors
                }
            }
        } else {
            Write-Information '[DryRun] Correlating account via GET /api/users/employeeid/'
        }
    }

    # --- 3. Correlation decision ---
    $lifecycleProcess = $null
    if ($correlatedAccount.Count -gt 1) {
        throw "Multiple accounts found for person where $correlationField is: [$($correlationValue)]"
    } elseif ($null -eq $correlatedAccount) {
        $lifecycleProcess = 'CreateAccount'
    } else {
        $lifecycleProcess = 'CorrelateAccount'
    }

    # --- 4. Process: Create or Correlate ---
    switch ($lifecycleProcess) {
        'CreateAccount' {
            $splatCreateParams = @{
                Uri    = "$($actionContext.Configuration.BaseUrl)/api/users"
                Method = 'POST'
                Body   = @{
                    EmployeeId = $actionContext.Data.CorrelationConfiguration.PersonFieldValue
                    FirstName  = $actionContext.Data.DisplayName.FirstName
                    LastName   = $actionContext.Data.DisplayName.LastName
                    Email      = $actionContext.Data.DisplayName.Email
                    Active     = $actionContext.Data.DisplayName.IsActive
                } | ConvertTo-Json
                ContentType = 'application/json'
                Headers = @{ Authorization = "$($token.token_type) $($token.access_token)" }
            }

            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information 'Creating and correlating example account'
                $createdAccount = Invoke-RestMethod @splatCreateParams

                $outputContext.Data = $createdAccount
                $outputContext.AccountReference = $createdAccount.Id
            } else {
                Write-Information '[DryRun] Create example account, will be executed during enforcement'
                # In DryRun, we simulate successful creation to proceed to reporting steps
                $outputContext.Data = @{ Id = New-Guid; EmployeeId = $actionContext.Data.CorrelationConfiguration.PersonFieldValue; FirstName = $actionContext.Data.DisplayName.FirstName; LastName = $actionContext.Data.DisplayName.LastName; Email = $actionContext.Data.DisplayName.Email; Active = $actionContext.Data.DisplayName.IsActive }
                $outputContext.AccountReference = (New-Guid).Guid
            }
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
        }

        'CorrelateAccount' {
            Write-Information 'Correlating example account'

            $outputContext.Data = $correlatedAccount
            $outputContext.AccountReference = $correlatedAccount.Id
            $outputContext.AccountCorrelated = $true
            $auditLogMessage = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
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
    $ex = $_
    if ($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException' -or
        $ex.Exception.GetType().FullName -eq 'System.Net.WebException') {

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