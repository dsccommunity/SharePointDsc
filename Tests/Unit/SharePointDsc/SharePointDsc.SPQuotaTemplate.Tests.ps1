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
                                              -DscResource "SPQuotaTemplate"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        Add-Type -TypeDefinition @"
    namespace Microsoft.SharePoint.Administration 
    { 
        public class SPQuotaTemplate 
        { 
            public string Name { get; set; } 
            public long StorageMaximumLevel { get; set; } 
            public long StorageWarningLevel { get; set; } 
            public double UserCodeMaximumLevel { get; set; } 
            public double UserCodeWarningLevel { get; set; }
        }
    }
"@

        # Mocks for all contexts   
        Mock -CommandName Get-SPFarm -MockWith { 
            return @{} 
        }

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
                Name = "Test"
                StorageMaxInMB = 1024
                StorageWarningInMB = 512
                MaximumUsagePointsSolutions = 1000
                WarningUsagePointsSolutions = 800
                Ensure = "Present"
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                throw "Unable to detect local farm" 
            }

            It "Should return null from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method to say there is no local farm" {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Context -Name "The server is in a farm and the incorrect settings have been applied to the template" -Fixture {
            $testParams = @{
                Name = "Test"
                StorageMaxInMB = 1024
                StorageWarningInMB = 512
                MaximumUsagePointsSolutions = 1000
                WarningUsagePointsSolutions = 800
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDSCContentService -MockWith {
                $quotaTemplates = @(@{
                        Test = @{
                            StorageMaximumLevel = 512
                            StorageWarningLevel = 256
                            UserCodeMaximumLevel = 400
                            UserCodeWarningLevel = 200
                        }
                    })
                $quotaTemplatesCol = {$quotaTemplates}.Invoke() 

                $contentService = @{
                    QuotaTemplates = $quotaTemplatesCol
                } 

                $contentService = $contentService | Add-Member -MemberType ScriptMethod `
                                                               -Name Update `
                                                               -Value { 
                                                                   $Global:SPDscQuotaTemplatesUpdated = $true 
                                                                } -PassThru
                return $contentService
            }

            It "Should return values from the get method" {
                Get-TargetResource @testParams | Should Not BeNullOrEmpty
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscQuotaTemplatesUpdated = $false
            It "Should update the quota template settings" {
                Set-TargetResource @testParams
                $Global:SPDscQuotaTemplatesUpdated | Should Be $true
            }
        }

        Context -Name "The server is in a farm and the template doesn't exist" -Fixture {
            $testParams = @{
                Name = "Test"
                StorageMaxInMB = 1024
                StorageWarningInMB = 512
                MaximumUsagePointsSolutions = 1000
                WarningUsagePointsSolutions = 800
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDSCContentService -MockWith {
                $quotaTemplates = @(@{
                        Test = $null
                    })
                $quotaTemplatesCol = {$quotaTemplates}.Invoke() 

                $contentService = @{
                    QuotaTemplates = $quotaTemplatesCol
                } 

                $contentService = $contentService | Add-Member -MemberType ScriptMethod `
                                                               -Name Update `
                                                               -Value { 
                                                                   $Global:SPDscQuotaTemplatesUpdated = $true 
                                                                } -PassThru
                return $contentService
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be 'Absent'
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            $Global:SPDscQuotaTemplatesUpdated = $false
            It "Should create a new quota template" {
                Set-TargetResource @testParams
                $Global:SPDscQuotaTemplatesUpdated | Should Be $true
            }
        }

        Context -Name "The server is in a farm and the correct settings have been applied" -Fixture {
            $testParams = @{
                Name = "Test"
                StorageMaxInMB = 1024
                StorageWarningInMB = 512
                MaximumUsagePointsSolutions = 1000
                WarningUsagePointsSolutions = 800
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPDSCContentService -MockWith { 
                 $returnVal = @{ 
                     QuotaTemplates = @{ 
                         Test = @{ 
                             StorageMaximumLevel = 1073741824 
                             StorageWarningLevel = 536870912 
                             UserCodeMaximumLevel = 1000 
                             UserCodeWarningLevel = 800 
                         } 
                     } 
                 }  
                 $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                                                      -Name Update `
                                                      -Value { 
                                                          $Global:SPDscQuotaTemplatesUpdated = $true 
                                                        } -PassThru 
                 return $returnVal 
             } 

            It "Should return values from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be 'Present'
                $result.StorageMaxInMB | Should Be 1024
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }

        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
