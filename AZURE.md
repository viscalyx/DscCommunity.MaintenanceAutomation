# Azure setup

## Create an Application Insights Resource

```bash
az monitor app-insights component create \
    --app <Your-App-Name> \
    --location <Your-Region> \
    --resource-group <Your-Resource-Group> \
    --kind web \
    --application-type web
```

## Configure Your Azure Function to Use Application Insights

1. **Retrieve the Instrumentation Key:**

- Navigate to your Application Insights resource in the Azure Portal.
- Copy the **Instrumentation Key** from the **Overview** section.

1. Add the Instrumentation Key to `local.settings.json`:

```json
{
    "IsEncrypted": false,
    "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "APPINSIGHTS_INSTRUMENTATIONKEY": "your_instrumentation_key_here"
    }
}
```

When you're ready to deploy your Azure Functions to a production environment, you'll need to update the `AzureWebJobsStorage` setting to point to an actual Azure Storage account. Here's how you can do it:

1. **Obtain the Connection String**:

1. Update the Instrumentation Key in Azure:

- Navigate to your Azure Storage account in the Azure Portal.
- Go to **Access keys** under the **Security + networking** section.
- Copy the **Connection string** value.

1. **Update `local.settings.json`**:

   ```json:local.settings.json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;AccountName=your_account_name;AccountKey=your_account_key;EndpointSuffix=core.windows.net",
       "FUNCTIONS_WORKER_RUNTIME_VERSION": "7.4",
       "FUNCTIONS_WORKER_RUNTIME": "powershell",
       "APPINSIGHTS_INSTRUMENTATIONKEY": "your_instrumentation_key_here"
     }
   }
   ```

1. **Deploy Your Function App**:

- Ensure that the production environment has access to the updated connection string, typically managed through environment variables or Azure App Service settings.

## Installing Azurite

Open your terminal or command prompt and run:

```bash
npm install -g azurite
azurite --version
azurite
```

or

1. **Pull the Azurite Docker Image**

```bash
docker pull mcr.microsoft.com/azure-storage/azurite
docker run -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite
docker ps
```

This command maps Azurite's ports to your local machine.
You should see the Azurite container running with the mapped ports.

## **Implementing Azure Key Vault in Your Azure Function**

Below is an example of how you can integrate Azure Key Vault into your Azure Function written in PowerShell to securely retrieve the Instrumentation Key.

Create Azure Key Vault using RBAC.

### **1. Store the Secret in Azure Key Vault**

First, store your `InstrumentationKey` in Azure Key Vault.

### **2. Grant Access to the Azure Function**

Ensure that your Azure Function has the necessary permissions to access the Key Vault. You can use **Managed Identities** for this purpose.

1. Navigate to your Azure Function in the Azure Portal.
2. Under the "Settings" section, select "Identity".
3. Enable the system-assigned managed identity.
4. Go to your Azure Key Vault.
5. Under "Access policies", add a new policy granting the Azure Function's managed identity `Get` permissions for secrets.

### **3. Modify Your PowerShell Code to Retrieve the Secret**

Update your `run.ps1` to fetch the `InstrumentationKey` from Azure Key Vault.

```powershell
# Retrieve the Instrumentation Key from Azure Key Vault
$KeyVaultName = "YourKeyVaultName"
$SecretName = "InstrumentationKey"

# Authenticate using the Managed Identity
$AccessToken = (Invoke-RestMethod -Method Post -Uri "http://169.254.169.254/metadata/identity/oauth2/token?resource=https://vault.azure.net&api-version=2019-08-01" -Headers @{Metadata="true"}).access_token

# Retrieve the secret
$SecretUri = "https://$KeyVaultName.vault.azure.net/secrets/$SecretName"
$InstrumentationKey = (Invoke-RestMethod -Method GET -Headers @{Authorization = "Bearer $AccessToken"} -Uri "$SecretUri?api-version=7.0").value
```

## KQL queries in Application Insights Logs

Use Kusto Query Language (KQL) to query different types of logs. For example:

```sql
/* View trace logs, last 5 minutes */
traces
| where timestamp >= ago(5m)
| order by timestamp desc

/* View trace logs */
traces
| where timestamp >= ago(24h)
| order by timestamp desc

/* View exceptions */
exceptions
| where timestamp >= ago(24h)
| order by timestamp desc

/* View custom metrics */
customMetrics
| where timestamp >= ago(24h)
| order by timestamp desc

/* View metrics from log messages */
traces
  | where message startswith "Metric:"
  | parse message with "Metric: " MetricName "=" MetricValue
  | summarize count() by MetricName

/* View JSON-Structured Metrics */
traces
  | where isnotempty(customDimensions)
  | extend MetricName = tostring(customDimensions.MetricName), MetricValue = toint(customDimensions.MetricValue)
  | summarize sum(MetricValue) by MetricName

/* View the custom metric "opened" */
customMetrics
| where name startswith "opened"
| project name, value, timestamp
| order by timestamp desc
```

## Random notes

```bash
az functionapp config appsettings set \
    --name <Your-Function-App-Name> \
    --resource-group <Your-Resource-Group> \
    --settings APPINSIGHTS_INSTRUMENTATIONKEY=<Your-Instrumentation-Key>
```

| Telemetry Type | Description | Consider Excluding? |
|--------------------|------------------------------------------------------|------------------------------|
| Request | Incoming HTTP requests | Yes (Critical) |
| Dependency | External service calls | Depends (Moderate) |
| Exception | Unhandled exceptions and errors | Yes (Critical) |
| Trace | Custom log messages | No (High Volume) |
| Event | Custom application events | Depends (Low to Moderate)|
| Metric | Numerical performance and health data | Depends (Moderate) |
| Availability | Application availability and responsiveness checks | Depends (Moderate) |
| PageView | User page views and interactions (Web Apps) | No (Typically Not Needed for Server Apps) |
| Custom Types | Application-specific telemetry | Depends |
By strategically configuring these settings, you optimize your monitoring strategy to capture essential insights without overwhelming your telemetry data pipeline.

```powershell
# Initialize Application Insights Telemetry
$telemetry = New-Object Microsoft.ApplicationInsights.TelemetryClient
$telemetry.InstrumentationKey = $env:APPINSIGHTS_INSTRUMENTATIONKEY

# Log a custom event
$telemetry.TrackEvent("FunctionAppStarted")
```
