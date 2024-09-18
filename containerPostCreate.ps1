$PSDefaultParameterValues['Install-ModuleFast:Scope'] = 'CurrentUser'
$PSDefaultParameterValues['Install-ModuleFast:NoPSModulePathUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:NoProfileUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:Timeout'] = 180

Write-Information -MessageData "Installing ModuleFast" -InformationAction Continue

& ([scriptblock]::Create((Invoke-WebRequest -Uri 'bit.ly/modulefast')))

Write-Information -MessageData "Installing runtime dependencies" -InformationAction Continue

Install-ModuleFast -Path './DscCommunity.MaintenanceAutomation/requirements.psd1' -Verbose

Write-Information -MessageData "Installing dev dependencies" -InformationAction Continue

Install-ModuleFast -Path './devRequirements.psd1' -Verbose

Write-Information -MessageData "Installing Azure Functions extensions" -InformationAction Continue

func extensions install
