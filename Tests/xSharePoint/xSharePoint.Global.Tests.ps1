[CmdletBinding()]
param()

if (!$PSScriptRoot) # $PSScriptRoot is not defined in 2.0
{
    $PSScriptRoot = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path

Describe 'xSharePoint Global Tests' {

    $mofFiles = @(Get-ChildItem $RepoRoot -Recurse -Filter "*.schema.mof" -File | ? {
        ($_.FullName -like "*\DscResources\*")
    })
    
    Context 'MOF schemas use InstallAccount' {

        It "Doesn't have an InstallAccount required parameter" {
            $mofFilesWithNoInstallAccount = 0
			$mofFiles | % {
				$fileHasInstallAccount = $false
				Get-Content $_.FullName | % {
					if ($_.IndexOf("[Required, EmbeddedInstance(`"MSFT_Credential`")] String InstallAccount;") -gt 0) { $fileHasInstallAccount = $true }
				}
				if (-not $fileHasInstallAccount -and $_.Name -ne "MSFT_xSPInstall.schema.mof" `
	                                            -and $_.Name -ne "MSFT_xSPClearRemoteSessions.schema.mof" `
	                                            -and $_.Name -ne "MSFT_xSPInstallPrereqs.schema.mof") {
					$mofFilesWithNoInstallAccount += 1
					Write-Warning "File $($_.FullName) does not contain an InstallAccount parameter. All SharePoint specific resources should use this to impersonate as and access SharePoint resources"
				}
			}
			$mofFilesWithNoInstallAccount | Should Be 0
        }
    }
}