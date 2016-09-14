[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPUsageApplication"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPUsageApplication - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Usage Service App"
            UsageLogCutTime = 60
            UsageLogLocation = "L:\UsageLogs"
            UsageLogMaxFileSizeKB = 1024
            UsageLogMaxSpaceGB = 10
            DatabaseName = "SP_Usage"
            DatabaseServer = "sql.test.domain"
            FailoverDatabaseServer = "anothersql.test.domain"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock -CommandName New-SPUsageApplication { }
        Mock -CommandName Set-SPUsageService { }
        Mock -CommandName Get-SPUsageService { return @{
            UsageLogCutTime = $testParams.UsageLogCutTime
            UsageLogDir = $testParams.UsageLogLocation
            UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
            UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
        }}
        Mock -CommandName Remove-SPServiceApplication
        Mock -CommandName Get-SPServiceApplicationProxy {
            return (New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod Provision {} -PassThru | Add-Member -NotePropertyName Status -NotePropertyValue "Online" -PassThru  | Add-Member -NotePropertyName TypeName -NotePropertyValue "Usage and Health Data Collection Proxy" -PassThru)
        }

        Context -Name "When no service applications exist in the current farm" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }

            It "Should return null from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPUsageApplication
            }

            It "Should create a new service application with custom database credentials" {
                $testParams.Add("DatabaseCredentials", (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))))
                Set-TargetResource @testParams
                Assert-MockCalled New-SPUsageApplication
            }
        }

        Context -Name "When service applications exist in the current farm but not the specific usage service app" {

            Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{
                TypeName = "Some other service app type"
            }) }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"  
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When a service application exists and is configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"  
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When a service application exists and log path are not configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock -CommandName Get-SPUsageService { return @{
                UsageLogCutTime = $testParams.UsageLogCutTime
                UsageLogDir = "C:\Wrong\Location"
                UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
                UsageLogMaxSpaceGB = $testParams.UsageLogMaxSpaceGB
            }}

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPUsageService
            }
        }

        Context -Name "When a service application exists and log size is not configured correctly" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = $testParams.DatabaseName
                        Server = @{ Name = $testParams.DatabaseServer }
                    }
                })
            }
            Mock -CommandName Get-SPUsageService { return @{
                UsageLogCutTime = $testParams.UsageLogCutTime
                UsageLogDir = $testParams.UsageLogLocation
                UsageLogMaxFileSize = ($testParams.UsageLogMaxFileSizeKB * 1024)
                UsageLogMaxSpaceGB = 1
            }}

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the update service app cmdlet from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Set-SPUsageService
            }
        }
        
        $testParams = @{
            Name = "Test App"
            Ensure = "Absent"
        }
        
        Context -Name "When the service app exists but it shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = "db"
                        Server = @{ Name = "server" }
                    }
                })
            }
            
            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should remove the service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
            }
        }
        
        Context -Name "When the service app doesn't exist and shouldn't" {
            Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        $testParams = @{
            Name = "Test App"
            Ensure = "Present"
        }
        
        Context -Name "The proxy for the service app is offline when it should be running" {
            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Usage and Health Data Collection Service Application"
                    DisplayName = $testParams.Name
                    UsageDatabase = @{
                        Name = "db"
                        Server = @{ Name = "server" }
                    }
                })
            }
            Mock -CommandName Get-SPServiceApplicationProxy {
                return (New-Object -TypeName "Object" | Add-Member -MemberType ScriptMethod Provision {$Global:SPDscUSageAppProxyStarted = $true} -PassThru | Add-Member -NotePropertyName Status -NotePropertyValue "Disabled" -PassThru | Add-Member -NotePropertyName TypeName -NotePropertyValue "Usage and Health Data Collection Proxy" -PassThru)
            }    
            $Global:SPDscUSageAppProxyStarted = $false
            
            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }
            
            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }
            
            It "Should start the proxy in the set method" {
                Set-TargetResource @testParams
                $Global:SPDscUSageAppProxyStarted | Should Be $true
            }
        }
    }    
}
