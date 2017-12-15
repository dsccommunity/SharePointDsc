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
    -DscResource "SPManagedMetaDataServiceAppDefault"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        $getTypeFullName = "Managed Metadata Service Connection"

        $managedMetadataServiceApplicationProxy = @{
            TypeName   = "Managed Metadata Service Connection"
            Name       = "Managed Metadata Service Application Proxy"
            Properties = @{
                IsDefaultSiteCollectionTaxonomy = $false
                IsDefaultKeywordTaxonomy        = $false
            }
        } `
            | Add-Member -MemberType ScriptMethod `
            -Name Update `
            -Value { `
                $Global:SPDscServiceProxyUpdateCalled = $true
        } `
            -PassThru -Force `
            | Add-Member -MemberType ScriptMethod `
            -Name GetType `
            -Value { `
                return (@{
                    FullName = $getTypeFullName
                }) `
        } `
            -PassThru -Force

        $managedMetadataServiceApplicationProxyDefault = @{
            TypeName   = "Managed Metadata Service Connection"
            Name       = "Managed Metadata Service Application Proxy Default"
            Properties = @{
                IsDefaultSiteCollectionTaxonomy = $true
                IsDefaultKeywordTaxonomy        = $true
            }
        } `
            | Add-Member -MemberType ScriptMethod `
            -Name Update `
            -Value { `
                $Global:SPDscServiceProxyUpdateCalledDefault = $true `
        } `
            -PassThru -Force `
            | Add-Member -MemberType ScriptMethod `
            -Name GetType `
            -Value { `
                return (@{
                    FullName = $getTypeFullName
                }) `
        } `
            -PassThru -Force

        Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
            return @(
                $managedMetadataServiceApplicationProxy,
                $managedMetadataServiceApplicationProxyDefault
            )
        }

        Context -Name "When no service application proxy or managed metadata service application proxy exist in the farm" -Fixture {
            $testParams = @{
                IsSingleInstance               = "Yes"
                DefaultSiteCollectionProxyName = "DefaultSiteCollectionProxyName"
                DefaultKeywordProxyName        = "DefaultKeywordProxyName"
            }

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return $null
            }

            It "Should throw an error, when no Service Application Proxy is available" {
                { Get-TargetResource @testParams } | Should Throw "There are no Managed Metadata Service Application Proxy available in the farm"
            }

            $mockProxy = @{
                TypeName = "Mock Proxy"
                Name     = "Mock Proxy"

            } `
                | Add-Member -MemberType ScriptMethod `
                -Name GetType `
                -Value { `
                    return (@{
                        FullName = "Mock Proxy"
                    }) `
            } `
                -PassThru -Force

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return @(
                    $mockProxy
                )
            }

            It "Should throw an error, when no Service Application Proxy is available" {
                { Get-TargetResource @testParams } | Should Throw "There are no Managed Metadata Service Application Proxy available in the farm"
            }
        }

        Context -Name "When one managed metadata service application proxy exists and should be the default" -Fixture {
            $testParams = @{
                IsSingleInstance               = "Yes"
                DefaultSiteCollectionProxyName = "Managed Metadata Service Application Proxy"
                DefaultKeywordProxyName        = "Managed Metadata Service Application Proxy"
            }

            $managedMetadataServiceApplicationProxyMock = @{
                TypeName   = "Managed Metadata Service Connection"
                Name       = "Managed Metadata Service Application Proxy"
                Properties = @{
                    IsDefaultSiteCollectionTaxonomy = $false
                    IsDefaultKeywordTaxonomy        = $false
                }
            } `
                | Add-Member -MemberType ScriptMethod `
                -Name Update `
                -Value { `
                    $Global:SPDscServiceProxyUpdateCalled = $true
            } `
                -PassThru -Force `
                | Add-Member -MemberType ScriptMethod `
                -Name GetType `
                -Value { `
                    return (@{
                        FullName = $getTypeFullName
                    }) `
            } `
                -PassThru -Force

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return @(
                    $managedMetadataServiceApplicationProxyMock
                )
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should return null, as the proxy is not configured properly" {
                $result = Get-TargetResource @testParams
                $result.DefaultKeywordProxyName | Should Be $null
                $result.DefaultSiteCollectionProxyName | Should Be $null
            }

            It "Should set the defaults" {
                $Global:SPDscServiceProxyUpdateCalled = $false

                Set-TargetResource @testParams

                $managedMetadataServiceApplicationProxyMock.Properties["IsDefaultKeywordTaxonomy"] | Should Be $true
                $managedMetadataServiceApplicationProxyMock.Properties["IsDefaultSiteCollectionTaxonomy"] | Should Be $true
                $Global:SPDscServiceProxyUpdateCalled | Should Be $true
            }
        }

        Context -Name "When several managed metadata service application proxy exists and another should be the default" -Fixture {
            $testParams = @{
                IsSingleInstance               = "Yes"
                DefaultSiteCollectionProxyName = "Managed Metadata Service Application Proxy"
                DefaultKeywordProxyName        = "Managed Metadata Service Application Proxy"
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should return the default proxy" {
                $result = Get-TargetResource @testParams
                $result.DefaultKeywordProxyName | Should Be "Managed Metadata Service Application Proxy Default"
                $result.DefaultSiteCollectionProxyName | Should Be "Managed Metadata Service Application Proxy Default"
            }

            It "Should set the defaults" {
                $Global:SPDscServiceProxyUpdateCalled = $false
                $Global:SPDscServiceProxyUpdateCalledDefault = $false

                Set-TargetResource @testParams

                $managedMetadataServiceApplicationProxy.Properties["IsDefaultKeywordTaxonomy"] | Should Be $true
                $managedMetadataServiceApplicationProxy.Properties["IsDefaultSiteCollectionTaxonomy"] | Should Be $true

                $managedMetadataServiceApplicationProxyDefault.Properties["IsDefaultKeywordTaxonomy"] | Should Be $false
                $managedMetadataServiceApplicationProxyDefault.Properties["IsDefaultSiteCollectionTaxonomy"] | Should Be $false

                $Global:SPDscServiceProxyUpdateCalled | Should Be $true
                $Global:SPDscServiceProxyUpdateCalledDefault | Should Be $true
            }
        }

        Context -Name "When several managed metadata service application proxy exists, both are default" -Fixture {
            $testParams = @{
                IsSingleInstance               = "Yes"
                DefaultSiteCollectionProxyName = "Managed Metadata Service Application Proxy"
                DefaultKeywordProxyName        = "Managed Metadata Service Application Proxy"
            }

            $managedMetadataServiceApplicationProxyDefault = @{
                TypeName   = "Managed Metadata Service Connection"
                Name       = "Managed Metadata Service Application Proxy Default"
                Properties = @{
                    IsDefaultSiteCollectionTaxonomy = $true
                    IsDefaultKeywordTaxonomy        = $true
                }
            } `
                | Add-Member -MemberType ScriptMethod `
                -Name Update `
                -Value { `
                    $Global:SPDscServiceProxyUpdateCalledDefault = $true `
            } `
                -PassThru -Force `
                | Add-Member -MemberType ScriptMethod `
                -Name GetType `
                -Value { `
                    return (@{
                        FullName = $getTypeFullName
                    }) `
            } `
                -PassThru -Force

            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                return @(
                    $managedMetadataServiceApplicationProxyDefault,
                    $managedMetadataServiceApplicationProxyDefault
                )
            }

            It "Should return false when the test method is called" {
                Test-TargetResource @testParams | Should be $false
            }

            It "Should return null" {
                $result = Get-TargetResource @testParams
                $result.DefaultKeywordProxyName | Should Be $null
                $result.DefaultSiteCollectionProxyName | Should Be $null
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
