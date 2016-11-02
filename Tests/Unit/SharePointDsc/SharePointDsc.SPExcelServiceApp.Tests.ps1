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
                                              -DscResource "SPExcelServiceApp"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Excel.Server.MossHost.ExcelServerWebServiceApplication" 

        # Mocks for all contexts   
        Mock -CommandName Remove-SPServiceApplication -MockWith { }
        Mock -CommandName New-SPExcelServiceApplication -MockWith { }
        Mock -CommandName Get-SPExcelFileLocation -MockWith { }
        Mock -CommandName Set-SPExcelServiceApplication -MockWith { }
        Mock -CommandName New-SPExcelFileLocation -MockWith { }
        Mock -CommandName Set-SPExcelFileLocation -MockWith { }
        Mock -CommandName Remove-SPExcelFileLocation -MockWith { }

        # Test contexts
        switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major) 
        {
            15 {
                Context -Name "When no service applications exist in the current farm" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        return $null 
                    }

                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent"
                    }

                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should create a new service application in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled New-SPExcelServiceApplication 
                    }
                }

                Context -Name "When service applications exist in the current farm but the specific Excel Services app does not" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                                            DisplayName = $testParams.Name 
                                        } 
                        $spServiceApp | Add-Member -MemberType ScriptMethod `
                                                -Name GetType `
                                                -Value {  
                                                        return @{ 
                                                            FullName = "Microsoft.Office.UnKnownWebServiceApplication" 
                                                        }  
                                                    } -PassThru -Force 
                        return $spServiceApp 
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return @(@{
                        TypeName = "Some other service app type"
                    }) }

                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                    }

                }

                Context -Name "When a service application exists and is configured correctly" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    It "Should return values from the get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                    }

                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }
                
                Context -Name "When the service application exists but it shouldn't" -Fixture {
                    $testParams = @{
                        Name = "Test App"
                        ApplicationPool = "-"
                        Ensure = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }
                    
                    It "Should return present from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Present" 
                    }
                    
                    It "Should return false when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $false
                    }
                    
                    It "Should call the remove service application cmdlet in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Remove-SPServiceApplication
                    }
                }
                
                Context -Name "When the serivce application doesn't exist and it shouldn't" -Fixture {
                    $testParams = @{
                        Name = "Test App"
                        ApplicationPool = "-"
                        Ensure = "Absent"
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { return $null }
                    
                    It "Should return absent from the Get method" {
                        (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
                    }
                    
                    It "Should return true when the Test method is called" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "When the service app should have trusted locations, but doesn't" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                        TrustedFileLocations = @(
                            (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                Address = "http://"
                                LocationType = "SharePoint"
                                WorkbookSizeMax = 10
                            })
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPExcelFileLocation -MockWith { 
                        return @()
                    }

                    It "Should return no trusted location results from the get method" {
                        (Get-TargetResource @testParams).TrustedFileLocations | Should BeNullOrEmpty
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should create the trusted location in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName New-SPExcelFileLocation
                    }
                }

                Context -Name "When the service app should have trusted locations, but the settings don't match" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                        TrustedFileLocations = @(
                            (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                Address = "http://"
                                LocationType = "SharePoint"
                                WorkbookSizeMax = 10
                            })
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPExcelFileLocation -MockWith { 
                        return @(@{
                            Address = "http://"
                            LocationType = "SharePoint"
                            WorkbookSizeMax = 2
                        })
                    }

                    It "Should return trusted location results from the get method" {
                        (Get-TargetResource @testParams).TrustedFileLocations | Should Not BeNullOrEmpty
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should update the trusted location in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName Set-SPExcelFileLocation
                    }
                }

                Context -Name "When the service app should have trusted locations, and does" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                        TrustedFileLocations = @(
                            (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                Address = "http://"
                                LocationType = "SharePoint"
                                WorkbookSizeMax = 10
                            })
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPExcelFileLocation -MockWith { 
                        return @(@{
                            Address = "http://"
                            LocationType = "SharePoint"
                            WorkbookSizeMax = 10
                        })
                    }

                    It "Should return trusted location results from the get method" {
                        (Get-TargetResource @testParams).TrustedFileLocations | Should Not BeNullOrEmpty
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should Be $true
                    }
                }

                Context -Name "When the service app should have trusted locations, and does but also has an extra one that should be removed" -Fixture {
                    $testParams = @{
                        Name = "Test Excel Services App"
                        ApplicationPool = "Test App Pool"
                        TrustedFileLocations = @(
                            (New-CimInstance -ClassName MSFT_SPExcelFileLocation -ClientOnly -Property @{
                                Address = "http://"
                                LocationType = "SharePoint"
                                WorkbookSizeMax = 10
                            })
                        )
                    }

                    Mock -CommandName Get-SPServiceApplication -MockWith { 
                        $spServiceApp = [PSCustomObject]@{ 
                            TypeName = "Excel Services Application Web Service Application"
                            DisplayName = $testParams.Name
                            ApplicationPool = @{ Name = $testParams.ApplicationPool }
                        }
                        $spServiceApp = $spServiceApp | Add-Member -MemberType ScriptMethod -Name GetType -Value { 
                            return @{ FullName = $getTypeFullName } 
                        } -PassThru -Force
                        return $spServiceApp
                    }

                    Mock -CommandName Get-SPExcelFileLocation -MockWith { 
                        return @(@{
                            Address = "http://"
                            LocationType = "SharePoint"
                            WorkbookSizeMax = 10
                        },
                        @{
                            Address = "https://"
                            LocationType = "SharePoint"
                            WorkbookSizeMax = 10
                        })
                    }

                    It "Should return trusted location results from the get method" {
                        (Get-TargetResource @testParams).TrustedFileLocations | Should Not BeNullOrEmpty
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should Be $false
                    }

                    It "Should remove the trusted location in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled -CommandName Remove-SPExcelFileLocation
                    }
                }
            }
            16 {
                Context -Name "All methods throw exceptions as Excel Services doesn't exist in 2016" -Fixture {
                    It "Should throw on the get method" {
                        { Get-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the test method" {
                        { Test-TargetResource @testParams } | Should Throw
                    }

                    It "Should throw on the set method" {
                        { Set-TargetResource @testParams } | Should Throw
                    }
                }
            }
            Default {
                throw [Exception] "A supported version of SharePoint was not used in testing"
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
