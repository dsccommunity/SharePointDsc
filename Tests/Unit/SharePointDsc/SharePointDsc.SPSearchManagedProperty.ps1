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
                                              -DscResource "SPSearchManagedProperty"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $getTypeFullName = "Microsoft.Office.Server.Search.Administration.SearchServiceApplication"

        # Mocks for all contexts
        Mock -CommandName New-SPEnterpriseSearchMetadataManagedProperty -MockWith {}
        Mock -CommandName Set-SPEnterpriseSearchMetadataManagedProperty -MockWith {}
        Mock -CommandName Remove-SPEnterpriseSearchMetadataManagedProperty -MockWith {}

        Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
            return @(@{
                Name = "MockManagedProperty"
                PID = 0
                PropertyType = "Text"
                Searchable = $true
                Refinable = $true
                Queryable = $true
                Sortable = $true
                NoWordBreaker = $true
            })
        }

        Context -Name "When the property doesn't exist and should" -Fixture {
            Mock -CommandName Get-SPEnterpriseSearchMetadataManagedProperty -MockWith {
                return @({
                    Name = "TestParam"
                    PropertyType = "Text"
                    Ensure = "Absent"
                })
            }
            $testParams = @{
                Name = "TestParam"
                PropertyType = "Text"
                ServiceAppName = "Search Service Application"
                Ensure = "Present"
            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
