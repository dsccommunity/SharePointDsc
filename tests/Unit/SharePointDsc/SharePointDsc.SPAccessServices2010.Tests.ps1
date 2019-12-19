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
    -DscResource "SPAccessServices2010"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Access.Server.MossHost.AccessServerWebServiceApplication"

        # Mocks for all contexts
        Mock -CommandName Get-SPServiceApplication -MockWith { }
        Mock -CommandName New-SPAccessServiceApplication -MockWith { }
        Mock -CommandName Remove-SPServiceApplication -MockWith { }

        # Test contexts
        Context -Name "When Access 2010 Services doesn't exists and should exist" -Fixture {
            $testParams = @{
                Name            = "Access 2010 Services Service Application"
                ApplicationPool = "SharePoint Service Applications"
                Ensure          = "Present"
            }

            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPAccessServiceApplication -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    DisplayName = $testParams.Name
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                    -Name GetType `
                    -Value {
                    return @{
                        FullName = "$($getTypeFullName).other"
                    }
                } -PassThru -Force
                return @($spServiceApp)
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should call Methods on Set-TargetResource" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplication
                Assert-MockCalled New-SPAccessServiceApplication -Times 1
                Assert-MockCalled Remove-SPServiceApplication -Times 0
            }
        }
        Context -Name "When Access 2010 Services exists and should exist" -Fixture {
            $testParams = @{
                Name            = "Access 2010 Services Service Application"
                ApplicationPool = "SharePoint Service Applications"
                Ensure          = "Present"
            }

            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPAccessServiceApplication -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    DisplayName     = $testParams.Name
                    ApplicationPool = [PSCustomObject]@{
                        Name = $testParams.ApplicationPool
                    }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                    -Name GetType `
                    -Value {
                    return @{
                        FullName = "$($getTypeFullName)"
                    }
                } -PassThru -Force
                return @($spServiceApp)
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "Should call Remove - Get - New on Set-TargetResource" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplication

            }
        }

        Context -Name "When Access 2010 Services exists and shouldn't exist" -Fixture {
            $testParams = @{
                Name            = "Access 2010 Services Service Application"
                ApplicationPool = "SharePoint Service Applications"
                Ensure          = "Absent"
            }

            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPAccessServiceApplication -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith {
                $spServiceApp = [PSCustomObject]@{
                    DisplayName     = $testParams.Name
                    ApplicationPool = [PSCustomObject]@{
                        Name = $testParams.ApplicationPool
                    }
                }
                $spServiceApp | Add-Member -MemberType ScriptMethod `
                    -Name GetType `
                    -Value {
                    return @{
                        FullName = "$($getTypeFullName)"
                    }
                } -PassThru -Force
                return @($spServiceApp)
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should call Remove - Get - New on Set-TargetResource" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPServiceApplication
                Assert-MockCalled Get-SPServiceApplication
            }
        }

        Context -Name "When Access 2010 Services doesn't exists and should exist" -Fixture {
            $testParams = @{
                Name            = "Access 2010 Services Service Application"
                ApplicationPool = "SharePoint Service Applications"
                Ensure          = "Present"
            }

            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPAccessServiceApplication -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
            It "Should call New on Set-TargetResource" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPAccessServiceApplication
            }
        }

        Context -Name "When Access 2010 Services doesn't exists and shouldn't exist" -Fixture {
            $testParams = @{
                Name            = "Access 2010 Services Service Application"
                ApplicationPool = "SharePoint Service Applications"
                Ensure          = "Absent"
            }

            Mock -CommandName Remove-SPServiceApplication -MockWith { }
            Mock -CommandName New-SPAccessServiceApplication -MockWith { }
            Mock -CommandName Get-SPServiceApplication -MockWith {
                return $null
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
            It "Should call New on Set-TargetResource" {
                Set-TargetResource @testParams
                Assert-MockCalled Get-SPServiceApplication
            }
        }
    }
}


Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
