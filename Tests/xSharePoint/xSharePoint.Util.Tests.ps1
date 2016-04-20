[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")

Describe "xSharePoint.Util" {
    Context "Validate Get-xSharePointAssemblyVersion" {
        It "returns the version number of a given executable" {
            Get-xSharePointAssemblyVersion -PathToAssembly "C:\windows\System32\WindowsPowerShell\v1.0\powershell.exe" | Should Not Be 0
        }
    }

    Context "Validate Invoke-xSharePointCommand" {
        Mock Invoke-Command { return $null } -ModuleName "xSharePoint.Util"
        Mock New-PSSession { return $null } -ModuleName "xSharePoint.Util"
        Mock Get-PSSnapin { return $null } -ModuleName "xSharePoint.Util"
        Mock Add-PSSnapin { return $null } -ModuleName "xSharePoint.Util"

        It "executes a command as the local run as user" {
            Invoke-xSharePointCommand -ScriptBlock { return "value" } 
        }

        It "executes a command as the local run as user with additional arguments" {
            Invoke-xSharePointCommand -ScriptBlock { return "value" } -Arguments @{ Something = "42" }
        }

        It "executes a command as the specified InstallAccount user where it is different to the current user" {
            Invoke-xSharePointCommand -ScriptBlock { return "value" } -Credential (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))) 
        }

        It "throws an exception when the run as user is the same as the InstallAccount user" {
            { Invoke-xSharePointCommand -ScriptBlock { return "value" } -Credential (New-Object System.Management.Automation.PSCredential ("$($Env:USERDOMAIN)\$($Env:USERNAME)", (ConvertTo-SecureString "password" -AsPlainText -Force)))} | Should Throw
        }

        It "throws normal exceptions when triggered in the script block" {
            Mock Invoke-Command { throw [Exception] "A random exception" } -ModuleName "xSharePoint.Util"

            { Invoke-xSharePointCommand -ScriptBlock { return "value" } } | Should Throw
        }

        It "throws normal exceptions when triggered in the script block using InstallAccount" {
            Mock Invoke-Command { throw [Exception] "A random exception" } -ModuleName "xSharePoint.Util"

            { Invoke-xSharePointCommand -ScriptBlock { return "value" } -Credential (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force)))} | Should Throw
        }

        It "handles a SharePoint update conflict exception by rebooting the server to retry" {
            Mock Invoke-Command { throw [Exception] "An update conflict has occurred, and you must re-try this action." } -ModuleName "xSharePoint.Util"

            { Invoke-xSharePointCommand -ScriptBlock { return "value" } } | Should Not Throw
        }

        It "handles a SharePoint update conflict exception by rebooting the server to retry using InstallAccount" {
            Mock Invoke-Command { throw [Exception] "An update conflict has occurred, and you must re-try this action." } -ModuleName "xSharePoint.Util"

            { Invoke-xSharePointCommand -ScriptBlock { return "value" } -Credential (New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force)))} | Should Not Throw
        }
    }

    Context "Validate Test-xSharePointSpecificParameters" {
        It "Returns true for two identical tables" {
            $desired = @{ Example = "test" }
            Test-xSharePointSpecificParameters -CurrentValues $desired -DesiredValues $desired | Should Be $true
        }

        It "Returns false when a value is different" {
            $current = @{ Example = "something" }
            $desired = @{ Example = "test" }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired | Should Be $false
        }

        It "Returns false when a value is missing" {
            $current = @{ }
            $desired = @{ Example = "test" }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired | Should Be $false
        }

        It "Returns true when only a specified value matches, but other non-listed values do not" {
            $current = @{ Example = "test"; SecondExample = "true" }
            $desired = @{ Example = "test"; SecondExample = "false"  }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired -ValuesToCheck @("Example") | Should Be $true
        }

        It "Returns false when only specified values do not match, but other non-listed values do " {
            $current = @{ Example = "test"; SecondExample = "true" }
            $desired = @{ Example = "test"; SecondExample = "false"  }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired -ValuesToCheck @("SecondExample") | Should Be $false
        }

        It "Returns false when an empty array is used in the current values" {
            $current = @{ }
            $desired = @{ Example = "test"; SecondExample = "false"  }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired | Should Be $false
        }
    }
}