# Setup

## Prerequisites

1. **Install Azure Functions Core Tools**

   See [Installing Azure Functions Core Tools](https://github.com/Azure/azure-functions-core-tools#installing).

   ```bash
   brew tap azure/functions
   brew install azure-functions-core-tools@4
   ```

2. **Install Azure Functions VS Code Extension**

   This extension is required locally even when developing in the dev container.

3. **Install Azure Functions PowerShell Module**

   ```bash
   Install-Module -Name Az
   ```

4. **Install Pester**

   ```bash
   Install-Module -Name Pester
   ```

5. **Install Docker Desktop**

   See [Docker Desktop](https://www.docker.com/products/docker-desktop/).

## Local Development

Follow these steps to set up and develop the project locally without using a development container.

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourusername/DscCommunity.MaintenanceAutomation.git
   cd DscCommunity.MaintenanceAutomation
   ```

2. **Configure Local Settings**

   Copy the template settings file and update the necessary values.

   ```bash
   cp local.settings.template.json local.settings.json
   ```

   Update `local.settings.json` with your configurations, such as `GITHUB_TOKEN` and `RELABELER_CONFIG_PATH`.

3. **Install Dependencies**

   Install the required PowerShell modules.

   ```powershell
   Install-Module -Name Az.Accounts -RequiredVersion 3.0.4
   Install-Module -Name Az.ApplicationInsights -RequiredVersion 2.2.5
   Install-Module -Name powershell-yaml -RequiredVersion 0.4.4
   ```

4. **Run the Azure Function Locally**

   Start the Azure Functions host.

   ```bash
   func host start
   ```

5. **Test the Function**

   Use `curl` or Postman to send requests to `http://localhost:7071/api/Relabeler`.

## Developing inside a container

For an isolated and consistent development environment, use the provided development container.

1. **Prerequisites**

   - **Visual Studio Code** with the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed.

2. **Open the Project in the Dev Container**

   - Open Visual Studio Code.
   - Click on the green _><_ icon in the bottom-left corner.
   - Select **"Reopen in Container"**.

3. **Configure Environment Variables**

   Ensure that `.devcontainer/devcontainer.env` is properly set up with necessary environment variables.

4. **Build the Dev Container**

   The container will automatically build based on the provided `Dockerfile` and `devcontainer.json`. If you need to rebuild manually:

   - Open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
   - Select **"Dev Containers: Rebuild Container"** or **"Dev Containers: Rebuild Container Without Cache"**.

5. **Run Post-Creation Scripts**

   The `postCreateCommand` in `devcontainer.json` will execute `containerPostCreate.ps1` to install dependencies.

6. **Start the Azure Function (without debugging)**

   Use the integrated terminal to start the Azure Functions host.

   ```bash
   func host start
   ```

7. **Start the Azure Function with Debugging**

   - Press `F5` to start debugging.

   If you get the error `Could not find the task 'func: host start'` see the issue [Fails debugging Azure Function inside a .devcontainer using VS Code](https://github.com/microsoft/vscode-azurefunctions/issues/4290#issuecomment-2365056629).

## Configuration

Set `webHookType` to `github` in `function.json`. Avoid using the `authLevel` property with GitHub webhooks. When setting the `webHookType` property, do not set the `methods` property on the binding.

See [WebHook type](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2&pivots=programming-language-csharp#webhook-type) and [GitHub Webhooks](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2&pivots=programming-language-csharp#github-webhooks).

### Original `function.json`

```json
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "Request",
      "methods": [
        "get",
        "post"
      ]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "Response"
    }
  ]
}
```

### Modified `function.json`

```json
{
  "bindings": [
    {
      "webHookType": "github",
      "type": "httpTrigger",
      "direction": "in",
      "name": "Request"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "Response"
    }
  ]
}
```

## Testing

Use [octokit/webhooks payload examples](https://github.com/octokit/webhooks/tree/main/payload-examples/api.github.com) to test your Azure Function.

### Using PowerShell

Ensure the payload is saved as a file, then run:

```powershell
curl -X POST http://localhost:7071/api/Relabeler `
     -H "Content-Type: application/json" `
     -H "X-GitHub-Event: pull_request" `
     -H "X-GitHub-Delivery: $(uuidgen)" `
     --% -d @./tests/payloads/issue_comment.created.json
```

### Using Bash

Ensure the payload is saved as a file, then run:

```bash
curl --request POST http://localhost:7071/api/Relabeler \
     --header "Content-Type: application/json" \
     --header "X-GitHub-Event: pull_request" \
     --header "X-GitHub-Delivery: 1234567890" \
     --data @./tests/payloads/issue_comment.created.json
```

### Downloading and Using Payload Content

Must be run in `bash` or `zsh` as it downloads the payload content and then uses it.

```bash
curl -X POST -H "Content-Type: application/json" \
     --data-binary @<(curl -s 'https://raw.githubusercontent.com/octokit/webhooks/main/payload-examples/api.github.com/pull_request/opened.payload.json') \
     http://localhost:7071/api/Relabeler
```

## Random

Randomly generate a secret token and set `secretToken` in `function.json` to the value of `GITHUB_WEBHOOK_SECRET` in `local.settings.json`.

```bash
openssl rand -base64 24
```

## Secret

If your Azure Function is configured to validate GitHub webhook signatures using a secret, include the `X-Hub-Signature-256` header in your requests.

### 1. Generate a Secret

Define a secret string that both GitHub and your Azure Function know.

```bash
SECRET=your_secret_here
```

### 2. Compute the HMAC SHA-256 Signature

Calculate the HMAC SHA-256 signature of the payload using the secret.

```bash
SIGNATURE=$(echo -n '{"action":"opened",...}' | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')
```

> **Note:** Replace `'{"action":"opened",...}'` with your actual JSON payload.

### 3. Include the Signature in the Header

Add the `X-Hub-Signature-256` header to your request.

```bash
curl -X POST http://localhost:7071/api/Relabeler \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-GitHub-Delivery: 1234567890" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d @pull_request_opened.json
```

- Set `githubToken` in `local.settings.json` to a GitHub personal access token with the `repo` scope.
- See [GitHub Tokens](https://github.com/settings/tokens).

## Additional Tips

### Use Ngrok for External Testing

To test webhooks from GitHub directly to your local machine without deploying, use [Ngrok](https://ngrok.com/) to create a secure tunnel.

```bash
ngrok http 7071
```

### TODO

- **Send Test Payloads:** Use GitHub's "Test webhook" feature to send sample payloads and ensure your function processes them correctly.
- **Monitor Logs:** Utilize Azure's monitoring tools, including Application Insights, to check the logs for any discrepancies or errors during webhook handling.
