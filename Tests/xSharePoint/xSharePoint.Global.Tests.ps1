[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)
$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..).Path
Import-Module "$PSScriptRoot\xSharePoint.TestHelpers.psm1"

Describe 'xSharePoint whole of module tests' {

    $mofFiles = @(Get-ChildItem $RepoRoot -Recurse -Filter "*.schema.mof" -File | ? {
        ($_.FullName -like "*\DscResources\*")
    })
    
    Context "Validate the MOF schemas for the DSC resources" {

        It "should not list InstallAccount as required if it does have that attribute" {
            $mofFilesWithNoInstallAccount = 0
            $mofFiles | ForEach-Object {
                $fileHasInstallAccount = $false

                $mofSchema = Get-MofSchemaObject $_.FullName
                $installAccount = $mofSchema.Attributes | Where-Object { $_.Name -eq "InstallAccount" }
                if (($null -ne $installAccount) -and ($installAccount.State -eq "Required")) {
                    $mofFilesWithNoInstallAccount += 1
                    Write-Warning "File $($_.FullName) has InstallAccount listed as a required parameter. After v0.6 of xSharePoint this should be changed to 'write' instead of 'required'"
                }
            }
            $mofFilesWithNoInstallAccount | Should Be 0
        }

        It "uses MOF schemas that match the functions used in the corresponding PowerShell module for each resource" {
            $filesWithErrors = 0
            $WarningPreference = "Continue"
            $mofFiles | % {
                if ((Assert-MofSchemaScriptParameters $_.FullName) -eq $false) { $filesWithErrors++ }
            }
            $filesWithErrors | Should Be 0
        }
    }

    $DSCTestsPath = (Get-Item (Join-Path $RepoRoot "..\**\DSCResource.Tests\MetaFixers.psm1" -Resolve)).FullName
    if ($null -ne $DSCTestsPath) {
        Import-Module $DSCTestsPath
        Context "Validate the format and structure of all text files in the module" {

            $allTextFiles = Get-TextFilesList $RepoRoot

            It "has no files that aren't in UTF-8 encoding" {
                $unicodeFilesCount = 0
                $allTextFiles | %{
                    if (Test-FileUnicode $_) {
                        $unicodeFilesCount += 1
                        Write-Warning "File $($_.FullName) contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8. Use Fixer 'Get-UnicodeFilesList `$pwd | ConvertTo-UTF8'."
                    }
                }
                $unicodeFilesCount | Should Be 0
            }

            It "has no files with tabs in the content" {
                $totalTabsCount = 0
                $allTextFiles | %{
                    $fileName = $_.FullName
                    $tabStrings = (cat $_.FullName -Raw) | Select-String "`t" | % {
                        Write-Warning "There are tab in $fileName. Use Fixer 'Get-TextFilesList `$pwd | ConvertTo-SpaceIndentation'."
                        $totalTabsCount++
                    }
                }
                $totalTabsCount | Should Be 0
            }
        }
    }

    Context "Validate the PowerShell modules used throughout the module" {
        $psm1Files = @(ls $RepoRoot -Recurse -Filter "*.psm1" -File | ? {
            ($_.FullName -like "*\DscResources\*" -or  $_.FullName -like "*\Modules\xSharePoint.*") -and (-not ($_.Name -like "*.schema.psm1"))
        })

        It 'has valid PowerShell syntax in all module files' {
            $errors = @()
            $psm1Files | ForEach-Object { 
                $localErrors = Get-ParseErrors $_.FullName
                if ($localErrors) {
                    Write-Warning "There are parsing errors in $($_.FullName)"
                    Write-Warning ($localErrors | Format-List | Out-String)
                }
                $errors += $localErrors
            }
            $errors.Count | Should Be 0
        }
    }
}