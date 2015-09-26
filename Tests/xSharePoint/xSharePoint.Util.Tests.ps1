[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

$ModuleName = "xSharePoint.Util"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint")

Describe "xSharePoint.Util" {
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

        It "Returns false when an empty array is used in the current values " {
            $current = @{ }
            $desired = @{ Example = "test"; SecondExample = "false"  }
            Test-xSharePointSpecificParameters -CurrentValues $current -DesiredValues $desired | Should Be $false
        }
    }
}