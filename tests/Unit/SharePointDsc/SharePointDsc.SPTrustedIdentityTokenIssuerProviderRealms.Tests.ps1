[CmdletBinding()]
param
(
    [Parameter()]
    [string]$SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPTrustedIdentityTokenIssuerProviderRealms'
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
            }

            Context -Name "The SPTrustedLoginProvider not exists in the farm" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith { return $null }
                }

                It "Ensure should be Absent, since SPTrustedIdentityTokenIssuer 'Contoso' was not found" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and should not be changed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Present"
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                        foreach ($realm in $testParams.ProviderRealms)
                        {
                            $url = New-Object System.Uri($realm.RealmUrl)
                            $realmsDict[$url.ToString()] = $realm.RealmUrn
                        }
                        $realmRet = [pscustomobject]@{
                            ProviderRealms = $realmsDict
                        }
                        return $realmRet
                    }
                }

                It "Test-TargetResource: Should return true" {
                    Test-TargetResource @testParams | Should -Be $true
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists but one realm will be added" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Present"
                    }

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $testParams.ProviderRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmsDict.Remove("https://intranet.contoso.com/")

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }
                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    } -PassThru

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm added to SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1 `
                            -and $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 2) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms empty and all will be added" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Present"
                    }

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $testParams.ProviderRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmsDict.Clear()

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }
                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    } -PassThru

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realms added to SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 2 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1 ) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one realm will be removed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Absent"
                    }

                    $Global:SPTrustedIdentityTokenIssuerRemoveProviderRealmCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $testParams.ProviderRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmsDict.Remove("https://intranet.contoso.com/")

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm removed from SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and all will be removed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Absent"
                    }

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $testParams.ProviderRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realms removed from SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one realm will be updated" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName     = "Contoso"
                        ProviderRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure         = "Present"
                    }

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $testParams.ProviderRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmsDict["https://intranet.contoso.com/"] = "urn:sharepoint:contoso:intranet1"

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm updated in SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 2 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one will be excluded" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToExclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm removed in SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 1 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one should be excluded but not found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToExclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search1"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Test-TargetResource: Should return true" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one should be included" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToInclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://searchx.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm added in SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 3 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms empty and two should be included" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToInclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly)
                            (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://intranet.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:intranet"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmsDict.Clear()

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return absent" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realms included in to SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 2 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one should be included but found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToInclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Present"
                }

                It "Test-TargetResource: Should return true" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The SPTrustedLoginProviderRealms already exists and one should be included and updated" -Fixture {
                BeforeAll {
                    $testParams = @{
                        IssuerName              = "Contoso"
                        ProviderRealmsToInclude = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                    RealmUrl = "https://search.contoso.com"
                                    RealmUrn = "urn:sharepoint:contoso:search1"
                                } -ClientOnly))
                        Ensure                  = "Present"
                    }

                    $pRealms = @((New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://search.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:search"
                            } -ClientOnly)
                        (New-CimInstance -ClassName MSFT_SPProviderRealm -Property @{
                                RealmUrl = "https://intranet.contoso.com"
                                RealmUrn = "urn:sharepoint:contoso:intranet"
                            } -ClientOnly))

                    $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount = 0
                    $Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount = 0

                    $realmsDict = New-Object 'system.collections.generic.dictionary[system.uri,string]'
                    foreach ($realm in $pRealms)
                    {
                        $url = New-Object System.Uri($realm.RealmUrl)
                        $realmsDict[$url.ToString()] = $realm.RealmUrn
                    }

                    $realmRet = [pscustomobject]@{
                        ProviderRealms = $realmsDict
                    }

                    $realmRet.ProviderRealms | Add-Member -Name Add -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount
                    } -Force

                    $realmRet | Add-Member -Name Update -MemberType ScriptMethod -Value {
                        ++$Global:SPTrustedIdentityTokenIssuerUpdateCalledCount
                    }  -Force

                    Mock -CommandName Get-SPTrustedIdentityTokenIssuer -MockWith {
                        return $realmRet
                    }
                }

                It "Get-TargetResource: Should return present" {
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                }

                It "Test-TargetResource: Should return false" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Set-TargetResource: Realm updated in SPTrustedIdentityTokenIssuer.ProviderRealms" {
                    Set-TargetResource @testParams
                    $($Global:SPTrustedIdentityTokenIssuerAddProviderRealmCalledCount -eq 2 `
                            -and $Global:SPTrustedIdentityTokenIssuerUpdateCalledCount -eq 1) | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
