$PSDefaultParameterValues['Install-ModuleFast:Scope'] = 'CurrentUser'
$PSDefaultParameterValues['Install-ModuleFast:NoPSModulePathUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:NoProfileUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:Timeout'] = 180

Write-Information -MessageData "Installing ModuleFast" -InformationAction Continue

& ([scriptblock]::Create((Invoke-WebRequest -Uri 'bit.ly/modulefast')))

Write-Information -MessageData "Installing runtime dependencies" -InformationAction Continue

Install-ModuleFast -Path './requirements.psd1'

Write-Information -MessageData "Installing dev dependencies" -InformationAction Continue

Install-ModuleFast -Path './devRequirements.psd1'

Write-Information -MessageData "Installing Azure Functions extensions" -InformationAction Continue

func extensions install

Write-Information -MessageData "Listing installed dotnet SDK versions" -InformationAction Continue

dotnet --list-sdks

Write-Information -MessageData "Listing installed dotnet runtime versions" -InformationAction Continue

dotnet --list-runtimes
