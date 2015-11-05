﻿param(
    [boolean]$configureWss = $false,
    [boolean]$useWss = $false,
    [boolean]$useReporting = $false,
    [boolean]$useSqlAlwaysOn = $false,
    [boolean]$IsServiceAccountBuiltIn = $false,
    [string]$sqlInstance = ${Env:\COMPUTERNAME},
    [string]$urlHostName = ${Env:\COMPUTERNAME},
	[string]$setupAccountName ="contoso\tfssetup",
	[string]$setupAccountPassword ="password#1",
    [string]$serviceAccountName = "NT Authority\Network Service",
	[string]$serviceAccountPassword= "password#1"
)

Set-Location -Path (Get-Content Env:\ProgramFiles)
Set-Location -Path "Microsoft Team Foundation Server 12.0\Tools"

$setupPassword = ConvertTo-SecureString -String $setupAccountPassword -AsPlainText -Force
$setupCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($setupAccountName,$setupPassword)

$servicePassword = ConvertTo-SecureString -String $serviceAccountPassword -AsPlainText -Force
$serviceCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($serviceAccountName,$servicePassword)

# start the configuration of the app-tier
$args = "unattend /configure /type:standard /inputs:UseWss=$useWss;UseReporting=$useReporting;ConfigureWss=$false;SqlInstance=$sqlInstance;UseSqlAlwaysOn=$useSqlAlwaysOn;IsServiceAccountBuiltIn=$isServiceAccountBuiltIn;ServiceAccountName=$serviceAccountName;ServiceAccountPassword=$($serviceCred.GetNetworkCredential().Password)"
Start-Process -FilePath ".\tfsconfig.exe" -ArgumentList $args -Credential $setupCred
#tfsconfig.exe unattend /configure /type:standard /inputs:"UseWss=$useWss;UseReporting=$useReporting;ConfigureWss=$false;SqlInstance=$sqlInstance;UseSqlAlwaysOn=$useSqlAlwaysOn;IsServiceAccountBuiltIn=$isServiceAccountBuiltIn;ServiceAccountName=$serviceAccountName" /verify
