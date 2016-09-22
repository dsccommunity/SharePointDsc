[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path

Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc") -Force
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\Modules\SharePointDsc.Reverse\SharePointDsc.Reverse.psm1") -Force

Describe "SharePointDsc.Reverse - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {	

    Context "Validate Environment Data Extract" {
        Mock Invoke-Command { return $null } -ModuleName "SharePointDsc.Reverse"
        Mock New-PSSession { return $null } -ModuleName "SharePointDsc.Reverse"
        Mock Get-PSSnapin { return $null } -ModuleName "SharePointDsc.Reverse"
        Mock Add-PSSnapin { return $null } -ModuleName "SharePointDsc.Reverse"
		Mock Get-Credential { return $null } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPServer cmdlet
		$wfe1 = New-Object -TypeName PSObject
		Add-Member -InputObject $wfe1 -MemberType NoteProperty -Name Name -Value "SPWFE1"

		$wfe2 = New-Object -TypeName PSObject
		Add-Member -InputObject $wfe2 -MemberType NoteProperty -Name Name -Value "SPWFE2"

		$servers = @($wfe1, $wfe2)

		Mock Get-SPServer {return $servers} -ModuleName "SharePointDsc.Reverse"

		#Mocking the Get-WmiObject cmdlet
		$osInfo = New-Object -TypeName PSObject
		Add-Member -InputObject $osInfo -MemberType NoteProperty -Name OSName -Value "Windows Server 2012 R2"
		Add-Member -InputObject $osInfo -MemberType NoteProperty -Name OSArchitecture -Value "x64"
		Add-Member -InputObject $osInfo -MemberType NoteProperty -Name Version -Value "15.0.0.0"
		Mock Get-WmiObject {return $osInfo} -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPDatabase cmdlet
		Mock Get-SPDatabase { return $null } -ModuleName "SharePointDsc.Reverse"

        It "Read information about the Operating System" {
            Read-OperatingSystemVersion -ScriptBlock { return "value" } 
        }

        It "Read information about SQL Server" {
            Read-SQLVersion -ScriptBlock { return "value" }
        }

        It "Read information about the SharePoint version" {
            Read-SPProductVersions -ScriptBlock { return "value" }
        }        
    }

	Context "Validate Prerequisites for Reverse DSC script"{
		It "Read information about the required dependencies"{
			Set-Imports -ScriptBlock { return "value" }
		}
	}

    Context "Validate SharePoint Components Data Extract" {
		Mock Get-SPWebApplication{return "null"} -ModuleName "SharePointDSC.Reverse"

        It "Read information about the farm's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPCreateFarm\MSFT_SPCreateFarm.psm1")
			Write-Host $modulePath -BackgroundColor DarkMagenta
            Read-SPFarm -modulePath $modulePath -ScriptBlock { return "value" }
			Set-ConfigurationSettings -ScriptBlock { return "value" }
        }

		It "Read information about the Web Applications' configuration" {
			Read-SPWebApplications -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Paths' configuration" {
			Read-SPManagedPaths -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Accounts' configuration" {
			Read-SPManagedAccounts -ScriptBlock { return "value" }
        }

		It "Read information about the Service Application Pools' configuration" {
			Read-SPServiceApplicationPools -ScriptBlock { return "value" }
        }

		It "Read information about the Site Collections' configuration" {
			Read-SPSites -ScriptBlock { return "value" }
        }

		It "Read information about the Service Instances' configuration" {
			Read-SPServiceInstance -ScriptBlock { return "value" }
        }

		It "Read information about the Diagnostic Logging's configuration" {
			Read-DiagnosticLoggingSettings -ScriptBlock { return "value" }
        }

		It "Read information about the Usage Service Application's configuration" {
			Read-UsageServiceApplication -ScriptBlock { return "value" }
        }

		It "Read information about the State Service Application's configuration" {
			Read-StateServiceApplication -ScriptBlock { return "value" }
        }

		It "Read information about the User Profile Service Application's configuration" {
			Read-UserProfileServiceapplication -ScriptBlock { return "value" }
        }

		It "Read information about the Cache Accounts' configuration" {
			Read-CacheAccounts -ScriptBlock { return "value" }
        }

		It "Read information about the Secure Store Service Application's configuration" {
			Read-SecureStoreServiceApplication -ScriptBlock { return "value" }
        }

		It "Read information about the BCS Service Application's configuration" {
			Read-BCSServiceApplication -ScriptBlock { return "value" }
        }

		It "Read information about the Search Service Application's configuration" {
			Read-SearchServiceApplication -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Metadata Service Application's configuration" {
			Read-ManagedMetadataServiceApplication -ScriptBlock { return "value" }
        }
    }
}
