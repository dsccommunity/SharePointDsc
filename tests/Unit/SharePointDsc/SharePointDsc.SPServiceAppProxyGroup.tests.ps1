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
$script:DSCResourceName = 'SPServiceAppProxyGroup'
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
    Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
        InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
            Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

            # Initialize tests
            $listofAllServiceAppProxies = @(
                "Web 1 User Profile Service Application",
                "Web 1 MMS Service Application",
                "State Service Application",
                "Web 2 User Profile Service Application"
            )

            # Mocks for all contexts
            Mock -CommandName Add-SPServiceApplicationProxyGroupMember -MockWith { }
            Mock -CommandName Remove-SPServiceApplicationProxyGroupMember -MockWith { }
            Mock -CommandName Get-SPServiceApplicationProxy -MockWith {
                $proxiesToReturn = @()
                foreach ($ServiceAppProxy in $listofAllServiceAppProxies)
                {
                    $proxiesToReturn += @{
                        DisplayName = $ServiceAppProxy
                    }
                }
                return $proxiesToReturn
            }
            Mock -CommandName New-SPServiceApplicationProxyGroup {
                return @{
                    Name = $TestParams.Name
                }
            }

            # Test contexts
            Context -Name "ServiceAppProxies and ServiceAppProxiesToInclude parameters used simultaniously" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxies          = "Web 1 User Profile Service Application", "Web 1 MMS Service Application", "State Service Application"
                    ServiceAppProxiesToInclude = "Web 2 User Profile Service Application"
                }

                It "Should return Ensure=null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should throw "Cannot use the ServiceAppProxies parameter together with the ServiceAppProxiesToInclude or ServiceAppProxiesToExclude parameters"
                }
            }

            Context -Name "None of the ServiceAppProxies, ServiceAppProxiesToInclude and ServiceAppProxiesToExclude parameters are used" -Fixture {
                $testParams = @{
                    Name   = "My Proxy Group"
                    Ensure = "Present"
                }

                It "Should return Ensure=null from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should BeNullOrEmpty
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an exception in the set method" {
                    { Set-TargetResource @testParams } | Should throw "At least one of the following parameters must be specified: ServiceAppProxies, ServiceAppProxiesToInclude, ServiceAppProxiesToExclude"
                }
            }

            Context -Name "The Service Application Proxy Group does not exist and should" -Fixture {
                $testParams = @{
                    Name              = "Shared Services"
                    Ensure            = "Present"
                    ServiceAppProxies = @("State Service Application", "Web 1 User Profile Service Application")
                }

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    return $null
                }

                It "Should return ensure = absent  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Absent'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should create the Service Application Proxy Group with the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled New-SPServiceApplicationProxyGroup
                }
            }

            Context -Name "The ServiceApplication Proxy Group does not exist, and should not" -Fixture {
                $testParams = @{
                    Name   = "Shared Services"
                    Ensure = "Absent"
                }

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    return $null
                }

                It "Should return ensure = absent  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Absent'
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxies match" -Fixture {
                $testParams = @{
                    Name              = "Shared Services"
                    Ensure            = "Present"
                    ServiceAppProxies = @("State Service Application", "Web 1 User Profile Service Application")
                }

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $TestParams.ServiceAppProxies)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxies do not match" -Fixture {
                $testParams = @{
                    Name              = "Shared Services"
                    Ensure            = "Present"
                    ServiceAppProxies = @(
                        "State Service Application",
                        "Web 1 User Profile Service Application")
                }

                $serviceAppProxiesConfigured = @(
                    "State Service Application",
                    "Web 2 User Profile Service Application")

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $serviceAppProxiesConfigured)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should add the missing and remove the extra service proxy in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 1
                    Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 1
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxiesToInclude matches" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxiesToInclude = @(
                        "State Service Application",
                        "Web 1 User Profile Service Application")
                }

                $serviceAppProxiesConfigured = @(
                    "State Service Application",
                    "Web 1 User Profile Service Application",
                    "Web 1 MMS Service Application")

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $serviceAppProxiesConfigured)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxiesToInclude does not match" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxiesToInclude = @(
                        "State Service Application",
                        "Web 1 User Profile Service Application")
                }

                $serviceAppProxiesConfigured = @(
                    "State Service Application",
                    "Web 1 MMS Service Application")

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $serviceAppProxiesConfigured)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should add the missing and then not remove the extra service proxy in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 1
                    Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 0
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxiesToExclude matches" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxiesToExclude = @("Web 1 User Profile Service Application")
                }

                $serviceAppProxiesConfigured = @(
                    "State Service Application",
                    "Web 1 MMS Service Application")

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $serviceAppProxiesConfigured)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }

            Context -Name "The Service Application Proxy Group exists and should, ServiceAppProxiesToExclude does not match" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxiesToExclude = @("Web 1 User Profile Service Application", "Web 2 User Profile Service Application")
                }

                $serviceAppProxiesConfigured = @(
                    "State Service Application",
                    "Web 1 MMS Service Application",
                    "Web 1 User Profile Service Application")

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in $serviceAppProxiesConfigured)
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should remove the extra but not add a new service proxy in the set mthod" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Remove-SPServiceApplicationProxyGroupMember -Exactly 1
                    Assert-MockCalled Add-SPServiceApplicationProxyGroupMember -Exactly 0
                }
            }

            Context -Name "Specified service application does not exist, ServiceAppProxies specified" -Fixture {
                $testParams = @{
                    Name              = "Shared Services"
                    Ensure            = "Present"
                    ServiceAppProxies = @(
                        "No Such Service Application",
                        "Web 1 User Profile Service Application")
                }

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in "Web 1 User Profile Service Application")
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should throw "Invalid Service Application Proxy No Such Service Application"
                }
            }

            Context -Name "Specified service application does not exist, ServiceAppProxiesToInclude specified" -Fixture {
                $testParams = @{
                    Name                       = "Shared Services"
                    Ensure                     = "Present"
                    ServiceAppProxiesToInclude = @(
                        "No Such Service Application",
                        "Web 1 User Profile Service Application")
                }

                Mock -CommandName Get-SPServiceApplicationProxyGroup -MockWith {
                    $proxiesToReturn = @()
                    foreach ($ServiceAppProxy in "Web 1 User Profile Service Application")
                    {
                        $proxiesToReturn += @{
                            DisplayName = $ServiceAppProxy
                        }
                    }
                    return @{
                        Name    = $testParams.Name
                        Proxies = $proxiesToReturn
                    }
                }

                It "Should return ensure = present  from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should be 'Present'
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should Be $false
                }

                It "Should throw an error from the set method" {
                    { Set-TargetResource @testParams } | Should throw "Invalid Service Application Proxy No Such Service Application"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
