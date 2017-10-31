[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
    -DscResource "SPManagedMetadataServiceLanguageSettings"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Mocks for all contexts
        Mock -CommandName Get-SPWebApplication -MockWith {
            return @(
                @{
                    Url                            = "http://FakeCentralAdmin.Url"
                    IsAdministrationWebApplication = $true
                }
            )
        }

        $termStores = @{ 
            "Managed Metadata Service Application Proxy" = @{
                Name            = "Managed Metadata Service Application Proxy"
                Languages       = @(1033)
                DefaultLanguage = 1033
                WorkingLanguage = 1033  
            } | Add-Member -MemberType ScriptMethod `
                -Name AddLanguage `
                -Value { $Global:SPDscAddLanguageCalled = $true }  `
                -PassThru -Force `
                | Add-Member -MemberType ScriptMethod `
                -Name DeleteLanguage `
                -Value { $Global:SPDscDeleteLanguageCalled = $true }  `
                -PassThru -Force `
                | Add-Member -MemberType ScriptMethod `
                -Name CommitAll `
                -Value { }  `
                -PassThru -Force 
        }
        
        Mock -CommandName Get-SPTaxonomySession -MockWith {
            return @{
                TermStores = $termStores
            }
        }

        # Test contexts
        Context -Name "When no termstore at all or no termstore for the service application proxy exists in the current farm" -Fixture {
            $testParams = @{
                ProxyName = "Managed Metadata Service Application Proxy"
            }

            Mock -CommandName Get-SPTaxonomySession -MockWith { return $null }

            It "Should throw an error, that there is no taxonomy session available" {
                { Get-TargetResource @testParams } | Should Throw "Could not get taxonomy session. Please check if the managed metadata service is started."
            }

            Mock -CommandName Get-SPTaxonomySession -MockWith {
                return @{
                    TermStores = @{
                        "Managed Metadata Service Application Proxy Wrong" = @{}
                    }
                    
                }
            }

            It "Should throw an error, that there is no termstore with the name $($testParams.ProxyName)" {
                { Get-TargetResource @testParams } | Should Throw "Specified termstore '$($testParams.ProxyName)' does not exist."
            }
        }

        Context -Name "When the termstore for the service application proxy exists in the current farm and is configured correctly" -Fixture {
            $testParams = @{
                ProxyName       = "Managed Metadata Service Application Proxy"
                Languages       = @(1033)
                DefaultLanguage = 1033
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "When the termstore for the service application proxy exists in the current farm and is not configured correctly" -Fixture {
            $testParams = @{
                ProxyName       = "Managed Metadata Service Application Proxy"
                DefaultLanguage = 1033
                Languages       = @(1033)
            }

            Mock -CommandName Get-SPTaxonomySession -MockWith {
                return @{
                    TermStores = @{
                        "Managed Metadata Service Application Proxy" = @{
                            Name            = "Managed Metadata Service Application Proxy"
                            Languages       = @(1031)
                            DefaultLanguage = 1031
                            WorkingLanguage = 1033    
                        } 
                    }
                }
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should match the mocked values" {
                $result = Get-TargetResource @testParams
                $result.DefaultLanguage | Should Be 1031
                $result.Languages | Should Be @(1031)
            }
        }        

        Context -Name "When the default language has to be set" -Fixture {
            $testParams = @{
                ProxyName       = "Managed Metadata Service Application Proxy"
                DefaultLanguage = 1031
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should change the value for 'Default Language'" {
                Set-TargetResource @testParams
                $termStores[$testParams.ProxyName].DefaultLanguage | Should Be $testParams.DefaultLanguage
            }
        }

        Context -Name "When the working languages have to be changed" -Fixture {
            $testParams = @{
                ProxyName = "Managed Metadata Service Application Proxy"
                Languages = @(1031)
            }
            
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should change the value for 'Languages'" {
                $Global:SPDscAddLanguageCalled = $false
                $Global:SPDscDeleteLanguageCalled = $false
                Set-TargetResource @testParams
                $Global:SPDscAddLanguageCalled | Should Be $true
                $Global:SPDscDeleteLanguageCalled | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
