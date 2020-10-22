[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPManagedMetaDataServiceAppDefault'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                $getTypeFullName = "Microsoft.SharePoint.Taxonomy.MetadataWebServiceApplicationProxy"

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

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    return @{
                        Proxies = @(
                            $managedMetadataServiceApplicationProxy,
                            $managedMetadataServiceApplicationProxyDefault
                        )
                    }
                }

                function Add-SPDscEvent
                {
                    param (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType,

                        [Parameter()]
                        [System.UInt32]
                        $EventID
                    )
                }
            }

            Context -Name "Specified proxy group does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppProxyGroup           = "DoesNotExist"
                        DefaultSiteCollectionProxyName = "DefaultSiteCollectionProxyName"
                        DefaultKeywordProxyName        = "DefaultKeywordProxyName"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return $null
                    }
                }

                It "Should throw an error in the Get Method, when the Service Application Proxy Group does not exist" {
                    { Get-TargetResource @testParams } | Should -Throw "Specified ServiceAppProxyGroup $($testParams.ServiceAppProxyGroup) does not exist."
                }

                It "Should throw an error in the Set Method, when the Service Application Proxy Group does not exist" {
                    { Set-TargetResource @testParams } | Should -Throw "Specified ServiceAppProxyGroup $($testParams.ServiceAppProxyGroup) does not exist."
                }
            }

            Context -Name "When no service application proxy or managed metadata service application proxy exist in the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppProxyGroup           = "ProxyGroup"
                        DefaultSiteCollectionProxyName = "DefaultSiteCollectionProxyName"
                        DefaultKeywordProxyName        = "DefaultKeywordProxyName"
                    }

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Proxies = $null
                        }
                    }
                }

                It "Should throw an error in the Get Method, when no Service Application Proxy is available" {
                    { Get-TargetResource @testParams } | Should -Throw "There are no Service Application Proxies available in the proxy group"
                }

                It "Should throw an error in the Set Method, when no Service Application Proxy is available" {
                    { Set-TargetResource @testParams } | Should -Throw "There are no Service Application Proxies available in the proxy group"
                }

                It "Should throw an error in the Get method, when no MMS Service Application Proxy is available" {
                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Proxies = @{
                                TypeName = "Mock Proxy"
                                Name     = "Mock Proxy"
                            } `
                            | Add-Member -MemberType ScriptMethod `
                                -name GetType `
                                -Value { `
                                    return (@{
                                        FullName = "Mock Proxy"
                                    }) `
                            } `
                                -PassThru -Force
                        }
                    }

                    { Get-TargetResource @testParams } | Should -Throw "There are no Managed Metadata Service Application Proxies available in the proxy group"
                }

                It "Should throw an error in the Set method, when no MMS Service Application Proxy is available" {
                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Proxies = @{
                                TypeName = "Mock Proxy"
                                Name     = "Mock Proxy"
                            } `
                            | Add-Member -MemberType ScriptMethod `
                                -name GetType `
                                -Value { `
                                    return (@{
                                        FullName = "Mock Proxy"
                                    }) `
                            } `
                                -PassThru -Force
                        }
                    }

                    { Set-TargetResource @testParams } | Should -Throw "There are no Managed Metadata Service Application Proxies available in the proxy group"
                }
            }

            Context -Name "When one managed metadata service application proxy exists and should be the default" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppProxyGroup           = "Default"
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

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Proxies = @(
                                $managedMetadataServiceApplicationProxyMock
                            )
                        }
                    }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return null, as the proxy is not configured properly" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultKeywordProxyName | Should -Be $null
                    $result.DefaultSiteCollectionProxyName | Should -Be $null
                }

                It "Should set the defaults" {
                    $Global:SPDscServiceProxyUpdateCalled = $false

                    Set-TargetResource @testParams

                    $managedMetadataServiceApplicationProxyMock.Properties["IsDefaultKeywordTaxonomy"] | Should -Be $true
                    $managedMetadataServiceApplicationProxyMock.Properties["IsDefaultSiteCollectionTaxonomy"] | Should -Be $true
                    $Global:SPDscServiceProxyUpdateCalled | Should -Be $true
                }
            }

            Context -Name "When several managed metadata service application proxy exists and another should be the default" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppProxyGroup           = "ProxyGroup"
                        DefaultSiteCollectionProxyName = "Managed Metadata Service Application Proxy"
                        DefaultKeywordProxyName        = "Managed Metadata Service Application Proxy"
                    }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return the default proxy" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultKeywordProxyName | Should -Be "Managed Metadata Service Application Proxy Default"
                    $result.DefaultSiteCollectionProxyName | Should -Be "Managed Metadata Service Application Proxy Default"
                }

                It "Should set the defaults" {
                    $Global:SPDscServiceProxyUpdateCalled = $false
                    $Global:SPDscServiceProxyUpdateCalledDefault = $false

                    Set-TargetResource @testParams

                    $managedMetadataServiceApplicationProxy.Properties["IsDefaultKeywordTaxonomy"] | Should -Be $true
                    $managedMetadataServiceApplicationProxy.Properties["IsDefaultSiteCollectionTaxonomy"] | Should -Be $true

                    $managedMetadataServiceApplicationProxyDefault.Properties["IsDefaultKeywordTaxonomy"] | Should -Be $false
                    $managedMetadataServiceApplicationProxyDefault.Properties["IsDefaultSiteCollectionTaxonomy"] | Should -Be $false

                    $Global:SPDscServiceProxyUpdateCalled | Should -Be $true
                    $Global:SPDscServiceProxyUpdateCalledDefault | Should -Be $true
                }
            }

            Context -Name "When several managed metadata service application proxy exists, both are default" -Fixture {
                BeforeAll {
                    $testParams = @{
                        ServiceAppProxyGroup           = "ProxyGroup"
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

                    Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                        return @{
                            Proxies = @(
                                $managedMetadataServiceApplicationProxyDefault,
                                $managedMetadataServiceApplicationProxyDefault
                            )
                        }
                    }
                }

                It "Should return false when the test method is called" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should return null" {
                    $result = Get-TargetResource @testParams
                    $result.DefaultKeywordProxyName | Should -Be $null
                    $result.DefaultSiteCollectionProxyName | Should -Be $null
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
