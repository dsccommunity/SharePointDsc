[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 
    
$ModuleName = "MSFT_xSPUserProfileServiceApp"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPUserProfileServiceApp" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "User Profile Service App"
            ApplicationPool = "SharePoint Service Applications"
            FarmAccount = New-Object System.Management.Automation.PSCredential ("domain\username", (ConvertTo-SecureString "password" -AsPlainText -Force))
        }

        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        Mock Initialize-xSharePointPSSnapin { }
        Mock Get-UserProfileServiceProperties { return @{
            ProfileDatabase = @{
                Name = "SP_ProfileDB"
                Server = @{ Name = "SQL.domain.local" }
            }
            SocialDatabase = @{
                Name = "SP_SocialDB"
                Server = @{ Name = "SQL.domain.local" }
            }
            SynchronizationDatabase = @{
                Name = "SP_SyncDB"
                Server = @{ Name = "SQL.domain.local" }
            }
        }}
        Mock Get-SPFarm { return @{
            DefaultServiceAccount = @{ Name = $testParams.FarmAccount.Username }
        }}
        Mock New-SPProfileServiceApplication { }
        Mock New-SPProfileServiceApplicationProxy { }
        Mock Add-xSharePointUserToLocalAdmin { } 
        Mock Test-xSharePointUserIsLocalAdmin { return $false }
        Mock Remove-xSharePointUserToLocalAdmin { }
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"

        Context "When no service application exists in the current farm" {

            Mock Get-SPServiceApplication { return $null }

            It "returns null from the Get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "creates a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPProfileServiceApplication
            }
        }

        Context "When a service application exists and is configured correctly" {
            Mock Get-SPServiceApplication { 
                return @(@{
                    TypeName = "User Profile Service Application"
                    DisplayName = $testParams.Name
                    ApplicationPool = @{ Name = $testParams.ApplicationPool }
                })
            }

            It "returns values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
                Assert-MockCalled Get-SPServiceApplication -ParameterFilter { $Name -eq $testParams.Name } 
            }

            It "returns true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }    
}