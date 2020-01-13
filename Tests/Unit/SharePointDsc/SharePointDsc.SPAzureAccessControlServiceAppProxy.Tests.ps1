[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPAzureAccessControlServiceAppProxy"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        #Initialise tests
        $getTypeFullName = "Microsoft.SharePoint.Administration.SPAzureAccessControlServiceApplicationProxy"

        # Mocks for all contexts
        Mock -CommandName Remove-SPServiceApplicationProxy -MockWith { }

        # Test contexts
        Context -Name "When no service application proxies exist in the current farm and it should" -Fixture {
            $testParams = @{
                Name                       = "Test Proxy"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                Ensure                     = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith { return $null }
            Mock -CommandName New-SPAzureAccessControlServiceApplicationProxy -MockWith {
                $returnVal = @{
                    Name = "ServiceApp"
                    MetadataServiceEndpointUri = [Uri]"https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                }

                return $returnVal
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                Assert-MockCalled Get-SPServiceApplicationProxy
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new service application in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAzureAccessControlServiceApplicationProxy -ParameterFilter {
                    $Name -eq $testParams.Name -and
                    $MetadataServiceEndpointUri -eq $testParams.MetadataServiceEndpointUri
                }
            }
        }

        Context -Name "When service applications exist in the current farm with the same name but metadata service endpoint URI does not match" -Fixture {
            $testParams = @{
                Name                       = "Test Proxy"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                Ensure                     = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $spServiceAppProxy = [PSCustomObject]@{
                    Name                = $testParams.Name
                    MetadataEndpointUri = [Uri]"https://accounts.accesscontrol.windows.net/litware.onmicrosoft.com/metadata/json/1"
                }
                $spServiceAppProxy | Add-Member -MemberType ScriptMethod `
                    -Name GetType `
                    -Value {
                    return @{
                        FullName = $getTypeFullName
                    }
                } -Force
                return $spServiceAppProxy
            }
            Mock -CommandName New-SPAzureAccessControlServiceApplicationProxy -MockWith { return $null }
            Mock -CommandName Remove-SPServiceApplicationProxy -MockWith { return $null }

            It "Should return present from the get method" {
                $result = Get-TargetResource @testParams
                $result.Ensure | Should Be "Present"
                $result.MetadataServiceEndpointUri | Should Be "https://accounts.accesscontrol.windows.net/litware.onmicrosoft.com/metadata/json/1"
                Assert-MockCalled Get-SPServiceApplicationProxy
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should recreate the application proxy from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Get-SPServiceApplicationProxy
                Assert-MockCalled Remove-SPServiceApplicationProxy
                Assert-MockCalled New-SPAzureAccessControlServiceApplicationProxy -ParameterFilter {
                    $Name -eq $testParams.Name -and
                    $MetadataServiceEndpointUri -eq $testParams.MetadataServiceEndpointUri
                }
            }
        }

        Context -Name "When a service application exists and it should, and is also configured correctly" -Fixture {
            $testParams = @{
                Name                       = "Test Proxy"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                Ensure                     = "Present"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $spServiceAppProxy = [PSCustomObject]@{
                    Name                = $testParams.Name
                    MetadataEndpointUri = [Uri]$testParams.MetadataServiceEndpointUri
                }
                $spServiceAppProxy | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return @{ FullName = $getTypeFullName }
                } -Force
                return $spServiceAppProxy
            }

            It "Should return values from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
                Assert-MockCalled Get-SPServiceApplicationProxy
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When the service application proxy exists but it shouldn't" -Fixture {
            $testParams = @{
                Name                       = "Test Proxy"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                Ensure                     = "Absent"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $spServiceAppProxy = [PSCustomObject]@{
                    Name                = $testParams.Name
                    MetadataEndpointUri = [Uri]$testParams.MetadataServiceEndpointUri
                }
                $spServiceAppProxy | Add-Member -MemberType ScriptMethod -Name GetType -Value {
                    return @{ FullName = $getTypeFullName }
                } -Force
                return $spServiceAppProxy
            }

            It "Should return present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the remove service application cmdlet in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplicationProxy
            }
        }

        Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
            $testParams = @{
                Name                       = "Test Proxy"
                MetadataServiceEndpointUri = "https://accounts.accesscontrol.windows.net/contoso.onmicrosoft.com/metadata/json/1"
                Ensure                     = "Absent"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith { return $null }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
