[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPContentDatabase"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        try 
        { 
            [Microsoft.SharePoint.Administration.SPObjectStatus] 
        }
        catch 
        {
            Add-Type -TypeDefinition @"
namespace Microsoft.SharePoint.Administration {
    public enum SPObjectStatus { Online, Disabled };
}        
"@
        }

        # Mocks for all contexts
        Mock -CommandName Dismount-SPContentDatabase -MockWith { }
        Mock -CommandName Get-SPWebApplication -MockWith { 
            return @{ 
                Url="http://sharepoint.contoso.com/" 
            } 
        }

        # Test contexts
        Context -Name "DatabaseServer parameter does not match actual setting" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                return @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "WrongSQLSrv"
                    WebApplication = @{ 
                        Url = "http://sharepoint.contoso.com/" 
                    }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
            }
            Mock -CommandName Get-SPWebApplication -MockWith { 
                return @{ 
                    Url="http://sharepoint.contoso.com/" 
                } 
            }

            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false and display message to indicate the databaseserver parameter does not match" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the test method to say the databaseserver parameter does not match" {
                { Set-TargetResource @testParams } | Should throw "Specified database server does not match the actual database server. This resource cannot move the database to a different SQL instance."
            }
        }
        
        Context -Name "Specified Web application does not exist" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }

            Mock -CommandName Get-SPDatabase -MockWith { 
                return @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ 
                        Url = "http://sharepoint2.contoso.com/" 
                    }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
            }
            Mock -CommandName Get-SPWebApplication -MockWith { 
                return @() 
            }

            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say the web application does not exist" {
                { Set-TargetResource @testParams } | Should throw "Specified web application does not exist."
            }
        }

        Context -Name "Mount database throws an error" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                $returnVal = @{}
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }
            
            Mock -CommandName Mount-SPContentDatabase -MockWith { 
                throw "MOUNT ERROR"
            }

            It "mounting a content database generates an error" {
                { Set-TargetResource @testParams } | Should throw "Error occurred while mounting content database. Content database is not mounted."
            }
        }

        Context -Name "Content database does not exist, but has to be" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                $returnVal = @{}
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }

            Mock -CommandName Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
            Mock Mount-SPContentDatabase { 
                $returnval = @{
                    Name = "SharePoint_Content_01"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Online"
                    WarningSiteCount = 2000
                    MaximumSiteCount = 5000
                }
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }

            It "Should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscContentDatabaseUpdated = $false
            It "mounts a (new) content database" {
                Set-TargetResource @testParams
                $Global:SPDscContentDatabaseUpdated | Should Be $true
            }
        }

        Context -Name "Content database exists, but has incorrect settings" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Disabled"
                    WarningSiteCount = 1000
                    MaximumSiteCount = 2000
                }
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }

            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscContentDatabaseUpdated = $false
            It "Should update the content database settings" {
                Set-TargetResource @testParams
                $Global:SPDscContentDatabaseUpdated | Should Be $true
            }
        }
        
        Context -Name "Content database exists, but Ensure is set to Absent" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                $returnVal = @{
                    Name = "SharePoint_Content_01"
                    Type = "Content Database"
                    Server = "SQLSrv"
                    WebApplication = @{ Url = "http://sharepoint.contoso.com/" }
                    Status = "Disabled"
                    WarningSiteCount = 1000
                    MaximumSiteCount = 2000
                }
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }
            
            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should update the content database settings" {
                Set-TargetResource @testParams
                Assert-MockCalled Dismount-SPContentDatabase
            }
        }

        Context -Name "Content database is mounted to the incorrect web application" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
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

            Mock -CommandName Get-SPWebApplication { return @{ Url="http://sharepoint.contoso.com/" } }
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
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { 
                    $Global:SPDscContentDatabaseUpdated = $true 
                } -PassThru
                return $returnVal
            }
                        
            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscContentDatabaseUpdated = $false
            It "move the content database to the specified web application via set method" {
                Set-TargetResource @testParams
                $Global:SPDscContentDatabaseUpdated | Should Be $true
            }
        }

        Context -Name "Content database is present with correct settings and Ensure is Present" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
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
                        
            It "Should return Ensure=Present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "Content database is absent and Ensure is Absent" -Fixture {
            $testParams = @{
                Name = "SharePoint_Content_01"
                DatabaseServer = "SQLSrv"
                WebAppUrl = "http://sharepoint.contoso.com"
                Enabled = $true
                WarningSiteCount = 2000
                MaximumSiteCount = 5000
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPDatabase -MockWith { 
                $returnVal = @{ }
                return $returnVal
            }
                        
            It "Should return Ensure=Absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
