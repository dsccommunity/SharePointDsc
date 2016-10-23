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
                                              -DscResource "SPIrmSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests

        # Mocks for all contexts   
        Mock -CommandName Get-SPFarm -MockWith { 
            return @{} 
        }

        # Test contexts
        Context -Name "The server is not part of SharePoint farm" -Fixture {
            $testParams = @{
              Ensure = "Present"
              RMSserver = "https://myRMSserver.local"
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
        
        Context -Name "IRM settings match desired settings" -Fixture {     
            $testParams = @{
                    Ensure = "Present"
                    RMSserver = "https://myRMSserver.local"
            }

            Mock -CommandName Get-SPDSCContentService -MockWith {
                $returnVal = @{
                    IrmSettings = @{
                        IrmRMSEnabled = $true 
                        IrmRMSUseAD = $false
                        IrmRMSCertServer = "https://myRMSserver.local"
                    }
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                                                     -Name Update `
                                                     -Value { 
                                                         $Global:SPDscIRMUpdated = $true 
                                                     } -PassThru
                return $returnVal
            }
            
            It "Should return present in the get method" {
                 (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            
            It "Should return true in the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
        
        Context -Name "IRM settings do not match desired settings" -Fixture {
            $testParams = @{
                    Ensure = "Present"
                    RMSserver = "https://myRMSserver.local"
            }

            Mock -CommandName Get-SPDSCContentService -MockWith {
                $returnVal = @{
                    IrmSettings = @{
                        IrmRMSEnabled = $false  
                        IrmRMSUseAD = $false
                        IrmRMSCertServer = $null 
                    }
                } 
                $returnVal = $returnVal | Add-Member -MemberType ScriptMethod `
                                                     -Name Update `
                                                     -Value { 
                                                         $Global:SPDscIRMUpdated = $true 
                                                      } -PassThru
                return $returnVal
            }
            
            It "Should return absent in the get method" {
                 (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            
            It "Should return false in the test method" {
                Test-TargetResource @testParams | Should Be $false 
            }
            
            $Global:SPDscIRMUpdated = $false
            It "Should apply the settings in the set method" {
                Set-TargetResource @testParams
                $Global:SPDscIRMUpdated | Should Be $true
            }
            
            It "Should throw when UseAD and RMSserver are both supplied" {
                $testParams.Add("UseADRMS",$true)
                { Set-TargetResource @testParams } | Should Throw 
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
