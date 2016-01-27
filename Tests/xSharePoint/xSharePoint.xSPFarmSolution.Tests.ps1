[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_xSPFarmSolution"
Import-Module (Join-Path $RepoRoot "Modules\xSharePoint\DSCResources\$ModuleName\$ModuleName.psm1")

Describe "xSPFarmSolution" {
	
	InModuleScope $ModuleName {
	
		$testParams = @{
            Name = "MySolution.wsp"
            LiteralPath = "MySolution.wsp"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..).Path) "Modules\xSharePoint")

        Mock Invoke-xSharePointCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue

		Context "When the solution does not exist,"{

			$result = Get-TargetResource @testParams

			It "it returns version 0.0.0.0" {
				$result.Version | Should Be "0.0.0.0"
			}

			It "it returns false for deployed." {
				$result.Deployed | Should Be $false
			}

			It "it returns Absent for Ensure." {
				$result.Ensure | Should Be "Absent"
			}

			It "it returns an empty array for WebApplications." {
				$result.WebApplications.Count | Should Be 0
			}
		}

		Context "When the solution does exist,"{

			$result = Get-TargetResource @testParams

			It "it returns version ''" {
				$result.Version | Should BeNullOrEmpty
			}

			It "it returns true for deployed." {
				$result.Deployed | Should Be $true
			}

			It "it returns Present for Ensure." {
				$result.Ensure | Should Be "Present"
			}

			It "it returns an url of central administration for WebApplications." {
				$result.WebApplications[0] | Should Be "http://s3y7028:8383/"
			}
		}

		$desiredValues = @{
			Name            = "SomeSolution"
			LiteralPath     = "\\server\share\file.wsp"
			Deployed        = $true
			Ensure          = "Present"
			Version         = "1.0.0.0"
			WebApplications = @("http://app1", "http://app2")
		}

		Context "When the solution is installed properly"{
        
			$actualValues = @{
				Deployed        = $true
				Ensure          = "Present"
				Version         = "1.0.0.0"
				WebApplications = @("http://app1", "http://app2")
			}

			Mock Get-TargetResource { $actualValues }

			It "it returns true for specific web applications"{

				Test-TargetResource @desiredValues | should be $true
			}

			It "it returns true for all web applications"{
				$desiredValues.WebApplications = @()

				Test-TargetResource @desiredValues | should be $true 
			}

			It "it returns fals if not all web applicationsare deployed"{
				$desiredValues.WebApplications = @("http://app1", "http://app2", "http://app3")

				Test-TargetResource @desiredValues | should be $false 
			}
		}

		Context "When the solution does not exist"{
			$desiredValues = @{
				Name            = "SomeSolution"
				LiteralPath     = "\\server\share\file.wsp"
				Deployed        = $true
				Ensure          = "Present"
				Version         = "1.0.0.0"
				WebApplications = @("http://app1", "http://app2")
			}

			$actualValues = @{
				Name            = "SomeSolution"
				LiteralPath     = "\\server\share\file.wsp"
				Deployed        = $false
				Ensure          = "Absent"
				Version         = "0.0.0.0"
				WebApplications = @()
			}

			Mock Get--TargetResource { return $actualValues }
			Mock Invoke-xSharePointCommand { return [PSCustomObject]@{ Properties = @{ Version = "1.0.0.0"}; ContainsGlobalAssembly = $true} } -Verifiable

			It "Does something"{ 
				Set-SPFarmSolutionInformation @desiredValues
			}
		}
	}   
}