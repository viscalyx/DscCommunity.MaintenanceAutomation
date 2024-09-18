$PSDefaultParameterValues['Install-ModuleFast:Scope'] = 'CurrentUser'
$PSDefaultParameterValues['Install-ModuleFast:NoPSModulePathUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:NoProfileUpdate'] = $true
$PSDefaultParameterValues['Install-ModuleFast:Timeout'] = 180

& ([scriptblock]::Create((Invoke-WebRequest -Uri 'bit.ly/modulefast')))

Install-ModuleFast -Path './DscCommunity.MaintenanceAutomation/requirements.psd1' -Specification 'Pester' -Verbose

func extensions install
