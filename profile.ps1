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
        [Parameter(Mandatory = $true)]
        [string]$name, # The name of the custom metric.

        [Parameter(Mandatory = $true)]
        [int]$value, # The numerical value of the metric.

        [int]$count = 1, # The number of times the metric was sampled.

        [Int16]$min = 0, # The minimum value of the metric.

        [int]$max = $value, # The maximum value of the metric.

        [int]$stdDev = 0, # The standard deviation of the metric.

        [int]$sum = $value
    )

    # TODO: Make this configurable via an environment variable
    # Application Insights Configuration
    $IngestionEndpoint = "https://dc.services.visualstudio.com/v2/track"

    $body = @{
        name = "Microsoft.ApplicationInsights.$name"
        time = (Get-Date).ToUniversalTime().ToString("o")
        iKey = $InstrumentationKey
        data = @{
            baseType = "MetricData"
            baseData = @{
                metrics = @(
                    @{
                        name   = $name
                        value  = $value
                        count  = $count
                        min    = $min
                        max    = $max
                        stdDev = $stdDev
                        sum    = $sum
                    }
                )
            }
        }
    } | ConvertTo-Json -Depth 5

    try
    {
        Invoke-RestMethod -Method Post -ContentType "application/json" -Body $body -Uri $IngestionEndpoint

        # $metricLog = @{
        #     name  = "CustomMetric"
        #     value = 5
        #     tags  = @{
        #         Environment = "Production"
        #         FunctionName = "ProcessWebhook"
        #     }
        # }
        # Write-Host (ConvertTo-Json $metricLog)

        Write-Host "Metric '$name' sent successfully with value $value."
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

        return $content | ConvertFrom-Yaml
    }
    catch
    {
        Write-Error "Failed to fetch configuration: $_"

        return $null
    }
}
