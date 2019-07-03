# Ignoring this because we need to generate a stub credential to run the tests here
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
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
    -SubModulePath "Modules\SharePointDsc.Util\SharePointDsc.Util.psm1" `
    -ExcludeInvokeHelper

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        Context -Name "Validate Get-SPDscAssemblyVersion" -Fixture {
            It "Should return the version number of a given executable" {
                $testPath = "C:\windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                Get-SPDscAssemblyVersion -PathToAssembly $testPath | Should Not Be 0
            }
        }

        Context -Name "Validate Invoke-SPDscCommand" -Fixture {

            Mock -CommandName Invoke-Command -MockWith {
                return $null
            }
            Mock -CommandName New-PSSession -MockWith {
                return $null
            }
            Mock -CommandName Get-PSSnapin -MockWith {
                return $null
            }
            Mock -CommandName Add-PSSnapin -MockWith {
                return $null
            }

            # The use of the '4>&1' operator is used to hide the verbose output from the
            # Invoke-SPDscCommand command in these tests as it is not necessary to Validate
            # the output of the tests.

            It "Should execute a command as the local run as user" {
                Invoke-SPDscCommand -ScriptBlock { return "value" } 4>&1
            }

            It "Should execute a command as the local run as user with additional arguments" {
                Invoke-SPDscCommand -ScriptBlock { return "value" } `
                    -Arguments @{ Something = "42" } 4>&1
            }

            It "Should execute a command as the specified InstallAccount user where it is different to the current user" {
                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential ("username", $mockPassword)
                Invoke-SPDscCommand -ScriptBlock { return "value" } `
                    -Credential $mockCredential 4>&1
            }

            It "Should throw an exception when the run as user is the same as the InstallAccount user" {
                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential ("$($Env:USERDOMAIN)\$($Env:USERNAME)", $mockPassword)
                { Invoke-SPDscCommand -ScriptBlock { return "value" } `
                        -Credential $mockCredential 4>&1 } | Should Throw
            }

            It "Should throw normal exceptions when triggered in the script block" {
                Mock -CommandName Invoke-Command -MockWith {
                    throw [Exception] "A random exception"
                }

                { Invoke-SPDscCommand -ScriptBlock { return "value" } 4>&1 } | Should Throw
            }

            It "Should throw normal exceptions when triggered in the script block using InstallAccount" {
                Mock -CommandName Invoke-Command -MockWith {
                    throw [Exception] "A random exception"
                }

                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential ("username", $mockPassword)
                { Invoke-SPDscCommand -ScriptBlock { return "value" } `
                        -Credential $mockCredential 4>&1 } | Should Throw
            }

            It "Should handle a SharePoint update conflict exception by rebooting the server to retry" {
                Mock -CommandName Invoke-Command -MockWith {
                    throw [Exception] "An update conflict has occurred, and you must re-try this action."
                }

                { Invoke-SPDscCommand -ScriptBlock { return "value" } 4>&1 } | Should Not Throw
            }

            It "Should handle a SharePoint update conflict exception by rebooting the server to retry using InstallAccount" {
                Mock -CommandName Invoke-Command -MockWith {
                    throw [Exception] "An update conflict has occurred, and you must re-try this action."
                }

                $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                $mockCredential = New-Object -TypeName System.Management.Automation.PSCredential ("username", $mockPassword)
                { Invoke-SPDscCommand -ScriptBlock { return "value" } `
                        -Credential $mockCredential 4>&1 } | Should Not Throw
            }
        }

        Context -Name "Validate Test-SPDscParameterState" -Fixture {
            It "Should return true for two identical tables" {
                $desired = @{ Example = "test" }
                Test-SPDscParameterState -CurrentValues $desired `
                    -DesiredValues $desired | Should Be $true
            }

            It "Should return false when a value is different" {
                $current = @{ Example = "something" }
                $desired = @{ Example = "test" }
                Test-SPDscParameterState -CurrentValues $current `
                    -DesiredValues $desired | Should Be $false
            }

            It "Should return false when a value is missing" {
                $current = @{ }
                $desired = @{ Example = "test" }
                Test-SPDscParameterState -CurrentValues $current `
                    -DesiredValues $desired | Should Be $false
            }

            It "Should return true when only a specified value matches, but other non-listed values do not" {
                $current = @{ Example = "test"; SecondExample = "true" }
                $desired = @{ Example = "test"; SecondExample = "false" }
                Test-SPDscParameterState -CurrentValues $current `
                    -DesiredValues $desired `
                    -ValuesToCheck @("Example") | Should Be $true
            }

            It "Should return false when only specified values do not match, but other non-listed values do " {
                $current = @{ Example = "test"; SecondExample = "true" }
                $desired = @{ Example = "test"; SecondExample = "false" }
                Test-SPDscParameterState -CurrentValues $current `
                    -DesiredValues $desired `
                    -ValuesToCheck @("SecondExample") | Should Be $false
            }

            It "Should return false when an empty array is used in the current values" {
                $current = @{ }
                $desired = @{ Example = "test"; SecondExample = "false" }
                Test-SPDscParameterState -CurrentValues $current `
                    -DesiredValues $desired | Should Be $false
            }
        }

        Context -Name "Validate Convert-SPDscADGroupIDToName" -Fixture {
            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.DirectoryServices.DirectoryEntry"
            } -MockWith { return @{
                    objectGUID = @{
                        Value = (New-Guid)
                    }
                } }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.DirectoryServices.DirectorySearcher"
            } -MockWith {
                $searcher = @{
                    SearchRoot       = $null
                    PageSize         = $null
                    Filter           = $null
                    SearchScope      = $null
                    PropertiesToLoad = (New-Object -TypeName "System.Collections.Generic.List[System.String]")
                }
                $searcher = $searcher | Add-Member -MemberType ScriptMethod `
                    -Name FindOne `
                    -Value {
                    $result = @{ }
                    $result = $result | Add-Member -MemberType ScriptMethod `
                        -Name GetDirectoryEntry `
                        -Value {
                        return @{
                            objectsid = @("item")
                        }
                    } -PassThru -Force
                    return $result
                } -PassThru -Force
                return $searcher
            }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.Security.Principal.SecurityIdentifier"
            } -MockWith {
                $sid = @{ }
                $sid = $sid | Add-Member -MemberType ScriptMethod `
                    -Name Translate `
                    -Value {
                    $returnVal = $global:SPDscGroupsToReturn[$global:SPDscSidCount]
                    $global:SPDscSidCount++
                    return $returnVal
                } -PassThru -Force
                return $sid
            }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.Security.Principal.NTAccount"
            } -MockWith {
                $sid = @{ }
                $sid = $sid | Add-Member -MemberType ScriptMethod `
                    -Name Translate `
                    -Value {
                    $returnVal = $global:SPDscSidsToReturn[$global:SPDscSidCount]
                    $global:SPDscSidCount++
                    return $returnVal
                } -PassThru -Force
                return $sid
            }

            It "should convert an ID to an AD domain name" {
                $global:SPDscGroupsToReturn = @("DOMAIN\Group 1")
                $global:SPDscSidsToReturn = @("example SID")
                $global:SPDscSidCount = 0
                Convert-SPDscADGroupIDToName -GroupId (New-Guid) | Should Be "DOMAIN\Group 1"
            }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.DirectoryServices.DirectorySearcher"
            } -MockWith {
                $searcher = @{
                    SearchRoot       = $null
                    PageSize         = $null
                    Filter           = $null
                    SearchScope      = $null
                    PropertiesToLoad = (New-Object -TypeName "System.Collections.Generic.List[System.String]")
                }
                $searcher = $searcher | Add-Member -MemberType ScriptMethod `
                    -Name FindOne `
                    -Value {
                    return $null
                } -PassThru -Force
                return $searcher
            }

            It "should throw an error if no result is found in AD" {
                $global:SPDscGroupsToReturn = @("DOMAIN\Group 1")
                $global:SPDscSidsToReturn = @("example SID")
                $global:SPDscSidCount = 0
                { Convert-SPDscADGroupIDToName -GroupId (New-Guid) } | Should Throw
            }
        }

        Context -Name "Validate Convert-SPDscADGroupNameToId" -Fixture {
            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.DirectoryServices.DirectoryEntry"
            } -MockWith { return @{
                    objectGUID = @{
                        Value = (New-Guid)
                    }
                } }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.DirectoryServices.DirectorySearcher"
            } -MockWith {
                $searcher = @{
                    SearchRoot       = $null
                    PageSize         = $null
                    Filter           = $null
                    SearchScope      = $null
                    PropertiesToLoad = (New-Object -TypeName "System.Collections.Generic.List[System.String]")
                }
                $searcher = $searcher | Add-Member -MemberType ScriptMethod `
                    -Name FindOne `
                    -Value {
                    $result = @{ }
                    $result = $result | Add-Member -MemberType ScriptMethod `
                        -Name GetDirectoryEntry `
                        -Value {
                        return @{
                            objectsid = @("item")
                        }
                    } -PassThru -Force
                    return $result
                } -PassThru -Force
                return $searcher
            }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.Security.Principal.SecurityIdentifier"
            } -MockWith {
                $sid = @{ }
                $sid = $sid | Add-Member -MemberType ScriptMethod `
                    -Name Translate `
                    -Value {
                    $returnVal = $global:SPDscGroupsToReturn[$global:SPDscSidCount]
                    $global:SPDscSidCount++
                    return $returnVal
                } -PassThru -Force
                return $sid
            }

            Mock -CommandName "New-Object" -ParameterFilter {
                $TypeName -eq "System.Security.Principal.NTAccount"
            } -MockWith {
                $sid = @{ }
                $sid = $sid | Add-Member -MemberType ScriptMethod `
                    -Name Translate `
                    -Value {
                    $returnVal = $global:SPDscSidsToReturn[$global:SPDscSidCount]
                    $global:SPDscSidCount++
                    return $returnVal
                } -PassThru -Force
                return $sid
            }

            It "should convert an AD domain name to an ID" {
                $global:SPDscGroupsToReturn = @("DOMAIN\Group 1")
                $global:SPDscSidsToReturn = @("example SID")
                $global:SPDscSidCount = 0
                Convert-SPDscADGroupIDToName -GroupId (New-Guid) | Should Not BeNullOrEmpty
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
