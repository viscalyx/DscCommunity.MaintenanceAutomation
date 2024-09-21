# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
# Remove this if you are not planning on using MSI or Azure PowerShell.
# if ($env:MSI_SECRET) {
#     Disable-AzContextAutosave -Scope Process | Out-Null
#     Connect-AzAccount -Identity
# }

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.

Write-Host "Loading StackExchange.Redis assembly"

# Load the StackExchange.Redis assembly
Add-Type -Path (Join-Path $PSScriptRoot './Relabeler/bin/netstandard2.0/StackExchange.Redis.dll')

# Import necessary modules
Import-Module Az.ApplicationInsights

# Import the YAML module if the RELABELER_CONFIG_PATH environment variable is not set
if ([System.String]::IsNullOrEmpty($env:RELABELER_CONFIG_PATH))
{
    # Import the YAML module
    Import-Module powershell-yaml
}

if ([System.String]::IsNullOrEmpty($env:APPINSIGHTS_INSTRUMENTATIONKEY))
{
    <#
        When developing and testing Azure Functions locally, accessing Azure services that rely
        on Managed Identities such as Azure Key Vault—can pose challenging. This is because
        the **Managed Identity endpoint (`http://169.254.169.254`)** is **only available within
        the Azure environment**. Consequently, your PowerShell script cannot access this endpoint
        when running on your local machine, resulting in authentication failures.
    #>
    $KeyVaultName = "kvRelabeler"
    $SecretName = "InstrumentationKey"

    # User-Assigned Managed Identity Client ID
    $UserAssignedIdentityClientId = $env:IDENTITY_CLIENT_ID

    # Azure Environment and Resource for Key Vault
    $VaultResource = "https://vault.azure.net"

    # Obtain an Access Token using the User-Assigned Managed Identity
    $AccessTokenResponse = Invoke-RestMethod -Method Post -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2019-08-01&resource=$VaultResource&client_id=$UserAssignedIdentityClientId" -Headers @{Metadata = "true" }

    $AccessToken = $AccessTokenResponse.access_token

    $SecretUri = "https://$KeyVaultName.vault.azure.net/secrets/$SecretName?api-version=7.0"

    # Retrieve the Instrumentation Key from Azure Key Vault
    $InstrumentationKey = (Invoke-RestMethod -Method GET -Headers @{Authorization = "Bearer $AccessToken" } -Uri $SecretUri).value

    $env:APPINSIGHTS_INSTRUMENTATIONKEY = $InstrumentationKey
}

function Send-Metric
{
    param (
        [Parameter()]
        [string]$BaseName = 'RepositoryEvent', # The base name of the custom metric, e.g., "RepositoryEvent"

        [Parameter(Mandatory = $true)]
        [int]$value, # The numerical value of the metric.

        [int]$count = 1, # The number of times the metric was sampled.

        [Int16]$min = 0, # The minimum value of the metric.

        [int]$max = $value, # The maximum value of the metric.

        [int]$stdDev = 0, # The standard deviation of the metric.

        [int]$sum = $value,

        [Parameter(Mandatory = $true)]
        [string]$organization, # The name of the organization the repository belongs to

        [Parameter(Mandatory = $true)]
        [string]$repository, # The name of the repository

        [Parameter(Mandatory = $true)]
        [string]$resource, # The resource type (e.g., 'Pull Request', 'Issue')

        [Parameter(Mandatory = $true)]
        [string]$eventType, # The event type (e.g., 'issue_comment')

        [Parameter(Mandatory = $true)]
        [string]$eventAction # The event action (e.g., 'opened')
    )

    # TODO: Make this configurable via an environment variable
    # Application Insights Configuration
    $IngestionEndpoint = "https://dc.services.visualstudio.com/v2/track"

    # Validate Repository parameter
    if (-not $repository)
    {
        Write-Error "Repository parameter is mandatory. Please provide a valid repository name."
        return
    }

    # Validate Resource parameter
    if (-not $resource)
    {
        Write-Error "Resource parameter is mandatory. Please provide a valid resource type (e.g., 'Pull Request', 'Issue')."
        return
    }

    # Validate Organization parameter
    if (-not $organization)
    {
        Write-Error "Organization parameter is mandatory. Please provide a valid organization name."
        return
    }

    # Validate EventType parameter
    if (-not $eventType)
    {
        Write-Error "EventType parameter is mandatory. Please provide a valid event type (e.g., 'issue_comment')."
        return
    }

    # Validate EventAction parameter
    if (-not $eventAction)
    {
        Write-Error "EventAction parameter is mandatory. Please provide a valid event action (e.g., 'opened')."
        return
    }


    $body = @{
        name = "Microsoft.ApplicationInsights.$BaseName"  # e.g., "Microsoft.ApplicationInsights.RepositoryEvent"
        time = (Get-Date).ToUniversalTime().ToString("o")
        iKey = $InstrumentationKey
        data = @{
            baseType = "MetricData"
            baseData = @{
                metrics = @(
                    @{
                        name       = $BaseName
                        value      = $value
                        count      = $count
                        min        = $min
                        max        = $max
                        stdDev     = $stdDev
                        sum        = $sum
                        dimensions = @(
                            @{
                                name  = "Organization"
                                value = $organization
                            },
                            @{
                                name  = "Repository"
                                value = $repository
                            },
                            @{
                                name  = "Resource"
                                value = $resource
                            },
                            @{
                                name  = "EventType"
                                value = $eventType
                            },
                            @{
                                name  = "EventAction"
                                value = $eventAction
                            }
                        )
                    }
                )
            }
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try
    {
        $null = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $body -Uri $IngestionEndpoint

        Write-Host "Metric '$BaseName' sent successfully with value $value. Dimensions - Repository: '$repository', Resource: '$resource', EventType: '$eventType', EventAction: '$eventAction'."
    }
    catch
    {
        Write-Error "Failed to send metric '$name': $_"
    }
}

function Get-RepoConfig
{
    param
    (
        [string]$ApiUrl,
        [string]$GithubToken
    )

    try
    {
        # This is to allow for local debugging with a local config file
        if ([System.String]::IsNullOrEmpty($env:RELABELER_CONFIG_PATH))
        {
            $headers = @{
                "Authorization" = "token $GithubToken"
                "User-Agent"    = "AzureFunction-Relabeler"
            }

            $configPath = ".github/relabeler-config.yml"
            $configApiUrl = "$apiUrl/contents/$configPath"

            Write-Information "Retrieving configuration from $configApiUrl." -InformationAction 'Continue'

            $response = Invoke-RestMethod -Uri $configApiUrl -Headers $headers -Method Get -ErrorAction 'Stop'

            # Decode the base64 content
            $decodedBytes = [System.Convert]::FromBase64String($response.content)

            # Convert bytes to UTF8 string
            $content = [System.Text.Encoding]::UTF8.GetString($decodedBytes)

        }
        else
        {
            Write-Information "Using local config file: $env:RELABELER_CONFIG_PATH" -InformationAction 'Continue'

            $content = Get-Content -Raw -Path $env:RELABELER_CONFIG_PATH
        }

        # Convert YAML to Hashtable, Hashtable to JSON and then JSON to a PowerShell object
        return [PSCustomObject] ($content | ConvertFrom-Yaml) #| ConvertTo-Json -Depth 10 -Compress | ConvertFrom-Json
    }
    catch
    {
        Write-Error "Failed to fetch configuration: $_"

        return $null
    }
}
