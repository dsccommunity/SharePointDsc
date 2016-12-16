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
                                              -DscResource "SPFarmPropertyBag"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Test contexts
        Context -Name 'No local SharePoint farm was detected' {
            $testParams = @{
                Key = 'FARM_TYPE'
                Value = 'SearchFarm'
            }

            Mock -CommandName Get-SPFarm -MockWith { 
                throw 'Unable to detect local farm' 
            }

            $result = Get-TargetResource @testParams

            It 'Should return absent from the get method' {
                $result.Ensure | Should Be 'absent'
            }

            It 'Should return the same values as passed as parameters' {
                $result.Key | Should Be $testParams.Key
            }

            It 'Should return null as the value used' {
                $result.value | Should Be $null
            }           

            It 'Should return false from the test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should throw an exception in the set method to say there is no local farm' {
                { Set-TargetResource @testParams } | Should throw "No local SharePoint farm was detected"
            }
        }

        Mock -CommandName Get-SPFarm -MockWith {
            $spFarm = [pscustomobject]@{
                Properties = @{
                    FARM_TYPE = 'SearchFarm'
                }
            }
            $spFarm = $spFarm | Add-Member ScriptMethod Update { 
                $Global:SPDscFarmPropertyUpdated = $true 
            } -PassThru
            $spFarm = $spFarm | Add-Member ScriptMethod Remove { 
                $Global:SPDscFarmPropertyRemoved = $true 
            } -PassThru
            return $spFarm
        }

        Context -Name 'The farm property does not exist, but should be' -Fixture {
            $testParams = @{
                Key = 'FARM_TYPE'
                Value = 'NewSearchFarm'
            }
            
            $result = Get-TargetResource @testParams

            It 'Should return absent from the get method' {
                $result.Ensure | Should Be 'absent'
            }

            It 'Should return the same key value as passed as parameter' {
                $result.Key | Should Be $testParams.Key
            }      

            It 'Should return false from the test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should not throw an exception in the set method' {
                { Set-TargetResource @testParams } | Should not throw
            }

            $Global:SPDscFarmPropertyUpdated = $false
            It 'Calls Get-SPFarm and update farm property bag from the set method' { 
                Set-TargetResource @testParams 

                $Global:SPDscFarmPropertyUpdated | Should Be $true
            }
        }

        Context -Name 'The farm property exists, and should be' -Fixture {
            $testParams = @{
                Key = 'FARM_TYPE'
                Value = 'SearchFarm'
                Ensure = 'Present'
            }
            
            $result = Get-TargetResource @testParams

            It 'Should return present from the get method' {
                $result.Ensure | Should Be 'present'
            }

            It 'Should return the same values as passed as parameters' {
                $result.Key | Should Be $testParams.Key
                $result.value | Should Be $testParams.value
            }          

            It 'Should return true from the test method' {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name 'The farm property does not exist, and should be' -Fixture {
            $testParams = @{
                Key = 'FARM_TYPED'
                Ensure = 'Absent'
            }
            
            $result = Get-TargetResource @testParams

            It 'Should return absent from the get method' {
                $result.Ensure | Should Be 'absent'
            }

            It 'Should return the same values as passed as parameters' {
                $result.Key | Should Be $testParams.Key
                $result.value | Should Be $testParams.value
            }          

            It 'Should return true from the test method' {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name 'The farm property exists, but should not be' -Fixture {
            $testParams = @{
                Key = 'FARM_TYPE'
                Value = 'SearchFarm'
                Ensure = 'Absent'
            }
            
            $result = Get-TargetResource @testParams

            It 'Should return Present from the get method' {
                $result.Ensure | Should Be 'Present'
            }

            It 'Should return the same values as passed as parameters' {
                $result.Key | Should Be $testParams.Key
                $result.value | Should Be $testParams.Value
            }           

            It 'Should return false from the test method' {
                Test-TargetResource @testParams | Should Be $false
            }

            It 'Should not throw an exception in the set method' {
                { Set-TargetResource @testParams } | Should not throw
            }

            $Global:SPDscFarmPropertyUpdated = $false
            It 'Calls Get-SPFarm and remove farm property bag from the set method' { 
                Set-TargetResource @testParams 

                $Global:SPDscFarmPropertyUpdated | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
