[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPCacheAccounts"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPCacheAccounts" {
    InModuleScope $ModuleName {
        $testParams = @{
            WebAppUrl = "http://test.sharepoint.com"
            SuperUserAlias = "DEMO\SuperUser"
            SuperReaderAlias = "DEMO\SuperReader"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")
        
        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        try { [Microsoft.SharePoint.Administration.SPPolicyRoleType] }
        catch {
            Add-Type @"
namespace Microsoft.SharePoint.Administration {
    public enum SPPolicyRoleType { FullRead, FullControl, DenyWrite, DenyAll };
}        
"@
        }    
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        
        Mock New-SPClaimsPrincipal { 
            $Global:xSharePointClaimsPrincipalUser = $Identity
            return (
                New-Object Object | Add-Member ScriptMethod ToEncodedString { 
                    return "i:0#.w|$($Global:xSharePointClaimsPrincipalUser)" 
                } -PassThru
            )
        }
        
        Context "The web application specified does not exist" {
            Mock Get-SPWebApplication { return $null }

            It "returns empty values from the get method" {
                $results = Get-TargetResource @testParams
                $results.SuperUserAlias | Should BeNullOrEmpty
                $results.SuperReaderAlias | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws and exception where set is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context "The specified cache accounts have not been configured" {
            Mock Get-SPWebApplication { return New-Object Object |
                Add-Member NoteProperty Properties @{} -PassThru |
                Add-Member NoteProperty Policies (
                    New-Object Object |
                    Add-Member ScriptMethod Add { return New-Object Object |
                        Add-Member NoteProperty PolicyRoleBindings (
                            New-Object Object |
                            Add-Member ScriptMethod Add {} -PassThru
                        ) -PassThru
                    } -PassThru | 
                    Add-Member ScriptMethod Remove {} -PassThru
                ) -PassThru |
                Add-Member NoteProperty PolicyRoles (
                    New-Object Object |
                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                ) -PassThru |
                Add-Member ScriptMethod Update {} -PassThru
            }

            It "returns empty strings from the Get method" {
                $results = Get-TargetResource @testParams
                $results.SuperUserAlias | Should BeNullOrEmpty
                $results.SuperReaderAlias | Should BeNullOrEmpty
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Updates the accounts when set is called" {
                Set-TargetResource @testParams
            }
        }

        Context "The cache accounts have been configured correctly" {
            Mock Get-SPWebApplication { return New-Object Object |
                Add-Member NoteProperty Properties @{
                    portalsuperuseraccount = $testParams.SuperUserAlias
                    portalsuperreaderaccount = $testParams.SuperReaderAlias
                } -PassThru |
                Add-Member NoteProperty Policies @(
                        @{
                            UserName = $testParams.SuperUserAlias
                        },
                        @{
                            UserName = $testParams.SuperReaderAlias
                        },
                        @{
                            UserName = "i:0#.w|$($testParams.SuperUserAlias)"
                        },
                        @{
                            UserName = "i:0#.w|$($testParams.SuperReaderAlias)"
                        }
                    ) -PassThru |
                Add-Member NoteProperty PolicyRoles (
                    New-Object Object |
                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                ) -PassThru |
                Add-Member ScriptMethod Update {} -PassThru
            }

            It "returns the values from the get method" {
                $results = Get-TargetResource @testParams
                $results.SuperUserAlias | Should Not BeNullOrEmpty
                $results.SuperReaderAlias | Should Not BeNullOrEmpty
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "Cache accounts have been configured, but the reader account is wrong" {
            Mock Get-SPWebApplication { return New-Object Object |
                Add-Member NoteProperty Properties @{
                    portalsuperuseraccount = $testParams.SuperUserAlias
                    portalsuperreaderaccount = "WRONG\AccountName"
                } -PassThru |
                Add-Member NoteProperty Policies (
                    New-Object Object |
                    Add-Member ScriptMethod Add { return New-Object Object |
                        Add-Member NoteProperty PolicyRoleBindings (
                            New-Object Object |
                            Add-Member ScriptMethod Add {} -PassThru
                        ) -PassThru
                    } -PassThru | 
                    Add-Member ScriptMethod Remove {} -PassThru
                ) -PassThru |
                Add-Member NoteProperty PolicyRoles (
                    New-Object Object |
                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                ) -PassThru |
                Add-Member ScriptMethod Update {} -PassThru
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "sets the correct accounts to the web app again" {
                Set-TargetResource @testParams
            }
        }

        Context "Cache accounts have been configured, but the super account is wrong" {
            Mock Get-SPWebApplication { return New-Object Object |
                Add-Member NoteProperty Properties @{
                    portalsuperuseraccount = "WRONG\AccountName"
                    portalsuperreaderaccount = $testParams.SuperReaderAlias
                } -PassThru |
                Add-Member NoteProperty Policies (
                    New-Object Object |
                    Add-Member ScriptMethod Add { return New-Object Object |
                        Add-Member NoteProperty PolicyRoleBindings (
                            New-Object Object |
                            Add-Member ScriptMethod Add {} -PassThru
                        ) -PassThru
                    } -PassThru | 
                    Add-Member ScriptMethod Remove {} -PassThru
                ) -PassThru |
                Add-Member NoteProperty PolicyRoles (
                    New-Object Object |
                    Add-Member ScriptMethod GetSpecialRole { return @{} } -PassThru
                ) -PassThru |
                Add-Member ScriptMethod Update {} -PassThru
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "sets the correct accounts to the web app again" {
                Set-TargetResource @testParams
            }
        }
    }    
}