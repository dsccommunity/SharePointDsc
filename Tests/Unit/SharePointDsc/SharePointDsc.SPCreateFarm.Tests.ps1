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
                                              -DscResource "SPCreateFarm"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
        $mockFarmAccount = New-Object -TypeName "System.Management.Automation.PSCredential" `
                                      -ArgumentList @("username", $mockPassword)
        $mockPassphrase = New-Object -TypeName "System.Management.Automation.PSCredential" `
                                     -ArgumentList @("PASSPHRASEUSER", $mockPassword)

        $modulePath = "Modules\SharePointDsc\Modules\SharePointDsc.Farm\SPFarm.psm1"
        Import-Module -Name (Join-Path -Path $Global:SPDscHelper.RepoRoot -ChildPath $modulePath -Resolve)

        # Mocks for all contexts

        # Test contexts
        Context -Name "no farm is configured locally and a supported version of SharePoint is installed" -Fixture {
            $testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                FarmAccount = $mockFarmAccount
                Passphrase =  $mockPassphrase
                AdminContentDatabaseName = "Admin_Content"
                CentralAdministrationAuth = "Kerberos"
                CentralAdministrationPort = 1234
            }

            It "Should throw an exception in the get method" {
                { Get-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }

            It "Should throw an exception in the test method" {
                { Test-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }

            It "Should throw an exception in the set method" {
                { Set-TargetResource @testParams } | Should Throw "SPCreateFarm: This resource has been removed. Please update your configuration to use SPFarm instead."
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
