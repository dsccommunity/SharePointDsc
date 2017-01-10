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
                                              -DscResource "SPSearchFileType"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

        # Mocks for all contexts   
        Mock -CommandName Remove-SPEnterpriseSearchFileFormat -MockWith {}   
        Mock -CommandName New-SPEnterpriseSearchFileFormat -MockWith {}   
        Mock -CommandName Set-SPEnterpriseSearchFileFormatState -MockWith {}   

        Mock -CommandName Get-SPServiceApplication -MockWith { 
            return @(
                New-Object -TypeName "Object" |  
                    Add-Member -MemberType ScriptMethod `
                               -Name GetType `
                               -Value {
                        New-Object -TypeName "Object" |
                            Add-Member -MemberType NoteProperty `
                                       -Name FullName `
                                       -Value $getTypeFullName `
                                       -PassThru
                                        } `
                            -PassThru -Force)
        }

        Context -Name "When no service applications exist in the current farm" -Fixture {
            $testParams = @{
                FileType = "abc"
                Description = "ABC"
                MimeType = "application/abc"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
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

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Service Application $($testParams.ServiceAppName) is not found"
            }
        }

        Context -Name "When service applications exist in the current farm but the specific search app does not" -Fixture {
            $testParams = @{
                FileType = "abc"
                Description = "ABC"
                MimeType = "application/abc"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }

            Mock -CommandName Get-SPServiceApplication -MockWith { 
                return @(@{
                    TypeName = "Some other service app type"
                }) 
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Service Application $($testParams.ServiceAppName) is not a search service application"
            }
        }

        Context -Name "When Ensure=Present, but Description and MimeType parameters are missing" -Fixture {
            $testParams = @{
                FileType = "abc"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should throw "Ensure is configured as Present, but MimeType and/or Description is missing"
            }
        }

        Context -Name "When a file type does not exists, but should be" -Fixture {
            $testParams = @{
                FileType = "abc"
                Description = "ABC"
                MimeType = "application/abc"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
                return $null
            }
            
            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should create a new file type in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled New-SPEnterpriseSearchFileFormat
            }
        }

        Context -Name "When a file type does not exists, but should be" -Fixture {
            $testParams = @{
                FileType = "abc"
                ServiceAppName = "Search Service Application"
                Ensure = "Absent"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
    	        return @{
                    Identity = $testParams.FileType
                    Name = "ABC"
                    MimeType = "application/abc" 
                    Enabled = $true
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should remove the file type in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchFileFormat
            }
        }

        Context -Name "When a file type exists, but with the incorrect settings" -Fixture {
            $testParams = @{
                FileType = "abc"
                ServiceAppName = "Search Service Application"
                Description = "XYZ"
                MimeType = "application/xyz"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
    	        return @{
                    Identity = $testParams.FileType
                    Name = "ABC"
                    MimeType = "application/abc" 
                    Enabled = $true
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should recreate the file type in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Remove-SPEnterpriseSearchFileFormat
                Assert-MockCalled New-SPEnterpriseSearchFileFormat
            }
        }

        Context -Name "When a file type exists, but with the incorrect state" -Fixture {
            $testParams = @{
                FileType = "abc"
                ServiceAppName = "Search Service Application"
                Description = "ABC"
                MimeType = "application/abc"
                Enabled = $true
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
    	        return @{
                    Identity = $testParams.FileType
                    Name = "ABC"
                    MimeType = "application/abc" 
                    Enabled = $false
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should enable the file type in the set method" {
                Set-TargetResource @testParams
                Assert-MockCalled Set-SPEnterpriseSearchFileFormatState
            }
        }

        Context -Name "When a file type exists and is configured correctly" -Fixture {
            $testParams = @{
                FileType = "abc"
                ServiceAppName = "Search Service Application"
                Description = "ABC"
                MimeType = "application/abc"
                Ensure = "Present"
            }
            
            Mock -CommandName Get-SPEnterpriseSearchFileFormat -MockWith {
    	        return @{
                    Identity = $testParams.FileType
                    Name = "ABC"
                    MimeType = "application/abc" 
                    Enabled = $true
                }
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
