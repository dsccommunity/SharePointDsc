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
                                              -DscResource "SPInstall"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        function New-SPDscMockPrereq
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [String]
                $Name
            )
            $object = New-Object -TypeName System.Object
            $object = $object | Add-Member -Type NoteProperty `
                                           -Name "DisplayName" `
                                           -Value $Name `
                                           -PassThru
            return $object
        }

        # Mocks for all contexts   
        Mock -CommandName Get-ChildItem -MockWith {
            $full = @{
                    Version = "4.5.0.0"
                    Release = "0"
                    PSChildName = "Full"
                } 

                $client = @{
                    Version = "4.5.0.0"
                    Release = "0"
                    PSChildName = "Client"
                } 

                $returnval = @($full, $client)
                $returnVal = $returnVal | Add-Member ScriptMethod GetValue { return 380000 } -PassThru
                return $returnval
        }

        Mock -CommandName Get-SPDSCAssemblyVersion -MockWith { 
            return $Global:SPDscHelper.CurrentStubBuildNumber.Major 
        }
        

        # Test contexts
        Context -Name "SharePoint binaries are not installed but should be" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith { 
                return $null 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "SharePoint binaries are installed and should be" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith { 
                return @(
                    (New-SPDscMockPrereq -Name "Microsoft SharePoint Server 2013"),
                    (New-SPDscMockPrereq -Name "Something else")
                ) 
            } -ParameterFilter { $null -ne $Path }

            Mock -CommandName Get-ItemProperty -MockWith {
                return @{
                    VersionInfo = @{
                        FileVersion = "15.0.4709.1000"
                    }
                } 
            }

            Mock -CommandName Test-Path -MockWith {
                return $true
            }

            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "SharePoint installation executes as expected" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
            }
            
            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = 0 
                }
            }

            It "reboots the server after a successful installation" {
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
            }
        }

        Context -Name "SharePoint installation fails" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
            }
            
            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = -1 
                }
            }

            It "Should throw an exception on an unknown exit code" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context -Name "SharePoint binaries are installed and should not be" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith { return @{} }  -ParameterFilter { $null -ne $Path }

            It "Should throw in the test method because uninstall is unsupported" {
                { Test-TargetResource @testParams } | Should Throw
            }

            It "Should throw in the set method because uninstall is unsupported" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context -Name "SharePoint 2013 is installing on a server with .NET 4.6" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
            }

            Mock -CommandName Get-ChildItem -MockWith {
                $full = @{
                    Version = "4.6.0.0"
                    Release = "0"
                    PSChildName = "Full"
                } 

                $client = @{
                    Version = "4.6.0.0"
                    Release = "0"
                    PSChildName = "Client"
                } 

                $returnval = @($full, $client)
                $returnVal = $returnVal | Add-Member ScriptMethod GetValue { return 391000 } -PassThru
                return $returnval
            }
            
            It "Should throw an error in the set method" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }
        
        Context -Name "SharePoint is not installed and should be, using custom install directories" -Fixture {
            $testParams = @{
                BinaryDir = "C:\SPInstall"
                ProductKey = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                Ensure = "Present"
                InstallPath = "C:\somewhere"
                DataPath = "C:\somewhere\else"
            }

            Mock -CommandName Get-ItemProperty -MockWith { 
                return $null 
            } -ParameterFilter { 
                $null -ne $Path 
            }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method"  {
                Test-TargetResource @testParams | Should Be $false
            }
            
            Mock -CommandName Start-Process { 
                return @{ 
                    ExitCode = 0 
                }
            }

            It "reboots the server after a successful installation" {
                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
