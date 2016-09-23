[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest
$Script:spFarmAccount = $null
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

		# Mocking the Get-WmiObject cmdlet
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

		# Mocking the Get-SPDSCInstalledProductVersion cmdlet
		$productVersionInfo = New-Object -TypeName PSObject
		Add-Member -InputObject $productVersionInfo -MemberType NoteProperty -Name FileMajorPart -Value "16"
		Mock Get-SPDSCInstalledProductVersion { return $productVersionInfo } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPManagedPath cmdlet
		$managedPath = New-Object -TypeName PSObject
		Add-Member -InputObject $managedPath -MemberType NoteProperty -Name Name -Value "sites"
		Add-Member -InputObject $managedPath -MemberType NoteProperty -Name Type -Value "ExplicitInclusion"
		Mock Get-SPManagedPath { return $managedPath } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPManagedAccount cmdlet
		$managedAccount = New-Object -TypeName PSObject
		Add-Member -InputObject $managedAccount -MemberType NoteProperty -Name UserName -Value "contoso\sp_farm"
		Mock Get-SPManagedAccount { return $managedAccount } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPSite cmdlet
		$rootWeb = New-Object -TypeName PSObject
		Add-Member -InputObject $rootWeb -MemberType NoteProperty -Name Title -Value "Root Web"

		$spSite = New-Object -TypeName PSObject		
		Add-Member -InputObject $spSite -MemberType NoteProperty -Name RootWeb -Value $rootWeb
		Add-Member -InputObject $spSite -MemberType NoteProperty -Name Url -Value "http://contoso.com"

		Mock Get-SPSite { return $spSite } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPServiceApplicationPool cmdlet
		Mock Get-SPServiceApplicationPool { return $null } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPServiceInstance cmdlet
		Mock Get-SPServiceInstance { return $null } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPDiagnosticConfig cmdlet

		Mock Get-SPDiagnosticConfig { return $null } -ModuleName "SharePointDsc.Reverse"

		# Mocking the Get-SPUsageApplication
		Mock Get-SPUsageApplication { return $null } -ModuleName "SharePointDsc.Reverse"

		# Mokcing the Get-SPWebApplication cmdlet
		$spWebApp = New-Object -TypeName PSObject		
		Add-Member -InputObject $spWebApp -MemberType NoteProperty -Name Name -Value "Test Web Application"
		Add-Member -InputObject $spWebApp -MemberType NoteProperty -Name Url -Value "http://contoso.com"
		$webApps = @($spwebApp)
		Mock Get-SPWebApplication{return $webApps} -ModuleName "SharePointDSC.Reverse"

		# Mocking the Get-SPStateServiceApplication cmdlet
		Mock Get-SPStateServiceApplication { return $null } -ModuleName "SharePointDSC.Reverse"

		# Mocking the Get-SPServiceApplication cmdlet
		Mock Get-SPServiceApplication { return $null } -ModuleName "SharePointDSC.Reverse"

        It "Read information about the farm's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPCreateFarm\MSFT_SPCreateFarm.psm1")
			$testParams = @{
                FarmConfigDatabaseName = "SP_Config"
                DatabaseServer = "DatabaseServer\Instance"
                FarmAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
                Passphrase =  New-Object System.Management.Automation.PSCredential ("PASSPHRASEUSER", (ConvertTo-SecureString "MyFarmPassphrase" -AsPlainText -Force))
                AdminContentDatabaseName = "Admin_Content"
                CentralAdministrationAuth = "Kerberos"
                CentralAdministrationPort = 1234
				InstallAccount = New-Object System.Management.Automation.PSCredential ("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            }

            Read-SPFarm -params $testParams -modulePath $modulePath -ScriptBlock { return "value" }
			Set-ConfigurationSettings -ScriptBlock { return "value" }
        }

		It "Read information about the Web Applications' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPWebApplication\MSFT_SPWebApplication.psm1")	
			Read-SPWebApplications -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Paths' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedPath\MSFT_SPManagedPath.psm1")	
			Read-SPManagedPaths -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Accounts' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedAccount\MSFT_SPManagedAccount.psm1")
			Read-SPManagedAccounts -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Service Application Pools' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPServiceAppPool\MSFT_SPServiceAppPool.psm1")
			Read-SPServiceApplicationPools -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Site Collections' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSite\MSFT_SPSite.psm1")
			Read-SPSites -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Service Instances' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPServiceInstance\MSFT_SPServiceInstance.psm1")
			Read-SPServiceInstance -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Diagnostic Logging's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPDiagnosticLoggingSettings\MSFT_SPDiagnosticLoggingSettings.psm1")
			Read-DiagnosticLoggingSettings -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Usage Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPUsageApplication\MSFT_SPUsageApplication.psm1")
			Read-UsageServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the State Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPStateServiceApp\MSFT_SPStateServiceApp.psm1")
			Read-StateServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the User Profile Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPUserProfileServiceApp\MSFT_SPUserProfileServiceApp.psm1")
			Read-UserProfileServiceapplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Cache Accounts' configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPCacheAccounts\MSFT_SPCacheAccounts.psm1")
			Read-CacheAccounts -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Secure Store Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSecureStoreServiceApp\MSFT_SPSecureStoreServiceApp.psm1")
			Read-SecureStoreServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the BCS Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPBCSServiceApp\MSFT_SPBCSServiceApp.psm1")
			Read-BCSServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Search Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPSearchServiceApp\MSFT_SPSearchServiceApp.psm1")
			Read-SearchServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }

		It "Read information about the Managed Metadata Service Application's configuration" {
			$modulePath = (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\MSFT_SPManagedMetadataServiceApp\MSFT_SPManagedMetadataServiceApp.psm1")
			Read-ManagedMetadataServiceApplication -modulePath $modulePath -ScriptBlock { return "value" }
        }
    }
}
