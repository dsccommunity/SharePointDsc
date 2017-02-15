[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] 
    $SharePointCmdletModule = (Join-Path -Path $PSScriptRoot `
                                         -ChildPath "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" `
                                         -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
                                -ChildPath "..\SharePointDsc.TestHarness.psm1" `
                                -Resolve)

$Global:SPDscHelper = New-SPDscUnitTestHelper -SharePointStubModule $SharePointCmdletModule `
                                              -DscResource "SPInstallPrereqs"

Describe -Name $Global:SPDscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:SPDscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:SPDscHelper.InitializeScript -NoNewScope

        # Initialize tests
        function New-SPDscMockPrereq
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [String]
                $Name
            )
            $object = New-Object -TypeName System.Object
            $object = $object | Add-Member -Type NoteProperty `
                                           -Name "DisplayName" `
                                           -Value $Name `
                                           -PassThru
            return $object
        }

        if ($null -eq (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)) 
        {
            function Get-WindowsFeature { }
        }
        if ($null -eq (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue)) 
        {
            function Install-WindowsFeature { }
        }

        # Mocks for all contexts   
         Mock -CommandName Get-ItemProperty -ParameterFilter { 
                $Path -eq "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" 
            } -MockWith {
                return @()
            }
        
        Mock -CommandName Get-ChildItem {
            $full = @{
                Version = "4.5.0.0"
                Release = "0"
                PSChildName = "Full"
            } 

           $client = @{
                Version = "4.5.0.0"
                Release = "0"
                PSChildName = "Client"
            } 

            $returnval = @($full, $client)
            $returnVal = $returnVal | Add-Member ScriptMethod GetValue { return 380000 } -PassThru
            return $returnval
        }

        Mock -CommandName Get-ItemProperty -ParameterFilter { 
            $Path -eq "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" 
        } -MockWith {
            return @()
        }

        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -CommandName Get-SPDscOSVersion -MockWith {
            return @{
                Major = 6
                Minor = 3
            }
        }

        Mock -CommandName Get-WindowsFeature -MockWith { 
            return @(@{ 
                Name = "ExampleFeature"
                Installed = $false
            }) 
        }

        # Test contexts
        Context -Name "Prerequisites are not installed but should be and are to be installed in online mode" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $true
                Ensure = "Present"
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                return @()
            } -ParameterFilter { $null -ne $Path }

            It "Should return absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should return false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Should call the prerequisite installer from the set method and records the need for a reboot" {
                Mock -CommandName Start-Process { return @{ ExitCode = 3010 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should call the prerequisite installer from the set method and a pending reboot is preventing it from running" {
                Mock -CommandName Start-Process { return @{ ExitCode = 1001 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should call the prerequisite installer from the set method and passes a successful installation" {
                Mock -CommandName Start-Process { return @{ ExitCode = 0 } }

                Set-TargetResource @testParams
                Assert-MockCalled Start-Process
            }

            It "Should call the prerequisite installer from the set method when the prerequisite installer is already running" {
                Mock -CommandName Start-Process { return @{ ExitCode = 1 } }

                { Set-TargetResource @testParams } | Should Throw "already running"
            }

            It "Should call the prerequisite installer from the set method and invalid arguments are passed to the installer" {
                Mock -CommandName Start-Process { return @{ ExitCode = 2 } }

                { Set-TargetResource @testParams } | Should Throw "Invalid command line parameters"
            }

            It "Should call the prerequisite installer from the set method and throws for unknown error codes" {
                Mock -CommandName Start-Process { return @{ ExitCode = -1 } }

                { Set-TargetResource @testParams } | Should Throw "unknown exit code"
            }
        }

        Context -Name "Prerequisites are installed and should be" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $true
                Ensure = "Present"
            }

            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15 {
                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" 
                    } -MockWith {
                        return @(
                            (New-SPDscMockPrereq -Name "Microsoft CCR and DSS Runtime 2008 R3"), 
                            (New-SPDscMockPrereq -Name "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"), 
                            (New-SPDscMockPrereq -Name "AppFabric 1.1 for Windows Server"), 
                            (New-SPDscMockPrereq -Name "WCF Data Services 5.6.0 Runtime"), 
                            (New-SPDscMockPrereq -Name "WCF Data Services 5.0 (for OData v3) Primary Components"), 
                            (New-SPDscMockPrereq -Name "Microsoft SQL Server 2008 R2 Native Client"), 
                            (New-SPDscMockPrereq -Name "Active Directory Rights Management Services Client 2.0"), 
                            (New-SPDscMockPrereq -Name "Microsoft Identity Extensions" )
                        )
                    }
                }
                16 {
                    Mock -CommandName Get-ItemProperty -ParameterFilter { 
                        $Path -eq "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" 
                    } -MockWith {
                        return @(
                            (New-SPDscMockPrereq -Name "Microsoft CCR and DSS Runtime 2008 R3"), 
                            (New-SPDscMockPrereq -Name "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"), 
                            (New-SPDscMockPrereq -Name "AppFabric 1.1 for Windows Server"), 
                            (New-SPDscMockPrereq -Name "WCF Data Services 5.6.0 Runtime"), 
                            (New-SPDscMockPrereq -Name "Microsoft ODBC Driver 11 for SQL Server"), 
                            (New-SPDscMockPrereq -Name "Microsoft Visual C++ 2012 x64 Minimum Runtime - 11.0.61030"), 
                            (New-SPDscMockPrereq -Name "Microsoft Visual C++ 2012 x64 Additional Runtime - 11.0.61030"), 
                            (New-SPDscMockPrereq -Name "Microsoft Visual C++ 2015 x64 Minimum Runtime - 14.0.23026"), 
                            (New-SPDscMockPrereq -Name "Microsoft Visual C++ 2015 x64 Additional Runtime - 14.0.23026"), 
                            (New-SPDscMockPrereq -Name "Microsoft SQL Server 2012 Native Client"), 
                            (New-SPDscMockPrereq -Name "Active Directory Rights Management Services Client 2.1"), 
                            (New-SPDscMockPrereq -Name "Microsoft Identity Extensions")
                        )
                    }
                }
                Default {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }

            Mock -CommandName Get-WindowsFeature -MockWith { 
                return @(@{ 
                    Name = "ExampleFeature"
                    Installed = $true
                }) 
            }
            
            It "Should return present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        if ($Global:SPDscHelper.CurrentStubBuildNumber.Major -eq 15)
        {
            Context -Name "Prerequisites are installed and should be (with SQL 2012 native client for SP2013)" -Fixture {
                $testParams = @{
                    InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                    OnlineMode = $true
                    Ensure = "Present"
                }

                Mock -CommandName Get-ItemProperty -ParameterFilter { 
                    $Path -eq "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" 
                } -MockWith {
                    return @(
                        (New-SPDscMockPrereq -Name "Microsoft CCR and DSS Runtime 2008 R3"), 
                        (New-SPDscMockPrereq -Name "Microsoft Sync Framework Runtime v1.0 SP1 (x64)"), 
                        (New-SPDscMockPrereq -Name "AppFabric 1.1 for Windows Server"), 
                        (New-SPDscMockPrereq -Name "WCF Data Services 5.6.0 Runtime"), 
                        (New-SPDscMockPrereq -Name "WCF Data Services 5.0 (for OData v3) Primary Components"), 
                        (New-SPDscMockPrereq -Name "Microsoft SQL Server 2012 Native Client"), 
                        (New-SPDscMockPrereq -Name "Active Directory Rights Management Services Client 2.0"), 
                        (New-SPDscMockPrereq -Name "Microsoft Identity Extensions")
                    )
                }

                Mock -CommandName Get-WindowsFeature -MockWith { 
                    return @(@{ 
                        Name = "ExampleFeature"
                        Installed = $true
                    }) 
                }

                It "Should return present from the get method" {
                    (Get-TargetResource @testParams).Ensure | Should Be "Present"
                }

                It "Should return true from the test method" {
                    Test-TargetResource @testParams | Should Be $true
                }
            }
        }
        
        Context -Name "Prerequisites are installed but should not be" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $true
                Ensure = "Absent"
            }

            It "Should throw an exception from the set method" {
                {Test-TargetResource @testParams} | Should Throw
            }

            It "Should throw an exception from the set method" {
                {Set-TargetResource @testParams} | Should Throw
            }
        }

        Context -Name "Prerequisites are not installed but should be and are to be installed in offline mode" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $false
                Ensure = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                return @()
            } -ParameterFilter { $null -ne $Path }

            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = 0 
                } 
            }
            Mock -CommandName Test-Path -MockWith { 
                return $true 
            }

            It "Should throw an exception in the set method if required parameters are not set" {
                {Set-TargetResource @testParams} | Should Throw
            }

            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15 {
                    $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
                }
                16 {
                    $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","KB3092423","WCFDataServices56","DotNetFx","MSVCRT11","MSVCRT14","ODBC")
                }
                Default {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }

            $requiredParams | ForEach-Object -Process {
                $testParams.Add($_, "C:\fake\value.exe")
            }

            It "does not throw an exception where the required parameters are included" {
                {Set-TargetResource @testParams} | Should Not Throw
            }
        }

        Context -Name "Prerequisites are not installed but should be and are to be installed in offline mode, but invalid paths have been passed" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $false
                Ensure = "Present"
            }

            Mock -CommandName Get-WindowsFeature -MockWith { 
                return @( @{ 
                    Name = "ExampleFeature"
                    Installed = $false 
                }) 
            }
            
            Mock -CommandName Get-ItemProperty -MockWith {
                return @()
            }

            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = 0 
                } 
            }
            Mock -CommandName Test-Path -MockWith { 
                return $false 
            }

            It "Should throw an exception in the set method if required parameters are not set" {
                {Set-TargetResource @testParams} | Should Throw
            }

            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15 {
                    $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
                }
                16 {
                    $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","KB3092423","WCFDataServices56","DotNetFx","MSVCRT11","MSVCRT14","ODBC")
                }
                Default {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }
            $requiredParams | ForEach-Object -Process {
                $testParams.Add($_, "C:\fake\value.exe")
            }

            It "does not throw an exception where the required parameters are included" {
                {Set-TargetResource @testParams} | Should Throw
            }
        }
        
        if ($majorBuildNumber -eq 15)
        {
            Context -Name "SharePoint 2013 is installing on a server with .NET 4.6" -Fixture {
                $testParams = @{
                    InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                    OnlineMode = $true
                    Ensure = "Present"
                }

                Mock -CommandName Get-ChildItem {
                $full = @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Full"
                    } 

                $client = @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Client"
                    } 

                    $returnval = @($full, $client)
                    $returnVal = $returnVal | Add-Member ScriptMethod GetValue { return 391000 } -PassThru
                    return $returnval
                }

                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.4600.1000"
                        }
                    }
                } -ParameterFilter { 
                    $Path -eq "C:\SPInstall\updates\svrsetup.dll"
                }
                
                It "throws an error in the set method" {
                    { Set-TargetResource @testParams } | Should Throw ("A known issue prevents installation of SharePoint 2013 on " + `
                                                                       "servers that have .NET 4.6 already installed")
                }
            }

            Context -Name "SharePoint 2013 is installing on a server with .NET 4.6 with compatibility update" {
                $testParams = @{
                    InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                    OnlineMode = $true
                    Ensure = "Present"
                }

                Mock -CommandName Get-ChildItem {
                $full = @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Full"
                    } 

                $client = @{
                        Version = "4.6.0.0"
                        Release = "0"
                        PSChildName = "Client"
                    } 

                    $returnval = @($full, $client)
                    $returnVal = $returnVal | Add-Member ScriptMethod GetValue { return 391000 } -PassThru
                    return $returnval
                }

                Mock -CommandName Get-ItemProperty -MockWith {
                    return @{
                        VersionInfo = @{
                            FileVersion = "15.0.4709.1000"
                        }
                    }
                } -ParameterFilter { 
                    $Path -eq "C:\SPInstall\updates\svrsetup.dll"
                }
                
                It "should install prereqs" {
                    Mock Start-Process { return @{ ExitCode = 0 } }
                    Mock Test-Path { return $true }

                    Set-TargetResource @testParams
                    Assert-MockCalled Start-Process -Scope It 
                }
            }
        }        
        
        Context -Name "Prerequisites are not installed but should be and are to be installed in offline mode, with SXSstore specified" -Fixture {
            $testParams = @{
                InstallerPath = "C:\SPInstall\Prerequisiteinstaller.exe"
                OnlineMode = $false
                SXSpath = "C:\SPInstall\SXS"
                Ensure = "Present"
            }

            Mock -CommandName Get-ItemProperty -MockWith {
                return @()
            }

            Mock -CommandName Start-Process -MockWith { 
                return @{ 
                    ExitCode = 0 
                } 
            }

            Mock -CommandName Test-Path -MockWith { 
                return $true 
            }

            switch ($Global:SPDscHelper.CurrentStubBuildNumber.Major)
            {
                15 {
                    $requiredParams = @("SQLNCli","PowerShell","NETFX","IDFX","Sync","AppFabric","IDFX11","MSIPCClient","WCFDataServices","KB2671763","WCFDataServices56")
                }
                16 {
                    $requiredParams = @("SQLNCli","Sync","AppFabric","IDFX11","MSIPCClient","KB3092423","WCFDataServices56","DotNetFx","MSVCRT11","MSVCRT14","ODBC")
                }
                Default {
                    throw [Exception] "A supported version of SharePoint was not used in testing"
                }
            }
            $requiredParams | ForEach-Object -Process {
                $testParams.Add($_, "C:\fake\value.exe")
            }

            It "installs required Windows features from specified path" {
                Mock -CommandName Install-WindowsFeature -MockWith { 
                    return @( @{ 
                        Name = "ExampleFeature" 
                        Success = $true 
                        RestartNeeded = "No"
                    })  
                }

                Set-TargetResource @testParams
                Assert-MockCalled Install-WindowsFeature 
            }
            
             It "feature install requires a reboot" {
                Mock -CommandName Install-WindowsFeature -MockWith { 
                    return @( @{ 
                        Name = "ExampleFeature" 
                        Success = $true 
                        RestartNeeded = "Yes"
                    })  
                }

                Set-TargetResource @testParams
                $global:DSCMachineStatus | Should Be 1 
            }
            
             It "feature install failure throws an error" {
                Mock -CommandName Install-WindowsFeature -MockWith { 
                    return @( @{ 
                        Name = "ExampleFeature" 
                        Success = $false 
                        RestartNeeded = "No"
                    })  
                }

                {Set-TargetResource @testParams} | should Throw "Error installing ExampleFeature"                
            }
        } 
    }
}

Invoke-Command -ScriptBlock $Global:SPDscHelper.CleanupScript -NoNewScope
