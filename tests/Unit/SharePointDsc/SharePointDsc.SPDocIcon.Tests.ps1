[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath '..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1' `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPDocIcon'
$script:DSCResourceFullName = 'MSFT_' + $script:DSCResourceName

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force

        Import-Module -Name (Join-Path -Path $PSScriptRoot `
                -ChildPath "..\UnitTestHelper.psm1" `
                -Resolve)

        $Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
            -DscResource $script:DSCResourceName
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:DSCModuleName `
        -DSCResourceName $script:DSCResourceFullName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope -ModuleName $script:DSCResourceFullName -ScriptBlock {
        Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
            BeforeAll {
                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                # Initialize tests
                $mockPassword = ConvertTo-SecureString -String 'password' -AsPlainText -Force
                $mockFarmAccount = New-Object -TypeName 'System.Management.Automation.PSCredential' `
                    -ArgumentList @('username', $mockPassword)
                $mockPassphrase = New-Object -TypeName "System.Management.Automation.PSCredential" `
                    -ArgumentList @('PASSPHRASEUSER', $mockPassword)

                try
                {
                    [Microsoft.SharePoint.Administration.SPDeveloperDashboardLevel]
                }
                catch
                {
                    Add-Type -TypeDefinition @"
    namespace Microsoft.SharePoint.Administration {
        public enum SPDeveloperDashboardLevel { On, OnDemand, Off };
    }
"@
                }

                # Mocks for all contexts
                function Add-SPDscEvent
                {
                    param
                    (
                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Message,

                        [Parameter(Mandatory = $true)]
                        [System.String]
                        $Source,

                        [Parameter()]
                        [ValidateSet('Error', 'Information', 'FailureAudit', 'SuccessAudit', 'Warning')]
                        [System.String]
                        $EntryType = 'Information',

                        [Parameter()]
                        [System.UInt32]
                        $EventID = 1
                    )
                }
            }

            # Test Contexts
            Context -Name "Ensure=Present, but the IconFile parameter is not specified" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should throw parameter validation exception in the Set method' {
                    { Set-TargetResource @testParams } | Should -Throw "When Ensure=Present, please also specify the IconFile parameter."
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Ensure=Present, but the specified IconFile does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should throw parameter validation exception in the Set method' {
                    { Set-TargetResource @testParams } | Should -Throw "Specified IconFile does not exist: $($testParams.IconFile)"
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Ensure=Present, but the docicon.xml file does not exist" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    } -ParameterFilter { $Path -eq $testParams.IconFile }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML\docicon.xml" }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should throw parameter validation exception in the Set method' {
                    { Set-TargetResource @testParams } | Should -Throw "Docicon.xml file is not found: C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML\docicon.xml"
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Ensure=Present, but resource is not in desired state: IconFile is not configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\IMAGES\icpdf.png" }

                    Mock -CommandName Copy-Item -MockWith {}

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should call the Copy-Item method once in the Set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Copy-Item
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Present, but resource is not in desired state: IconFile is not configured, does exist on disk but with incorrect hash" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-FileHash -MockWith {
                        return @{
                            Hash = "abcdefg"
                        }
                    }

                    Mock -CommandName Get-FileHash -MockWith {
                        return @{
                            Hash = "gfedcba"
                        }
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\IMAGES\icpdf.png" }

                    Mock -CommandName Copy-Item -MockWith {}

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should call the Get-FileHash method twice and the Copy-Item method once in the Set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-FileHash -Times 2
                    Assert-MockCalled -CommandName Copy-Item
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Present, but resource is not in desired state: IconFile is not configured and already exist on disk" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-FileHash -MockWith {
                        return @{
                            Hash = "abcdefg"
                        }
                    }

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should call the Get-FileHash method twice in the Set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Get-FileHash -Times 2
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Present, but resource is not in desired state: IconFile is incorrectly configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-FileHash -MockWith {
                        return @{
                            Hash = "abcdefg"
                        }
                    }

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    <Mapping Key="pdf" Value="icpdf.png" EditText="" OpenControl="" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Present from the Get method' {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                    $result.EditText | Should -BeNullOrEmpty
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should correct the docicon.xml in the Set method' {
                    Set-TargetResource @testParams
                    $dociconContent = Get-Content -Path $dociconFile -Raw
                    $dociconContent | Should -Be @"
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
  <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    <Mapping Key="pdf" Value="icpdf.png" EditText="Adobe Acrobat or Reader X" OpenControl="AdobeAcrobat.OpenDocuments" />
  </ByExtension>
  <Default>
    <Mapping Value="icgen.gif" />
  </Default>
