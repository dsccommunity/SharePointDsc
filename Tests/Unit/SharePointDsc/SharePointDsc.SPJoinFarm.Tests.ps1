[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
                                              -DscResource "SPJoinFarm"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassphrase = ConvertTo-SecureString -String "MyFarmPassphrase" -AsPlainText -Force
        $mockPassphraseCredential = New-Object -TypeName System.Management.Automation.PSCredential `
                                               -ArgumentList @("passphrase", $mockPassphrase)

        $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.Farm\SPFarm.psm1"
        Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

        # Mocks for all contexts

        # Test contexts
        Context -Name "no farm is configured locally and a supported version of SharePoint is installed" {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                Passphrase = $mockPassphraseCredential
            }
            
            It "the get method returns null when the farm is not configured" {
                { Get-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }

            It "Should return false from the test method" {
                { Test-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }

            It "Should call the new configuration database cmdlet in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
