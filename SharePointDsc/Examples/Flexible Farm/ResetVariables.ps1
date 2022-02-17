#Requires -Version 5.1

##### SCRIPT START #####

Clear-Host
Write-Host 'Resetting variables for SharePoint deployment' -ForegroundColor Green

$global:ConfigPathFolder = $null
$global:ConfigPathFull = $null
$global:DataFile = $null

$global:credentials = $null
$global:InstallAccount = $null

$global:PassPhrase = $null
$global:CertPassword = $null

Write-Host "Completed processing!" -ForegroundColor Green
