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
                                              -DscResource "SPInfoPathFormsServiceConfig"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        Mock -CommandName Get-SPInfoPathFormsService -MockWith {
            return @{
                Ensure = "Present"
                AllowUserFormBrowserEnabling             = $true
                AllowUserFormBrowserRendering            = $true
                MaxDataConnectionTimeout                 = 20000
                DefaultDataConnectionTimeout             = 10000
                MaxDataConnectionResponseSize            = 1500
                RequireSslForDataConnections             = $true
                AllowEmbeddedSqlForDataConnections       = $false
                AllowUdcAuthenticationForDataConnections = $false
                AllowUserFormCrossDomainDataConnections  = $false
                MaxPostbacksPerSession                   = 75
                MaxUserActionsPerPostback                = 200
                ActiveSessionsTimeout                    = 1440
                MaxSizeOfUserFormState                   = 4194304
            }| Add-Member ScriptMethod Update {
            } -PassThru
        }

        Context -Name "When the InfoPath Form Services is null" -Fixture {
            Mock -CommandName Get-SPInfoPathFormsService -MockWith {
                return $null
            }

            $testParams = @{
                IsSingleInstance                         = "Yes"
                Ensure                                   = "Present"
                AllowUserFormBrowserEnabling             = $false
                AllowUserFormBrowserRendering            = $true
                MaxDataConnectionTimeout                 = 20000
                DefaultDataConnectionTimeout             = 10000
                MaxDataConnectionResponseSize            = 1500
                RequireSslForDataConnections             = $true
                AllowEmbeddedSqlForDataConnections       = $false
                AllowUdcAuthenticationForDataConnections = $false
                AllowUserFormCrossDomainDataConnections  = $false
                MaxPostbacksPerSession                   = 75
                MaxUserActionsPerPostback                = 200
                ActiveSessionsTimeout                    = 1440
                MaxSizeOfUserFormState                   = 4096
            }

            It "Should return false when the Test method is called" {
                Test-TargetResource @testParams | Should Be $false
            }
        }

        Context -Name "When trying to remove configurations" -Fixture {
            $testParams = @{
                IsSingleInstance                         = "Yes"
                Ensure                                   = "Absent"
                AllowUserFormBrowserEnabling             = $false
                AllowUserFormBrowserRendering            = $true
                MaxDataConnectionTimeout                 = 20000
                DefaultDataConnectionTimeout             = 10000
                MaxDataConnectionResponseSize            = 1500
                RequireSslForDataConnections             = $true
                AllowEmbeddedSqlForDataConnections       = $false
                AllowUdcAuthenticationForDataConnections = $false
                AllowUserFormCrossDomainDataConnections  = $false
                MaxPostbacksPerSession                   = 75
                MaxUserActionsPerPostback                = 200
                ActiveSessionsTimeout                    = 1440
                MaxSizeOfUserFormState                   = 4096
            }

            It "Should return false when the Test method is called" {
                { Set-TargetResource @testParams } | Should throw "This resource cannot undo InfoPath Forms Service Configuration changes. " `
                "Please set Ensure to Present or omit the resource"
            }
        }

        Context -Name "When the InfoPath Form Services is properly configured" -Fixture {
            $testParams = @{
                IsSingleInstance                         = "Yes"
                Ensure                                   = "Present"
                AllowUserFormBrowserEnabling             = $true
                AllowUserFormBrowserRendering            = $true
                MaxDataConnectionTimeout                 = 20000
                DefaultDataConnectionTimeout             = 10000
                MaxDataConnectionResponseSize            = 1500
                RequireSslForDataConnections             = $true
                AllowEmbeddedSqlForDataConnections       = $false
                AllowUdcAuthenticationForDataConnections = $false
                AllowUserFormCrossDomainDataConnections  = $false
                MaxPostbacksPerSession                   = 75
                MaxUserActionsPerPostback                = 200
                ActiveSessionsTimeout                    = 1440
                MaxSizeOfUserFormState                   = 4096
            }

            It "Should return true when the Test method is called" {
                Test-TargetResource @testParams | Should Be $true
            }

            It "Should return the proper MaxSizeOfUserFormState value" {
                (Get-TargetResource @testParams).MaxSizeOfUserFormState | Should be 4096
            }

            It "Should properly configure the InfoPath Forms Service" {
                Set-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
