[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
Import-Module "$PSScriptRoot\xSharePoint.TestHelpers.psm1"

Describe 'xSharePoint whole of module tests' {

    $mofFiles = @(Get-ChildItem $RepoRoot -Recurse -Filter "*.schema.mof" -File | ? {
        ($_.FullName -like "*\DscResources\*")
    })
    
    Context "Validate the MOF schemas for the DSC resources" {

        It "should not list InstallAccount as required if it does have that attribute" {
            $mofFilesWithRequiredInstallAccount = 0
            $mofFiles | ForEach-Object {
                $mofSchemas = Get-MofSchemaObject $_.FullName
                foreach($mofSchema in $mofSchemas) {
                    $installAccount = $mofSchema.Attributes | Where-Object { $_.Name -eq "InstallAccount" }
                    if (($null -ne $installAccount) -and ($installAccount.State -eq "Required")) {
                        $mofFilesWithRequiredInstallAccount += 1
                        Write-Warning "File $($_.FullName) has InstallAccount listed as a required parameter. After v0.6 of xSharePoint this should be changed to 'write' instead of 'required'"
                    }
                }
            }
            $mofFilesWithRequiredInstallAccount | Should Be 0
        }
        
        It "should not list Ensure as required if it does have that attribute" {
            $mofFilesWithRequiredEnsure = 0
            $mofFiles | ForEach-Object {
                $mofSchemas = Get-MofSchemaObject $_.FullName
                foreach($mofSchema in $mofSchemas) {
                    $installAccount = $mofSchema.Attributes | Where-Object { $_.Name -eq "Ensure" }
                    if (($null -ne $installAccount) -and ($installAccount.State -eq "Required")) {
                        $mofFilesWithRequiredEnsure += 1
                        Write-Warning "File $($_.FullName) has Ensure listed as a required parameter. This should be 'write' and a default of 'present' should exist within the modules logic"
                    }
                }
            }
            $mofFilesWithRequiredEnsure | Should Be 0
        }

        It "uses MOF schemas that match the functions used in the corresponding PowerShell module for each resource" {
            $filesWithErrors = 0
            $WarningPreference = "Continue"
            $mofFiles | % {
                if ((Assert-MofSchemaScriptParameters $_.FullName) -eq $false) { $filesWithErrors++ }
            }
            $filesWithErrors | Should Be 0
        }
    }
}
