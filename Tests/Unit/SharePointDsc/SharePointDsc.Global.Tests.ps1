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

            ## For Appveyor builds copy the module to the system modules directory so it falls 
            ## in to a PSModulePath folder and is picked up correctly. 
            if ($env:APPVEYOR -eq $true) 
            {
                Copy-item -Path "$env:APPVEYOR_BUILD_FOLDER\Modules\SharePointDsc" `
                          -Destination 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\SharePointDsc' `
                          -Recurse
            }

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
            
            Get-ChildItem -Path "$RepoRoot\Modules\SharePointDsc\Examples" -Filter "*.ps1" -Recurse | ForEach-Object -Process {
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

            if ($env:APPVEYOR -eq $true) 
            {
                Remove-item -Path 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\SharePointDsc' `
                            -Recurse -Force -Confirm:$false
                # Restore the load of the module to ensure future tests have access to it
                Import-Module -Name "$RepoRoot\modules\SharePointDsc\SharePointDsc.psd1" -Global -Force
            }    
        }

        It "Should not have errors in any markdown files" {
            $runGulp = $false
            try {
                Start-Process -FilePath "npm" -ArgumentList "install" -WorkingDirectory $RepoRoot -Wait -PassThru -NoNewWindow
                $runGulp = $true
            }
            catch [System.Exception] {
                Write-Warning -Message ("Unable to run npm to install dependencies needed to " + `
                                        "test markdown files. Please be sure that you have " + `
                                        "installed nodejs.")
            }
            
            if ($runGulp -eq $true)
            {
                $mdErrors = 0
                try {
                    Start-Process -FilePath "gulp" -ArgumentList "test-mdsyntax --silent" -Wait -WorkingDirectory $RepoRoot -PassThru -NoNewWindow
                    Start-Sleep -Seconds 3
                    $mdIssuesPath = Join-Path -Path $RepoRoot -ChildPath "markdownissues.txt"
                    
                    if ((Test-Path -Path $mdIssuesPath) -eq $true)
                    {
                        Get-Content -Path $mdIssuesPath | ForEach-Object -Process {
                            if ([string]::IsNullOrEmpty($_) -eq $false)
                            {
                                Write-Warning -Message $_
                                $mdErrors ++
                            }
                        }
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message ("Unable to run gulp to test markdown files. Please " + `
                                            "be sure that you have installed nodejs and have " + `
                                            "run 'npm install -g gulp' in order to have this " + `
                                            "text execute.")
                }
                Remove-Item -Path $mdIssuesPath -Force -ErrorAction SilentlyContinue
                $mdErrors | Should Be 0
            }
        }
    }
}
