# Setup

## Prerequisites

1. Install Azure Functions Core Tools

See <https://github.com/Azure/azure-functions-core-tools#installing>.

```bash
brew tap azure/functions
brew install azure-functions-core-tools@4
```

1. Install Azure Functions VS Code Extension

1. Install Azure Functions PowerShell Module

```bash
Install-Module -Name Az
```

1. Install Pester

```bash
Install-Module -Name Pester
```

1. Install Docker Desktop

See [Docker Desktop](https://www.docker.com/products/docker-desktop/).

## Configuration

Set `webHookType` to `github` in `function.json`. Don't use the `authLevel`
property with GitHub webhooks. When setting the webHookType property, don't
also set the methods property on the binding.
See [WebHook type](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2&pivots=programming-language-csharp#webhook-type)
and [GitHub Webhooks](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cisolated-process%2Cnodejs-v4%2Cfunctionsv2&pivots=programming-language-csharp#github-webhooks).

Original:

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

Modified:

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

Use [octokit/webhooks payload examples](https://github.com/octokit/webhooks/tree/main/payload-examples/api.github.com).

This need the payload be saved as a file.

```powershell
curl -X POST http://localhost:7071/api/Relabeler -H "Content-Type: application/json" -H "X-GitHub-Event: pull_request" -H "X-GitHub-Delivery: $(uuidgen)" --% -d @./tests/payloads/issue_comment.created.json

```

This need the payload be saved as a file.

```bash
curl --request POST http://localhost:7071/api/Relabeler --header "Content-Type: application/json" --header "X-GitHub-Event: pull_request" --header "X-GitHub-Delivery: 1234567890" --data @./tests/payloads/issue_comment.created.json
```

Must be run in bash or zsh, it downloads the payload content and then uses it.

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

If your Azure Function is configured to validate GitHub webhook signatures using a secret, you'll need to include the `X-Hub-Signature-256` header in your requests. Here's how to handle it:

1. **Generate a Secret**

Define a secret string that both GitHub and your Azure Function know.

```bash
SECRET=your_secret_here
```

1. **Compute the HMAC SHA-256 Signature**

Calculate the HMAC SHA-256 signature of the payload using the secret.

```bash
SIGNATURE=$(echo -n '{"action":"opened",...}' | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')
```

> **Note:** Replace `'{"action":"opened",...}'` with your actual JSON payload.

1. **Include the Signature in the Header**

Add the `X-Hub-Signature-256` header to your request.

```bash
curl -X POST http://localhost:7071/api/Relabeler \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -H "X-GitHub-Delivery: 1234567890" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d @pull_request_opened.json
```

* Set `githubToken` in `local.settings.json` to a GitHub personal access token with the `repo` scope.
* Set `githubToken` in `local.settings.json` to a GitHub personal access token with the `repo` scope.

See <https://github.com/settings/tokens>.

* Set `githubToken` in `local.settings.json` to a GitHub personal access token with the `repo` scope.

## Additional Tips

### Use Ngrok for External Testing

If you need to test webhooks from GitHub directly to your local machine without deploying, consider using [Ngrok](https://ngrok.com/) to create a secure tunnel. This command will provide a public URL that forwards requests to your local Azure Function.

```bash
ngrok http 7071
```

## TODO

Send Test Payloads: Use GitHub's "Test webhook" feature to send sample payloads and ensure your function processes them correctly.
Monitor Logs: Utilize Azure's monitoring tools to check the logs for any discrepancies or errors during the webhook handling.
logging behaviors of the function app, including Application Insights.
