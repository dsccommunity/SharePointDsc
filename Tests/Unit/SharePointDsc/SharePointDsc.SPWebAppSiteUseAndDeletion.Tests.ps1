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
                                              -DscResource "SPWebAppSiteUseAndDeletion"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
                Url                                      = "http://example.contoso.local"
                SendUnusedSiteCollectionNotifications    = $true
                UnusedSiteNotificationPeriod             = 90
                AutomaticallyDeleteUnusedSiteCollections = $true
                UnusedSiteNotificationsBeforeDeletion    = 30
            }

            Mock -CommandName Get-SPFarm -MockWith { throw "Unable to detect local farm" }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should Be $null
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "The Web Application isn't available" -Fixture {
            $testParams = @{
                Url                                      = "http://example.contoso.local"
                SendUnusedSiteCollectionNotifications    = $true
                UnusedSiteNotificationPeriod             = 90
                AutomaticallyDeleteUnusedSiteCollections = $true
                UnusedSiteNotificationsBeforeDeletion    = 30
            }

            Mock -CommandName Get-SPWebApplication -MockWith  { 
                return $null
            }

            It "Should return null from the get method" {
                Get-TargetResource @testParams | Should BeNullOrEmpty 
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Configured web application could not be found"
            }
        }

        Context -Name "The server is in a farm and the incorrect settings have been applied" -Fixture {
            $testParams = @{
                Url                                      = "http://example.contoso.local"
                SendUnusedSiteCollectionNotifications    = $true
                UnusedSiteNotificationPeriod             = 90
                AutomaticallyDeleteUnusedSiteCollections = $true
                UnusedSiteNotificationsBeforeDeletion    = 30
            }

            Mock -CommandName Get-SPWebApplication -MockWith  {
                $returnVal = @{
                        SendUnusedSiteCollectionNotifications    = $false
                        UnusedSiteNotificationPeriod             = @{ TotalDays = 45; }
                        AutomaticallyDeleteUnusedSiteCollections = $false
                        UnusedSiteNotificationsBeforeDeletion    = 28
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnVal
            }

            Mock -CommandName Get-SPFarm -MockWith { return @{} }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscSiteUseUpdated = $false
            It "Should update the Site Use and Deletion settings" {
                Set-TargetResource @testParams
                $Global:SPDscSiteUseUpdated | Should Be $true
            }
        }

        Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
            $testParams = @{
                Url                                      = "http://example.contoso.local"
                SendUnusedSiteCollectionNotifications    = $true
                UnusedSiteNotificationPeriod             = 90
                AutomaticallyDeleteUnusedSiteCollections = $true
                UnusedSiteNotificationsBeforeDeletion    = 30
            }

            Mock -CommandName Get-SPWebApplication -MockWith  {
                $returnVal = @{
                    SendUnusedSiteCollectionNotifications    = $true
                    UnusedSiteNotificationPeriod             = @{ TotalDays = 90; }
                    AutomaticallyDeleteUnusedSiteCollections = $true
                    UnusedSiteNotificationsBeforeDeletion    = 30
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod -Name Update -Value { $Global:SPDscSiteUseUpdated = $true } -PassThru
                return $returnVal
            }
            Mock -CommandName Get-SPFarm -MockWith { return @{} }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