</DocIcons>
"@
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Present and resource is in desired state" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType    = 'PDF'
                        IconFile    = '\\server\share\icpdf.png'
                        EditText    = 'Adobe Acrobat or Reader X'
                        OpenControl = 'AdobeAcrobat.OpenDocuments'
                        Ensure      = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-FileHash -MockWith {
                        return @{
                            Hash = "abcdefg"
                        }
                    }

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    <Mapping Key="pdf" Value="icpdf.png" EditText="Adobe Acrobat or Reader X" OpenControl="AdobeAcrobat.OpenDocuments" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Present from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It 'Should return true from the Test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Absent, but resource is not in desired state: IconFile is configured" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType = 'PDF'
                        Ensure   = "Absent"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Remove-Item -MockWith {}

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    <Mapping Key="pdf" Value="icpdf.png" EditText="Adobe Acrobat or Reader X" OpenControl="AdobeAcrobat.OpenDocuments" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@
                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Present from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Present"
                }

                It 'Should return false from the Test method' {
                    Test-TargetResource @testParams | Should -Be $false
                }

                It 'Should remove the FileType in the Set method' {
                    Set-TargetResource @testParams
                    Assert-MockCalled -CommandName Remove-Item
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Ensure=Absent and resource is in desired state" -Fixture {
                BeforeAll {
                    $testParams = @{
                        FileType = 'PDF'
                        Ensure   = "Absent"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="zip" Value="iczip.gif" OpenControl="" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@

                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }
                }

                It 'Should return Ensure=Absent from the Get method' {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It 'Should return true from the Test method' {
                    Test-TargetResource @testParams | Should -Be $true
                }

                AfterAll {
                    Remove-Item $dociconFile -Force
                }
            }

            Context -Name "Running ReverseDsc Export" -Fixture {
                BeforeAll {
                    Import-Module (Join-Path -Path (Split-Path -Path (Get-Module SharePointDsc -ListAvailable).Path -Parent) -ChildPath "Modules\SharePointDSC.Reverse\SharePointDSC.Reverse.psm1")

                    Mock -CommandName Write-Host -MockWith { }

                    Mock -CommandName Get-TargetResource -MockWith {
                        return @{
                            FileType    = 'pdf'
                            IconFile    = 'icpdf.gif'
                            EditText    = 'Adobe Acrobat or Reader X'
                            OpenControl = 'AdobeAcrobat.OpenDocuments'
                            Ensure      = "Present"
                        }
                    }

                    $dociconFile = "$($env:Temp)\docicon.xml"
                    Set-Content -Path $dociconFile -Value @'
<?xml version="1.0" encoding="utf-8"?>
<DocIcons>
    <ByExtension>
    <Mapping Key="pdf" Value="icpdf.png" EditText="Adobe Acrobat or Reader X" OpenControl="AdobeAcrobat.OpenDocuments" />
    </ByExtension>
    <Default>
    <Mapping Value="icgen.gif" />
    </Default>
</DocIcons>
'@

                    Mock -CommandName Join-Path -MockWith {
                        return $dociconFile
                    } -ParameterFilter { $Path -eq "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\$($Global:SPDscHelper.CurrentStubBuildNumber.Major)\TEMPLATE\XML" }

                    if ($null -eq (Get-Variable -Name 'spFarmAccount' -ErrorAction SilentlyContinue))
                    {
                        $mockPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force
                        $Global:spFarmAccount = New-Object -TypeName System.Management.Automation.PSCredential ("contoso\spfarm", $mockPassword)
                    }

                    if ($null -eq (Get-Variable -Name 'DynamicCompilation' -ErrorAction SilentlyContinue))
                    {
                        $DynamicCompilation = $false
                    }

                    if ($null -eq (Get-Variable -Name 'StandAlone' -ErrorAction SilentlyContinue))
                    {
                        $StandAlone = $true
                    }

                    if ($null -eq (Get-Variable -Name 'ExtractionModeValue' -ErrorAction SilentlyContinue))
                    {
                        $Global:ExtractionModeValue = 2
                        $Global:ComponentsToExtract = @('SPFarm')
                    }

                    $result = @'
        SPDocIcon DocIconpdf
        {
            EditText             = "Adobe Acrobat or Reader X";
            Ensure               = "Present";
            FileType             = "pdf";
            IconFile             = "$ConfigurationData.NonNodeData.DocIconpdf";
            OpenControl          = "AdobeAcrobat.OpenDocuments";
            PsDscRunAsCredential = $Credsspfarm;
        }

'@
                }

                It "Should return valid DSC block from the Export method" {
                    Export-TargetResource | Should -Be $result
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
