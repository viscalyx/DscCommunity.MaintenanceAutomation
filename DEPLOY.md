# Deploying Azure Function

## Steps to Deploy the Azure Function

### 1. Sign In to Azure

First, sign in to your Azure account using the Azure CLI:

```bash
az login
```

or

```bash
az login --use-device-code
```

### 2. Create a Resource Group

Choose a location and create a resource group:

```bash
az group create --name rgRelabeler --location "West Europe"
```

### 3. Create a Storage Account

Azure Functions require a storage account. Create one using the following command:

```bash
az storage account create --name saRelabeler --resource-group rgRelabeler --location "West Europe" --sku Standard_LRS
```

### 4. Create the Function App

Create the Function App where your function will reside:

```bash
az functionapp create --resource-group rgRelabeler --consumption-plan-location westeurope --runtime powershell --runtime-version 7.4 --functions-version 4 --name fRelabeler --storage-account sarelabeler
```

### **a. Create the Identity**

You can create a user-assigned managed identity using the Azure Portal, Azure CLI, or Azure PowerShell. Below are the instructions using Azure CLI and PowerShell.

```bash
az identity create --name identityRelabeler --resource-group rgRelabeler --location westeurope
```

or

```powershell
New-AzUserAssignedIdentity -Name "identityRelabeler" -ResourceGroupName "rgRelabeler" -Location "westeurope"
```

### **b. Retrieve the Identity Details**

```bash
az identity show --name identityRelabeler --resource-group rgRelabeler --query "{clientId: clientId, id: id}" --output json
```

or

```powershell
$identity = Get-AzUserAssignedIdentity -Name "identityRelabeler" -ResourceGroupName "rgRelabeler"
$identity | Select-Object ClientId, Id | ConvertTo-Json
```

### **c. Assign the Identity to the Function App**

```bash
az functionapp identity assign --name fRelabeler --resource-group rgRelabeler --identities /subscriptions/{subscription-id}/resourcegroups/rgRelabeler/providers/Microsoft.ManagedIdentity/userAssignedIdentities/identityRelabeler
```

or

```powershell
$functionApp = Get-AzFunctionApp -Name "fRelabeler" -ResourceGroupName "rgRelabeler"
$userAssignedIdentity = "identityRelabeler"

$identity = Get-AzUserAssignedIdentity -Name $userAssignedIdentity -ResourceGroupName "rgRelabeler"
Set-AzFunctionApp -Name "fRelabeler" -ResourceGroupName "rgRelabeler" -AssignIdentity @($identity.Id)
```

## **Step 3: Grant Access to Azure Key Vault**

Now, you need to grant the user-assigned managed identity access to your Azure Key Vault. This involves setting appropriate access policies.

```bash
# Assign the role
az role assignment create --role "Key Vault Secrets User" --assignee-object-id $(az identity show --name identityRelabeler --resource-group rgRelabeler --query 'principalId' -o tsv) --scope /subscriptions/{subscription-id}/resourceGroups/rgRelabeler/providers/Microsoft.KeyVault/vaults/kvRelabeler --assignee-principal-type ServicePrincipal
```

or

```powershell
# Variables
$KeyVaultName = "kvRelabeler"
$ResourceGroup = "rgRelabeler"
$RoleName = "Key Vault Secrets User"
$IdentityName = "identityRelabeler"

# Get the Key Vault
$keyVault = Get-AzKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroup

# Get the Managed Identity
$identity = Get-AzUserAssignedIdentity -Name $IdentityName -ResourceGroupName $ResourceGroup

# Assign the role
New-AzRoleAssignment -ObjectId $identity.PrincipalId -RoleDefinitionName $RoleName -Scope $keyVault.ResourceId
```

### 5. Deploy Your Function Code

Navigate to your function project directory and deploy using Azure CLI:
https://learn.microsoft.com/en-us/azure/azure-functions/functions-core-tools-reference?tabs=v2#func-azure-functionapp-publish

```bash
cd path/to/your/function/project
func azure functionapp publish fRelabeler --verbose
```

### 6. Verify the Deployment

After deployment, you can verify if your function is running correctly:

- **Azure Portal**: Navigate to your Function App in the Azure Portal to check the status and logs.

- **Testing the Function**: You can test your HTTP-triggered function using tools like `curl` or [Postman](https://www.postman.com/).

```bash
curl https://MyFunctionApp.azurewebsites.net/api/YourFunctionName?code=YOUR_FUNCTION_KEY
```

### 7. Set Up Continuous Deployment (Optional)

```bash
az functionapp deployment source config --name fRelabeler --resource-group rgRelabeler --repo-url https://github.com/yourusername/your-repo --branch main --manual-integration
```
