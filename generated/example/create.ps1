#################################################
# HelloID-Conn-Prov-example-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-exampleError {
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
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
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

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        # Determine if a user needs to be [created] or [correlated]
        Write-Information "Verifying if an example account exists where $correlationField is: [$correlationValue]"

        # Since we don't have dynamic API calls available here, this is a placeholder reflecting the structure
        $correlatedAccount = @{
            Id          = (New-Guid).Guid
            DisplayName = $actionContext.Data.DisplayName
        }
        # Example to replace the placeholder code with:
        # Retrieve user details using an API call (GET /api/users/employeeid/{employeeid}) and store the result in $correlatedAccount
        # $correlatedAccount = (Invoke-RestMethod @splatGetEmployeeIdParams)
    }

    if ($correlatedAccount.Count -eq 0) {
        $lifecycleProcess = 'CreateAccount'
    }
    elseif ($correlatedAccount.Count -eq 1) {
        $lifecycleProcess = 'CorrelateAccount'
    }
    elseif ($correlatedAccount.Count -gt 1) {
        throw "Multiple accounts found for person where $correlationField is: [$correlationValue]"
    }

    # Process
    switch ($lifecycleProcess) {
        'CreateAccount' {
            $splatCreateParams = @{
                Uri    = $actionContext.Configuration.BaseUrl
                Method = 'POST'
                Body   = $actionContext.Data | ConvertTo-Json
            }

            # Use POST /api/users
            Write-Information 'Attempting to create and correlate example account'

            if (-not($actionContext.DryRun -eq $true)) {
                try {
                    # API Call: POST /api/users
                    $createdAccount = Invoke-RestMethod @splatCreateParams

                    # Make sure to filter out arrays from $outputContext.Data (If this is not mapped to type Array in the fieldmapping). This is not supported by HelloID.
                    $outputContext.Data = $createdAccount
                    $outputContext.AccountReference = $createdAccount.Id
                }
                catch {
                    $errorObj = Resolve-exampleError -ErrorObject $_
                    $outputContext.success = $false
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Message = "Could not create example account. Error: $($errorObj.FriendlyMessage)"
                        IsError = $true
                    })
                }
            }
            else {
                Write-Information '[DryRun] Create example account, will be executed during enforcement'
                # Placeholder for DryRun output data if necessary
                $outputContext.AccountReference = "DRY_RUN_ID"
            }
            $auditLogMessage = "Create account process completed. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }

        'CorrelateAccount' {
            Write-Information 'Correlating example account'

            # Placeholder: Since actual correlation requires an API call using $correlationValue,
            # we set a placeholder result consistent with convention.
            $outputContext.Data = $correlatedAccount
            $outputContext.AccountReference = $correlatedAccount.Id
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
        $errorObj = Resolve-exampleError -ErrorObject $ex
        $auditLogMessage = "Could not process example account: [$($actionContext.References.Account)]. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditLogMessage = "Could not process example account: [$($actionContext.References.Account)]. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
        Message = $auditLogMessage
        IsError = $true
    })
}