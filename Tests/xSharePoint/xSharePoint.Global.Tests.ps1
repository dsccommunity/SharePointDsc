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

    Context 'Files have valid text structure' {
        It 'Passes test file checks for DSC resources' {
            $DSCTestsPath = (Get-Item (Join-Path $RepoRoot "..\**\DSCResource.Tests\TestHelper.psm1" -Resolve)).FullName
            if ($null -ne $DSCTestsPath) {

            }
        }
    }
}

$DSCTestsPath = (Get-Item (Join-Path $RepoRoot "..\**\DSCResource.Tests\MetaFixers.psm1" -Resolve)).FullName
if ($null -ne $DSCTestsPath) {
    Import-Module $DSCTestsPath

    Describe 'Text files formatting' {
        $allTextFiles = Get-TextFilesList $RepoRoot
    
        Context 'Files encoding' {

            It "Doesn't use Unicode encoding" {
                $unicodeFilesCount = 0
                $allTextFiles | %{
                    if (Test-FileUnicode $_) {
                        $unicodeFilesCount += 1
                        Write-Warning "File $($_.FullName) contains 0x00 bytes. It's probably uses Unicode and need to be converted to UTF-8. Use Fixer 'Get-UnicodeFilesList `$pwd | ConvertTo-UTF8'."
                    }
                }
                $unicodeFilesCount | Should Be 0
            }
        }

        Context 'Indentations' {

            It "Uses spaces for indentation, not tabs" {
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
}


Describe 'PowerShell DSC resource modules' {
    
    # Force convert to array
    $psm1Files = @(ls $RepoRoot -Recurse -Filter "*.psm1" -File | ? {
        # Ignore Composite configurations
        # They requires additional resources to be installed on the box
        ($_.FullName -like "*\DscResources\*") -and (-not ($_.Name -like "*.schema.psm1"))
    })

    if (-not $psm1Files) {
        Write-Verbose -Verbose "There are no resource files to analyze"
    } else {

        Write-Verbose -Verbose "Analyzing $($psm1Files.Count) files"

        Context 'Correctness' {

            function Get-ParseErrors
            {
                param(
                    [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
                    [string]$fileName
                )    

                $tokens = $null 
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($fileName, [ref] $tokens, [ref] $errors)
                return $errors
            }


            It 'all .psm1 files don''t have parse errors' {
                $errors = @()
                $psm1Files | %{ 
                    $localErrors = Get-ParseErrors $_.FullName
                    if ($localErrors) {
                        Write-Warning "There are parsing errors in $($_.FullName)"
                        Write-Warning ($localErrors | fl | Out-String)
                    }
                    $errors += $localErrors
                }
                $errors.Count | Should Be 0
            }
        }
    }
}

