[CmdletBinding()]
# Ignoring this because we need to generate a stub credential to return up the current crawl account as a PSCredential
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Describe 'SharePointDsc whole of module tests' {

    Context -Name "Validate example files" {
        
        It "Should compile MOFs for all examples correctly" {
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
                        Example @params -OutputPath "TestDrive:\" -ConfigurationData $configData -ErrorAction Continue -WarningAction SilentlyContinue | Out-Null
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
