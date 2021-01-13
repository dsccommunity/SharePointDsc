[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPFarmSolution'
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
                Invoke-Command -Scriptblock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests

                # Mocks for all contexts
                Mock -CommandName Update-SPSolution -MockWith { }
                Mock -CommandName Install-SPFeature -MockWith { }
                Mock -CommandName Install-SPSolution -MockWith { }
                Mock -CommandName Uninstall-SPSolution -MockWith { }
                Mock -CommandName Remove-SPSolution -MockWith { }
                Mock -CommandName Start-Sleep -MockWith { }
            }

            # Test contexts
            Context -Name "The solution isn't installed, but should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Present"
                        Version     = "1.0.0.0"
                        WebAppUrls  = @("http://app1", "http://app2")
                    }

                    $global:SPDscSolutionAdded = $false

                    Mock -CommandName Get-SPSolution -MockWith {
                        if ($global:SPDscSolutionAdded)
                        {
                            return [pscustomobject] @{ }
                        }
                        else
                        {
                            return $null
                        }
                    }

                    Mock -CommandName Add-SPSolution -MockWith {
                        $solution = [pscustomobject] @{ Properties = @{ Version = "" } }
                        $solution | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        $global:SPDscSolutionAdded = $true
                        return $solution
                    }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected empty values from the get method" {
                    $getResults.Ensure | Should -Be "Absent"
                    $getResults.Version | Should -Be "0.0.0.0"
                    $getResults.Deployed | Should -Be $false
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "uploads and installes the solution to the farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPSolution
                    Assert-MockCalled Install-SPSolution

                }
            }

            Context -Name "The solution isn't installed, but should be with loop testing" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Present"
                        Version     = "1.0.0.0"
                        WebAppUrls  = @("http://app1", "http://app2")
                    }

                    $global:SPDscSolutionAdded = $false
                    $global:SPDscLoopCount = 0

                    Mock -CommandName Get-SPSolution -MockWith {
                        $global:SPDscLoopCount = $global:SPDscLoopCount + 1
                        $index = $global:SPDscLoopCount
                        if ($global:SPDscSolutionAdded)
                        {
                            if ($index -gt 2)
                            {
                                return @{
                                    JobExists = $false
                                }
                            }
                            else
                            {
                                return @{
                                    JobExists = $true
                                }
                            }
                        }
                        else
                        {
                            return $null
                        }
                    }

                    Mock -CommandName Add-SPSolution -MockWith {
                        $solution = [pscustomobject] @{ Properties = @{ Version = "" } }
                        $solution | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        $global:SPDscSolutionAdded = $true
                        return $solution
                    }
                }

                It "Should return the expected empty values from the get method" {
                    $global:SPDscLoopCount = 0
                    $getResults = Get-TargetResource @testParams
                    $getResults.Ensure | Should -Be "Absent"
                    $getResults.Version | Should -Be "0.0.0.0"
                    $getResults.Deployed | Should -Be $false
                }

                It "Should return false from the test method" {
                    $global:SPDscLoopCount = 0
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "uploads and installes the solution to the farm" {
                    $global:SPDscLoopCount = 0
                    Set-TargetResource @testParams
                    Assert-MockCalled Add-SPSolution
                    Assert-MockCalled Install-SPSolution

                }
            }

            Context -Name "The solution is installed, but should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Absent"
                        Version     = "1.0.0.0"
                        WebAppUrls  = @("http://app1", "http://app2")
                    }

                    Mock -CommandName Get-SPSolution -MockWith {
                        return [pscustomobject]@{
                            Deployed                = $true
                            Properties              = @{ Version = "1.0.0.0" }
                            DeployedWebApplications = @( [pscustomobject]@{Url = "http://app1" }, [pscustomobject]@{Url = "http://app2" })
                            ContainsGlobalAssembly  = $true
                        }
                    }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected values from the get method" {
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Version | Should -Be "1.0.0.0"
                    $getResults.Deployed | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "uninstalles and removes the solution from the web apps and the farm" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Uninstall-SPSolution
                    Assert-MockCalled Remove-SPSolution
                }
            }

            Context -Name "The solution isn't installed, and should not be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $false
                        Ensure      = "Absent"
                        Version     = "0.0.0.0"
                        WebAppUrls  = @()
                    }

                    Mock -CommandName Get-SPSolution -MockWith { $null }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected empty values from the get method" {
                    $getResults.Ensure | Should -Be "Absent"
                    $getResults.Version | Should -Be "0.0.0.0"
                    $getResults.Deployed | Should -Be $false
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The solution is installed, but needs update" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Present"
                        Version     = "1.1.0.0"
                        WebAppUrls  = @("http://app1", "http://app2")
                    }

                    Mock -CommandName Get-SPSolution -MockWith {
                        $s = [pscustomobject]@{
                            Deployed                = $true
                            Properties              = @{ Version = "1.0.0.0" }
                            DeployedWebApplications = @( [pscustomobject]@{Url = "http://app1" }, [pscustomobject]@{Url = "http://app2" })
                            ContainsGlobalAssembly  = $true
                        }
                        $s | Add-Member -Name Update -MemberType ScriptMethod -Value { }
                        return $s
                    }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected values from the get method" {
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Version | Should -Be "1.0.0.0"
                    $getResults.Deployed | Should -Be $true
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the solution in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Update-SPSolution
                    Assert-MockCalled Install-SPFeature
                }
            }

            Context -Name "The solution is installed, and should be" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Present"
                        Version     = "1.0.0.0"
                        WebAppUrls  = @("http://app1", "http://app2")
                    }

                    Mock -CommandName Get-SPSolution -MockWith {
                        return [pscustomobject]@{
                            Deployed                = $true
                            Properties              = @{ Version = "1.0.0.0" }
                            DeployedWebApplications = @( [pscustomobject]@{Url = "http://app1" }, [pscustomobject]@{Url = "http://app2" })
                            ContainsGlobalAssembly  = $true
                        }
                    }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected values from the get method" {
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Version | Should -Be "1.0.0.0"
                    $getResults.Deployed | Should -Be $true
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "The solution exists but is not deloyed, and needs update" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name        = "SomeSolution"
                        LiteralPath = "\\server\share\file.wsp"
                        Deployed    = $true
                        Ensure      = "Present"
                        Version     = "1.1.0.0"
                        WebAppUrls  = @()
                    }

                    $solution = [pscustomobject]@{
                        Deployed                = $false
                        Properties              = @{ Version = "1.0.0.0" }
                        DeployedWebApplications = @( [pscustomobject]@{Url = "http://app1" }, [pscustomobject]@{Url = "http://app2" })
                        ContainsGlobalAssembly  = $true
                    }
                    $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

                    Mock -CommandName Get-SPSolution -MockWith { $solution }
                    Mock -CommandName Add-SPSolution -MockWith { $solution }

                    $getResults = Get-TargetResource @testParams
                }

                It "Should return the expected values from the get method" {
                    $getResults.Ensure | Should -Be "Present"
                    $getResults.Version | Should -Be "1.0.0.0"
                    $getResults.Deployed | Should -Be $false
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It "Should update the solution in the set method" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Remove-SPSolution
                    Assert-MockCalled Add-SPSolution
                    Assert-MockCalled Install-SPSolution
                }
            }

            Context -Name "A solution deployment can target a specific compatability level" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name          = "SomeSolution"
                        LiteralPath   = "\\server\share\file.wsp"
                        Deployed      = $true
                        Ensure        = "Present"
                        Version       = "1.1.0.0"
                        WebAppUrls    = @()
                        SolutionLevel = "All"
                    }

                    $solution = [pscustomobject]@{
                        Deployed                = $false
                        Properties              = @{ Version = "1.0.0.0" }
                        DeployedWebApplications = @( [pscustomobject]@{Url = "http://app1" }, [pscustomobject]@{Url = "http://app2" })
                        ContainsGlobalAssembly  = $true
                    }
                    $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

                    Mock -CommandName Get-SPSolution -MockWith { $solution }
                    Mock -CommandName Add-SPSolution -MockWith { $solution }
                }

                It "deploys the solution using the correct compatability level" {
                    Set-TargetResource @testParams

                    Assert-MockCalled Install-SPSolution -ParameterFilter { $CompatibilityLevel -eq $testParams.SolutionLevel }
                }
            }

            Context -Name "Solution is scoped at the Web Application Level" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name          = "SomeSolution"
                        LiteralPath   = "\\server\share\file.wsp"
                        Deployed      = $true
                        Ensure        = "Present"
                        Version       = "1.1.0.0"
                        WebAppUrls    = @("https://contoso.com")
                        SolutionLevel = "All"
                    }

                    $solution = [pscustomobject]@{
                        Deployed                       = $false
                        Properties                     = @{ Version = "1.0.0.0" }
                        ContainsWebApplicationResource = $true
                        DeployedWebApplications        = @()
                        ContainsGlobalAssembly         = $true
                    }
                    $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

                    Mock -CommandName Get-SPSolution -MockWith { $solution }
                    Mock -CommandName Add-SPSolution -MockWith { $solution }
                }

                It "Deploys the solution to the specified Web Application" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Solution is scoped at multiple Web Application Levels" -Fixture {
                BeforeAll {
                    $testParams = @{
                        Name          = "SomeSolution"
                        LiteralPath   = "\\server\share\file.wsp"
                        Deployed      = $true
                        Ensure        = "Present"
                        Version       = "1.1.0.0"
                        WebAppUrls    = @("https://contoso.com", "https://tailspintoys.com")
                        SolutionLevel = "All"
                    }

                    $numberOfCalls = 1
                    Mock -CommandName Install-SPSolution -MockWith {
                        if ($numberOfCalls -le 1)
                        {
                            $numberOfCalls++
                            throw "A deployment is already underway"
                        }
                    }

                    $solution = [pscustomobject]@{
                        Deployed                       = $false
                        Properties                     = @{ Version = "1.0.0.0" }
                        ContainsWebApplicationResource = $true
                        DeployedWebApplications        = @()
                        ContainsGlobalAssembly         = $true
                    }
                    $solution | Add-Member -Name Update -MemberType ScriptMethod  -Value { }

                    Mock -CommandName Get-SPSolution -MockWith { $solution }
                    Mock -CommandName Add-SPSolution -MockWith { $solution }
                }

                It "Deploys the solution to the specified Web Application" {
                    Set-TargetResource @testParams
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            Name          = "test.wsp"
                            LiteralPath   = "C:\test.wsp"
                            Deployed      = $true
                            Ensure        = "Present"
                            Version       = 1.0.0.0
                            WebAppUrls    = "http://sharepoint.contoso.com"
                            SolutionLevel = "All"
                        }
                    }

                    Mock -CommandName Get-SPSolution -MockWith {
                        $spSolution = [PSCustomObject]@{
                            Name = "test.wsp"
                        }
                        return $spSolution
                    }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    $result = @'
        SPFarmSolution [0-9A-Fa-f]{8}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{4}[-][0-9A-Fa-f]{12}
        {
            Deployed             = \$True;
            Ensure               = "Present";
            LiteralPath          = \$AllNodes.Where{\$Null -ne \$_.SPSolutionPath}.SPSolutionPath\+"test.wsp";
            Name                 = "test.wsp";
            PsDscRunAsCredential = \$Credsspfarm;
            SolutionLevel        = "All";
            WebAppUrls           = "http://sharepoint.contoso.com";
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")
                    Export-TargetResource | Should -Match $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
