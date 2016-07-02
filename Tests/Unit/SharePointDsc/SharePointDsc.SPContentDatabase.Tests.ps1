[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPContentDatabase"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPContentDatabase - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "SharePoint_Content_01"
            DatabaseServer = "SQLSrv"
            WebAppUrl = "http://sharepoint.contoso.com"
            Enabled = $true
            WarningSiteCount = 2000
            MaximumSiteCount = 5000
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

        try { [Microsoft.SharePoint.Administration.SPObjectStatus] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint.Administration {
    public enum SPObjectStatus { Online, Disabled };
}        
"@
        }  

        Context "DatabaseServer parameter does not match actual setting" {
            Mock Get-SPDatabase { 
                return @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "WrongSQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }

            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false and display message to indicate the databaseserver parameter does not match" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the test method to say the databaseserver parameter does not match" {
                { Set-TargetResource @testParams } | Should throw "Specified database server does not match the actual database server. This resource cannot move the database to a different SQL instance."
            }
        }
        
        Context "Specified Web application does not exist" {
            Mock Get-SPDatabase { 
                return @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint2.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
            }
            Get-SPWebApplication { return $null }

            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws an exception in the set method to say the web application does not exist" {
                { Set-TargetResource @testParams } | Should throw "Specified web application does not exist."
            }
        }

        Context "Mount database throws an error" {
            Mock Get-SPDatabase { 
                $returnVal = @{}
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
            Mock Mount-SPContentDatabase { 
                throw "MOUNT ERROR"
            }

            It "mounting a content database generates an error" {
                { Set-TargetResource @testParams } | Should throw "Error occurred while mounting content database. Content database is not mounted."
            }
        }

        Context "Content database does not exist, but has to be" {
            Mock Get-SPDatabase { 
                $returnVal = @{}
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
            Mock Mount-SPContentDatabase { 
                $returnval = @{
                    Name = "SharePoint_Content_01"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }

            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCContentDatabaseUpdated = $false
            It "mounts a (new) content database" {
                Set-TargetResource @testParams
                $Global:SPDSCContentDatabaseUpdated | Should Be $true
            }
        }

        Context "Content database exists, but has incorrect settings" {
            Mock Get-SPDatabase { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Disabled"
                    WarningSiteCount = 1000
                    MaximumSiteCount = 2000
                }
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }

            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCContentDatabaseUpdated = $false
            It "updates the content database settings" {
                Set-TargetResource @testParams
                $Global:SPDSCContentDatabaseUpdated | Should Be $true
            }
        }
        
        Context "Content database exists, but Ensure is set to Absent" {
            Mock Get-SPDatabase { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Disabled"
                    WarningSiteCount = 1000
                    MaximumSiteCount = 2000
                }
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
            Mock Dismount-SPContentDatabase { }
            
            $testParams.Ensure = "Absent"
            
            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "updates the content database settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Dismount-SPContentDatabase
            }
        }

        Context "Content database is mounted to the incorrect web application" {
            Mock Get-SPDatabase { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint2.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
            Mock Dismount-SPContentDatabase { }
            Mock Mount-SPContentDatabase { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
                $returnVal = $returnVal | Add-Member ScriptMethod Update { $Global:SPDSCContentDatabaseUpdated = $true } -PassThru
                return $returnVal
            }

            $testParams.Ensure = "Present"
                        
            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDSCContentDatabaseUpdated = $false
            It "move the content database to the specified web application via set method" {
                Set-TargetResource @testParams
                $Global:SPDSCContentDatabaseUpdated | Should Be $true
            }
        }

        Context "Content database is present with correct settings and Ensure is Present" {
            Mock Get-SPDatabase { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
                        
            It "return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Content database is absent and Ensure is Absent" {
            Mock Get-SPDatabase { 
                $returnVal = @{ }
                return $returnVal
            }
            Mock Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }

            $testParams.Ensure = "Absent"
                        
            It "return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}
