[CmdletBinding()]
param
(
    [Parameter()]
    [string]
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
            -Resolve)
)

$script:DSCModuleName = 'SharePointDsc'
$script:DSCResourceName = 'SPProductUpdate'
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
                # Write-Host $PSScriptRoot
                $Global:TestRegistryData = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot `
                        -ChildPath "SharePointDsc.SPProductUpdate.Tests.psd1" `
                        -Resolve)

                Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

                function Add-TestRegistryData
                {
                    param(
                        # Use Registry Values with an update
                        [Parameter(Mandatory = $true)]
                        [ValidateSet("RTM", "CU", "SP1")]
                        [System.String]
                        $PatchLevel,

                        # Use this Parameter to export only Office Reg Keys from TestRegistry
                        [Parameter]
                        [Switch]
                        $PrepDataForTests
                    )

                    $productVersion = 2013
                    if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
                    {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                        {
                            $productVersion = 2016
                        }
                        else
                        {
                            $productVersion = 2019
                        }
                    }

                    if ($productVersion -ne 2013 -and $PatchLevel -eq "SP1")
                    {
                        throw "Invalid Parameter Set. 'SP1' can only be used with SharePoint Server 2013. Server version was $productVersion"
                    }

                    $registryValuesToImport = @(
                        "Windows Registry Editor Version 5.00"
                    )
                    $registryValuesToImport += $Global:TestRegistryData["$($productVersion)"]["$($PatchLevel)"].Keys | ForEach-Object -Process {
                        return $Global:TestRegistryData["$($productVersion)"]["$($PatchLevel)"]["$($_)"]
                    }
                    $registryFileContent = $registryValuesToImport -join "`n`n"

                    $testRegistryPath = Get-Item "TestRegistry:\\"

                    $testDrivePath = Get-Item "TestDrive:\"

                    $tempFileName = "$($productVersion)_$($PatchLevel).reg"

                    $modifiedFileDestination = $(Join-Path $testDrivePath.FullName -ChildPath $tempFileName)
                    $registryFileContent.Replace("[HKEY_LOCAL_MACHINE\", "[$($testRegistryPath.Name)\HKEY_LOCAL_MACHINE\") | Out-File -FilePath $modifiedFileDestination

                    # Using Try/Catch because reg.exe generates a complete message that
                    # triggers an exception in the Azure DevOps pipeline.
                    try
                    {
                        reg import $modifiedFileDestination *>&1 | Out-Null
                    }
                    catch
                    {
                    }

                    if ($PrepDataForTests)
                    {
                        Get-ChildItem "Registry::$($testRegistryPath)\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" | Where-Object -FilterScript {
                            $_.PsPath -notlike "*00000000F01FEC"
                        } | Remove-Item -Confirm:$false -Force -Recurse

                        # Using Try/Catch because reg.exe generates a complete message that
                        # triggers an exception in the Azure DevOps pipeline.
                        try
                        {
                            reg export "$($testRegistryPath)\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products" "C:\temp\$($tempFileName)"  *>&1 | Out-Null
                        }
                        catch
                        {
                        }
                    }
                }

                # Mocks for all contexts
                Mock -CommandName Test-Path {
                    return $true
                }

                # Additional mock needed for fixing #1087
                Mock -CommandName Get-SPFarm {
                    return $true
                }

                Mock -CommandName Get-Service -MockWith {
                    $service = @{
                        Status = "Running"
                    }
                    $service = $service | Add-Member -MemberType ScriptMethod `
                        -Name Stop `
                        -Value {
                        return $null
                    } -PassThru
                    $service = $service | Add-Member -MemberType ScriptMethod `
                        -Name Start `
                        -Value {
                        return $null
                    } -PassThru
                    $service = $service | Add-Member -MemberType ScriptMethod `
                        -Name WaitForStatus `
                        -Value {
                        return $null
                    } -PassThru
                    return $service
                }

                Mock -CommandName Get-SPDscInstalledProductVersion {
                    return @{
                        FileMajorPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Major
                        FileBuildPart    = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                        ProductBuildPart = $Global:SPDscHelper.CurrentStubBuildNumber.Build
                    }
                }

                Mock -CommandName Set-Service {
                    return $null
                }

                Mock -CommandName Start-Process {
                    return @{
                        ExitCode = 0
                    }
                }

                Mock -CommandName Get-SPDscRegistryKey -MockWith {
                    if ($Value -eq "SetupType")
                    {
                        return "CLEAN_INSTALL"
                    }

                    if ($Value -eq "LanguagePackInstalled")
                    {
                        return 0
                    }
                }

                Mock -CommandName Get-SPDscFarmVersionInfo -MockWith {
                    return @{
                        Lowest = $Global:SPDscHelper.CurrentStubBuildNumber
                    }
                }

                Mock -CommandName Get-ChildItem -MockWith {
                    $getChildItemCmdlet = Get-Command Get-ChildItem -CommandType Cmdlet
                    return & $getChildItemCmdlet -Path "$($Path[0].Replace("Registry::HKEY_LOCAL_MACHINE", "TestRegistry:\HKEY_LOCAL_MACHINE"))"
                } -ParameterFilter {
                    $Path -and $Path.Length -eq 1 -and $Path[0].Contains("HKEY_LOCAL_MACHINE")
                }


                Mock -CommandName Get-ItemProperty -MockWith {
                    $getItemPropertyCmdlet = Get-Command Get-ItemProperty -CommandType Cmdlet
                    return & $getItemPropertyCmdlet -Path "$($Path[0].Replace("Registry::HKEY_LOCAL_MACHINE", "TestRegistry:\HKEY_LOCAL_MACHINE"))"
                } -ParameterFilter {
                    $Path -and $Path.Length -eq 1 -and $Path[0].Contains("HKEY_LOCAL_MACHINE")
                }

                Mock -CommandName Clear-ComObject -MockWith { }
            }

            # Test contexts
            Context -Name "Specified update file not found" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $false
                    }
                }

                It "Should return Absent from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Setup file cannot be found"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Specified update file is blocked" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Test-Path -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-Item -MockWith {
                        return "Zone data"
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "Setup file is blocked!"
                }
            }

            Context -Name "Ensure is set to Absent" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Absent"
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "SharePoint does not support uninstalling updates."
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePoint does not support uninstalling updates."
                }

                It "Should throw exception in the test method" {
                    { Test-TargetResource @testParams } | Should -Throw "SharePoint does not support uninstalling updates."
                }
            }

            Context -Name "Deploying CU to RTM, update executed successfully" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMarch2019\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "RTM"

                    Mock -CommandName Get-SPFarm {
                        throw
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            # 2013
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                # 2016
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4822"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "ubersrv2016-kb3115029-fullfile-x64-glb.exe"
                                }
                            }
                            else
                            {
                                # 2019
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "ubersrv2019-kb3115029-fullfile-x64-glb.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    # MockCalled set to 0, as there is no farm available.
                    Assert-MockCalled Get-Service -Exactly 0
                    Assert-MockCalled Start-Process
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Update CU has same version, update not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5119"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4882"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10342"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    Assert-MockCalled Get-ChildItem
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Update CU has lower version, update not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5075"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4705"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10340"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5119"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4882"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10342"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Present from the get method" {
                    $result = Get-TargetResource @testParams
                    Assert-MockCalled Get-ChildItem
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Update CU has higher version, update required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-Service -Exactly 6
                    Assert-MockCalled Start-Process
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            # 2016/2019 WSS Loc updates
            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 16)
            {
                Context -Name "WSS Loc Update CU has higher version, update required" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            SetupFile        = "C:\Install\CUMay2016\wssloc2019-kb4461514-fullfile-x64-glb.exe"
                            ShutdownServices = $true
                            Ensure           = "Present"
                        }

                        Add-TestRegistryData -PatchLevel "CU"

                        Mock -CommandName Get-ItemProperty -MockWith {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                # 2016
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Update for Microsoft SharePoint Enterprise Server 2016 (KB4092463) 64-Bit Edition"
                                    }
                                    Name        = "wssloc2016-kb4461514-fullfile-x64-glb.exe"
                                }
                            }
                            else
                            {
                                # 2019
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Update for Microsoft SharePoint Server 2019 Language Pack (KB4461514)"
                                    }
                                    Name        = "wssloc2019-kb4461514-fullfile-x64-glb.exe"
                                }
                            }
                        } -ParameterFilter {
                            $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                        }

                        $installerMock = New-Module -AsCustomObject -ScriptBlock {
                            function GetType
                            { # Installer
                                New-Module -AsCustomObject -ScriptBlock {
                                    function InvokeMember
                                    {
                                        New-Module -AsCustomObject -ScriptBlock {
                                            function GetType
                                            { # InstallerDB
                                                New-Module -AsCustomObject -ScriptBlock {
                                                    function InvokeMember
                                                    {
                                                        New-Module -AsCustomObject -ScriptBlock {
                                                            function GetType
                                                            { # DBView
                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                    function InvokeMember
                                                                    {
                                                                        param ($a, $b, $c, $d, $e)
                                                                        if ($a -eq "Fetch")
                                                                        {
                                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                                function GetType
                                                                                { # Value
                                                                                    New-Module -AsCustomObject -ScriptBlock {
                                                                                        function InvokeMember
                                                                                        {
                                                                                            param ($a, $b, $c, $d, $e)
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            return $null
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Export-ModuleMember -Variable * -Function *
                        }

                        Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                    }

                    It "Should return Ensure is Absent from the get method" {
                        $result = Get-TargetResource @testParams
                        $result.Ensure | Should -Be "Absent"
                    }

                    It "Should run the Start-Process function in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Start-Process
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }
                }
            }

            # Test 2013 SP1 install
            if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
            {
                Context -Name "Service Pack has same version, update not required" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                            ShutdownServices = $true
                            Ensure           = "Present"
                        }

                        Add-TestRegistryData -PatchLevel "SP1"

                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.4569"
                                    FileDescription = "Service Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        } -ParameterFilter {
                            $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                        }

                        $installerMock = New-Module -AsCustomObject -ScriptBlock {
                            function GetType
                            { # Installer
                                New-Module -AsCustomObject -ScriptBlock {
                                    function InvokeMember
                                    {
                                        New-Module -AsCustomObject -ScriptBlock {
                                            function GetType
                                            { # InstallerDB
                                                New-Module -AsCustomObject -ScriptBlock {
                                                    function InvokeMember
                                                    {
                                                        New-Module -AsCustomObject -ScriptBlock {
                                                            function GetType
                                                            { # DBView
                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                    function InvokeMember
                                                                    {
                                                                        param ($a, $b, $c, $d, $e)
                                                                        if ($a -eq "Fetch")
                                                                        {
                                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                                function GetType
                                                                                { # Value
                                                                                    New-Module -AsCustomObject -ScriptBlock {
                                                                                        function InvokeMember
                                                                                        {
                                                                                            param ($a, $b, $c, $d, $e)
                                                                                            return "15.0.4569"
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            return $null
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Export-ModuleMember -Variable * -Function *
                        }

                        Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                    }

                    It "Should return Ensure is Present from the get method" {
                        $result = Get-TargetResource @testParams
                        Assert-MockCalled Get-ChildItem
                        $result.Ensure | Should -Be "Present"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should -Be $true
                    }
                }

                Context -Name "Update CU has lower version than SP1, update not required" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                            ShutdownServices = $true
                            Ensure           = "Present"
                        }

                        Add-TestRegistryData -PatchLevel "SP1"

                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.4535"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        } -ParameterFilter {
                            $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                        }

                        $installerMock = New-Module -AsCustomObject -ScriptBlock {
                            function GetType
                            { # Installer
                                New-Module -AsCustomObject -ScriptBlock {
                                    function InvokeMember
                                    {
                                        New-Module -AsCustomObject -ScriptBlock {
                                            function GetType
                                            { # InstallerDB
                                                New-Module -AsCustomObject -ScriptBlock {
                                                    function InvokeMember
                                                    {
                                                        New-Module -AsCustomObject -ScriptBlock {
                                                            function GetType
                                                            { # DBView
                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                    function InvokeMember
                                                                    {
                                                                        param ($a, $b, $c, $d, $e)
                                                                        if ($a -eq "Fetch")
                                                                        {
                                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                                function GetType
                                                                                { # Value
                                                                                    New-Module -AsCustomObject -ScriptBlock {
                                                                                        function InvokeMember
                                                                                        {
                                                                                            param ($a, $b, $c, $d, $e)
                                                                                            return "15.0.4571"
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            return $null
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Export-ModuleMember -Variable * -Function *
                        }

                        Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                    }

                    It "Should return Ensure is Present from the get method" {
                        $result = Get-TargetResource @testParams
                        Assert-MockCalled Get-ChildItem
                        $result.Ensure | Should -Be "Present"
                    }

                    It "Should return true from the test method" {
                        Test-TargetResource @testParams | Should -Be $true
                    }
                }

                Context -Name "Update CU has higher version than SP1, update required" -Fixture {
                    BeforeAll {
                        $testParams = @{
                            SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                            ShutdownServices = $true
                            Ensure           = "Present"
                        }

                        Add-TestRegistryData -PatchLevel "CU"

                        Mock -CommandName Get-ItemProperty -MockWith {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        } -ParameterFilter {
                            $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                        }

                        $installerMock = New-Module -AsCustomObject -ScriptBlock {
                            function GetType
                            { # Installer
                                New-Module -AsCustomObject -ScriptBlock {
                                    function InvokeMember
                                    {
                                        New-Module -AsCustomObject -ScriptBlock {
                                            function GetType
                                            { # InstallerDB
                                                New-Module -AsCustomObject -ScriptBlock {
                                                    function InvokeMember
                                                    {
                                                        New-Module -AsCustomObject -ScriptBlock {
                                                            function GetType
                                                            { # DBView
                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                    function InvokeMember
                                                                    {
                                                                        param ($a, $b, $c, $d, $e)
                                                                        if ($a -eq "Fetch")
                                                                        {
                                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                                function GetType
                                                                                { # Value
                                                                                    New-Module -AsCustomObject -ScriptBlock {
                                                                                        function InvokeMember
                                                                                        {
                                                                                            param ($a, $b, $c, $d, $e)
                                                                                            return "15.0.4571"
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            return $null
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            Export-ModuleMember -Variable * -Function *
                        }

                        Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                    }

                    It "Should return Ensure is Absent from the get method" {
                        $result = Get-TargetResource @testParams
                        $result.Ensure | Should -Be "Absent"
                    }

                    It "Should run the Start-Process function in the set method" {
                        Set-TargetResource @testParams
                        Assert-MockCalled Start-Process
                    }

                    It "Should return false from the test method" {
                        Test-TargetResource @testParams | Should -Be $false
                    }
                }
            }

            Context -Name "Update CU has higher version, update required - Install from UNC path" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "\\server\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("\\server\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Update CU has higher version, update required - Install from CDROM" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-Item -MockWith {
                        return $null
                    }

                    Mock -CommandName Get-Volume -MockWith {
                        return @{
                            DriveType = "CD-ROM"
                        }
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Get-Item -Times 0
                    Assert-MockCalled Start-Process
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "Update CU has higher version, update required - Update requires reboot" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock -CommandName Start-Process {
                        return @{
                            ExitCode = 17022
                        }
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "Update CU has higher version, update required - Update failed" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "CU"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Cumulative Update"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Cumulative Update"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock -CommandName Start-Process {
                        return @{
                            ExitCode = 1
                        }
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should run the Start-Process function in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "SharePoint update install failed, exit code was 1"
                    Assert-MockCalled Start-Process
                }
            }

            Context -Name "SP for Language Pack is not installed, update required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "RTM"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.5119"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4882"
                                        FileDescription = "Service Pack Language Pack"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10342"
                                        FileDescription = "Service Pack Language Pack"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5075"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4705"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10340"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Absent"
                }

                It "Should run the Start-Process function in the set method" {
                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $false
                }
            }

            Context -Name "SP for Language Pack is installed, update not required" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Add-TestRegistryData -PatchLevel "RTM"

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.4420"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-en-us.exe"
                            }
                        }
                        else
                        {
                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.4351"
                                        FileDescription = "Service Pack Language Pack"
                                    }
                                    Name        = "serverlpksp2016-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                            else
                            {
                                return @{
                                    VersionInfo = @{
                                        FileVersion     = "16.0.10337"
                                        FileDescription = "Service Pack Language Pack"
                                    }
                                    Name        = "serverlpksp2019-kb2880554-fullfile-x64-en-us.exe"
                                }
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }

                    $installerMock = New-Module -AsCustomObject -ScriptBlock {
                        function GetType
                        { # Installer
                            New-Module -AsCustomObject -ScriptBlock {
                                function InvokeMember
                                {
                                    New-Module -AsCustomObject -ScriptBlock {
                                        function GetType
                                        { # InstallerDB
                                            New-Module -AsCustomObject -ScriptBlock {
                                                function InvokeMember
                                                {
                                                    New-Module -AsCustomObject -ScriptBlock {
                                                        function GetType
                                                        { # DBView
                                                            New-Module -AsCustomObject -ScriptBlock {
                                                                function InvokeMember
                                                                {
                                                                    param ($a, $b, $c, $d, $e)
                                                                    if ($a -eq "Fetch")
                                                                    {
                                                                        New-Module -AsCustomObject -ScriptBlock {
                                                                            function GetType
                                                                            { # Value
                                                                                New-Module -AsCustomObject -ScriptBlock {
                                                                                    function InvokeMember
                                                                                    {
                                                                                        param ($a, $b, $c, $d, $e)
                                                                                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                                                                                        {
                                                                                            return "15.0.5119"
                                                                                        }
                                                                                        else
                                                                                        {
                                                                                            if ($Global:SPDscHelper.CurrentStubBuildNumber.Build.ToString().Length -eq 4)
                                                                                            {
                                                                                                return "16.0.4882"
                                                                                            }
                                                                                            else
                                                                                            {
                                                                                                return "16.0.10342"
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        return $null
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Export-ModuleMember -Variable * -Function *
                    }

                    Mock New-Object { return $installerMock } -ParameterFilter { $ComObject -eq 'WindowsInstaller.Installer' }
                }

                It "Should return Ensure is Absent from the get method" {
                    $result = Get-TargetResource @testParams
                    $result.Ensure | Should -Be "Present"
                }

                It "Should return false from the test method" {
                    Test-TargetResource @testParams | Should -Be $true
                }
            }

            Context -Name "Update SP LP does not have language in the name, throws exception" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.8000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64.exe"
                            }
                        }
                        else
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "16.0.15000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2016-kb2880554-fullfile-x64.exe"
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Update does not contain the language code in the correct format."
                }
            }

            Context -Name "Update SP LP has unknown language in the name, throws exception" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.8000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-ab-yz.exe"
                            }
                        }
                        else
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "16.0.15000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2016-kb2880554-fullfile-x64-ab-yz.exe"
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Error while converting language information:"
                }
            }

            Context -Name "Update SP LP specified language is not installed, throws exception" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile        = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices = $true
                        Ensure           = "Present"
                    }

                    Mock -CommandName Get-ItemProperty -MockWith {
                        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "15.0.8000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2013-kb2880554-fullfile-x64-fr-fr.exe"
                            }
                        }
                        else
                        {
                            return @{
                                VersionInfo = @{
                                    FileVersion     = "16.0.15000"
                                    FileDescription = "Service Pack Language Pack"
                                }
                                Name        = "serverlpksp2016-kb2880554-fullfile-x64-fr-fr.exe"
                            }
                        }
                    } -ParameterFilter {
                        $Path -and $Path.Length -eq 1 -and $Path[0].StartsWith("C:\")
                    }
                }

                It "Should throw exception in the get method" {
                    { Get-TargetResource @testParams } | Should -Throw "Error: Product for language fr-fr is not found."
                }
            }

            Context -Name "BinaryInstallDays outside range" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "mon"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "BinaryInstallTime outside range" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00am to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should return null from the set method" {
                    Set-TargetResource @testParams | Should -BeNullOrEmpty
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, too many arguments" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "error 3:00am to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Time window incorrectly formatted."
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, incorrect start time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00xm to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting start time"
                }
            }

            Context -Name "BinaryInstallTime incorrectly formatted, incorrect end time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00am to 5:00xm"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error converting end time"
                }
            }

            Context -Name "BinaryInstallTime start time larger than end time" -Fixture {
                BeforeAll {
                    $testParams = @{
                        SetupFile         = "C:\Install\CUMay2016\ubersrv2013-kb3115029-fullfile-x64-glb.exe"
                        ShutdownServices  = $true
                        BinaryInstallDays = "sun"
                        BinaryInstallTime = "3:00pm to 5:00am"
                        Ensure            = "Present"
                    }

                    $testDate = Get-Date -Day 17 -Month 7 -Year 2016 -Hour 12 -Minute 00 -Second 00

                    Mock -CommandName Get-Date -MockWith {
                        return $testDate
                    }
                }

                It "Should throw exception in the set method" {
                    { Set-TargetResource @testParams } | Should -Throw "Error: Start time cannot be larger than end time"
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
