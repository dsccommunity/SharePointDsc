[CmdletBinding()]
# Ignoring this because we need to generate a stub credential to return up the current crawl account as a PSCredential
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
Import-Module "$RepoRoot\DscResource.DocumentationHelper"

Describe 'SharePointDsc whole of module tests' {

    $mofFiles = @(Get-ChildItem $RepoRoot -Recurse -Filter "*.schema.mof" -File | Where-Object -FilterScript {
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
                        Write-Warning "File $($_.FullName) has InstallAccount listed as a required parameter. After v0.6 of SharePointDsc this should be changed to 'write' instead of 'required'"
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
    }

    Context "Validate example files" {
        
        It "should compile MOFs for all examples correctly" {
            $examplesWithErrors = 0
            $dummyPassword = ConvertTo-SecureString "-" -AsPlainText -Force
            $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @("username", $dummyPassword)
            $configData = @{
                AllNodes = @(
                    @{
                        NodeName = "localhost"
                        PSDscAllowPlainTextPassword = $true
                    },
                    @{
                        NodeName = "Server1"
                        PSDscAllowPlainTextPassword = $true
                    },
                    @{
                        NodeName = "Server2"
                        PSDscAllowPlainTextPassword = $true
                    }
                )
            }
            
            Get-ChildItem "$RepoRoot\Modules\SharePointDsc\Examples" -Filter "*.ps1" -Recurse | ForEach-Object -Process {
                    $path = $_.FullName
                    try
                    {
                        . $path
 
                        $command = Get-Command Example
                        $params = @{}
                        $command.Parameters.Keys | Where-Object { $_ -like "*Account" -or $_ -eq "Passphrase" } | ForEach-Object -Process {
                            $params.Add($_, $mockCredential)
                        }
                        Example -InstanceName localhost @params -OutputPath "TestDrive:\" -ConfigurationData $configData -ErrorAction Continue -WarningAction SilentlyContinue | Out-Null
                    }
                    catch
                    {
                        $examplesWithErrors ++
                        Write-Warning -Message "Unable to compile MOF for example '$path'"
                        Write-Warning $_.Exception.Message
                    }
                } 
            $examplesWithErrors | Should Be 0    
        }
    }
}
