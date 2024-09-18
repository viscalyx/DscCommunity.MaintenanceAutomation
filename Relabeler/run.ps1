using namespace System.Net

# Input bindings are passed in via param block.
# $Request is of type Microsoft.Azure.Functions.PowerShellWorker.HttpRequestContext:
# https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#request-object
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
# Log Information using Write-Host
Write-Host "Relabeler processing a request." # Gives INFORMATION in Azure Logs

$InstrumentationKey = $env:APPINSIGHTS_INSTRUMENTATIONKEY

if (-not $InstrumentationKey)
{
    Write-Error "Instrumentation Key is not set in Application Settings."
    Push-OutputBinding -Name Response -Value ([Microsoft.Azure.WebJobs.Extensions.Http.HttpResponseContext]@{
            Status = [HttpStatusCode]::InternalServerError
            Body   = "Configuration Error: Missing Instrumentation Key."
        })
    return
}

#Write-Information "Test Write-Information" # Same as Write-Host, gives INFORMATION in Azure Logs
#Write-Debug -Message "Test Write-Debug" -Debug # Write-Debug need to have -Debug to output, or pass Debug switch to PowerShell
#Write-Error -Message "Test Write-Error" # Gives ERROR in Azure Logs
#Write-Verbose -Message "Test Write-Verbose" -Verbose # Write-Verbose need to have -Verbose to output, or pass Verbose switch to PowerShell
# Log a Custom Metric using Write-Host (implicitly via structured logging)

Write-Host "Metric: WebhooksProcessed=1"

#RawBody
Write-Host -Object "RawBody: $($Request.RawBody | Out-String)"
#Body
Write-Debug -Message "Body: $($Request.Body | Out-String)"
#Headers
Write-Debug -Message "Headers: $($Request.Headers | Out-String)"
#Method
Write-Debug -Message "Method: $($Request.Method | Out-String)"
#Params
Write-Debug -Message "Params: $($Request.Params | Out-String)"
#Query
Write-Debug -Message "Query: $($Request.Query | Out-String)"
#Url
Write-Debug -Message "Url: $($Request.Url | Out-String)"

$eventType = $Request.Headers['x-github-event']

Write-Host -Object "x-github-event: $($eventType | Out-String)"

$payload = $null

try
{
    $payload = $Request.RawBody | ConvertFrom-Json -Depth 10
}
catch
{
    Write-Error "Error parsing JSON payload: $_"

    Push-OutputBinding -Name Response -Value ([Microsoft.Azure.WebJobs.Extensions.Http.HttpResponseContext]@{
            Status = [HttpStatusCode]::InternalServerError
            Body   = "Internal Server Error"
        })
}

if ($payload)
{
    if ($payload.action)
    {
        $eventAction = $payload.action
        $eventRepository = $payload.repository ? $payload.repository.name : $null
        $eventSender = $payload.sender ? $payload.sender.login : $null
        $eventRef = $payload.ref
        $eventRefType = $payload.ref_type
        $isPullRequest = $payload.pull_request -or $payload.issue.pull_request ? $true : $false

        # PR: https://github.com/johlju/DebugApps/pull/81
        # Get PR: https://api.github.com/repos/johlju/DebugApps/issues/81
        # Get all labels for PR: https://api.github.com/repos/johlju/DebugApps/issues/81/labels
        # Get specific labels: https://api.github.com/repos/johlju/DebugApps/issues/81/labels{/name}

        # Issue: https://github.com/johlju/DebugApps/issues/5
        # Get issue: https://api.github.com/repos/johlju/DebugApps/issues/5
        # Get all labels for issue: https://api.github.com/repos/johlju/DebugApps/issues/5/labels
        # Get specific labels: https://api.github.com/repos/johlju/DebugApps/issues/5/labels{/name}

        #$labels = $payload.issue.labels | ForEach-Object { $_.name }

        Write-Host -Object "Action: $($eventAction)"
        Write-Host -Object "Repository: $($eventRepository)"
        Write-Host -Object "Sender: $($eventSender)"
        Write-Host -Object "Ref: $($eventRef)"
        Write-Host -Object "RefType: $($eventRefType)"
        Write-Host -Object "IsPullRequest: $($isPullRequest)"

        # TODO: This need to be structured with repository, eventType, eventAction and maybe other properties.
        $metricName = '{0}.{1}' -f $eventType, $eventAction

        Send-Metric -Name $metricName -Value 1

        $logEntry = @{
            Timestamp  = (Get-Date).ToString("o")
            Level      = "Information"
            Message    = "Processed webhook successfully."
            EventType  = $eventType
            Action     = $eventAction
            Repository = $payload.repository.name
        }

        Write-Host -Object (ConvertTo-Json $logEntry)
    }

    Write-Host "Webhook processed successfully."

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    # https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#response-object
    Push-OutputBinding -Name Response -Value ([HttpResponseContext] @{
            StatusCode = [HttpStatusCode]::OK
            Body       = 'OK'
        })
}
else
{
    Write-Error "Wrong JSON payload: $($Request.RawBody | Out-String)"

    Push-OutputBinding -Name Response -Value ([Microsoft.Azure.WebJobs.Extensions.Http.HttpResponseContext] @{
            Status = [HttpStatusCode]::InternalServerError
            Body   = "Internal Server Error"
        })
}
