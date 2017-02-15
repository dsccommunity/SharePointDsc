[CmdletBinding()]param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Off

Describe -Tags @("Preflight") "SharePointDsc Integration Tests - Preflight Check" {
    
    It "Includes all required service accounts" {
        $Global:SPDscIntegrationCredPool.ContainsKey("Setup") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("Farm") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("WebApp") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("ServiceApp") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("SuperUser") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("SuperReader") | Should Be $true
        $Global:SPDscIntegrationCredPool.ContainsKey("Crawler") | Should Be $true
    }

    it "is being run from a machine on the specified domain" {
        $env:USERDOMAIN | Should Be $global:SPDscIntegrationGlobals.ActiveDirectory.NetbiosName
    }

    it "Has valid credentials for all service accounts" {
        $failedCredentials = $false
        $Global:SPDscIntegrationCredPool.Keys | ForEach-Object -Process {
            $cred = $Global:SPDscIntegrationCredPool.$_
            $username = $cred.username
            $password = $cred.GetNetworkCredential().password
            $domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("",$UserName,$Password)
            if ($domain.name -eq $null)
            {
                Write-Warning "Credential for $username is not valid"
                $failedCredentials = $true
            } 
        }
        $failedCredentials | Should Be $false
    }

    it "Can connect to SQL server using the setup credential" {

        { 
            Invoke-Command -Credential $Global:SPDscIntegrationCredPool.Setup -ComputerName . {
                $SqlConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
                $SqlConnection.ConnectionString = "Server=$($Global:SPDscIntegrationGlobals.SQL.DatabaseServer);Database=master;Trusted_Connection=True;"
                $SqlConnection.Open()
                $SqlConnection.Close()
            }
        } | Should Not Throw 
    }

    it "Has PowerShell 5 installed" {
        ($PSVersionTable.PSVersion.Major -ge 5) | Should Be $true
    }

    it "Has the SharePoint prerequisites installed" {
        Configuration PrereqTest {
            param([PSCredential] $RunAs)
            Import-DscResource -ModuleName SharePointDsc
            node "localhost" {
                SPInstallPrereqs PrereqCheck {
                    InstallerPath = (Join-Path $Global:SPDscIntegrationGlobals.SharePoint.BinaryPath "prerequisiteinstaller.exe")
                    Ensure = "Present"
                    OnlineMode = $true
                    PsDscRunAsCredential = $RunAs
                }
            }
        }
        PrereqTest -ConfigurationData $global:SPDscIntegrationConfigData -RunAs $Global:SPDscIntegrationCredPool.Setup -OutputPath "TestDrive:\PrereqTest"
        (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\PrereqTest\localhost.mof").InDesiredState | Should be $true
    }

    it "Has SharePoint installed" {
        Configuration InstallCheck {
            Import-DscResource -ModuleName SharePointDsc
            node "localhost" {
                SPInstall InstallCheck {
                    BinaryDir = $Global:SPDscIntegrationGlobals.SharePoint.BinaryPath
                    Ensure = "Present"
                    ProductKey = "TestValueOnly"
                    PsDscRunAsCredential = $Global:SPDscIntegrationCredPool.Setup
                }
            }
        }
        InstallCheck -ConfigurationData $global:SPDscIntegrationConfigData -OutputPath "TestDrive:\InstallCheck\"
        (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\InstallCheck\localhost.mof").InDesiredState | Should be $true
    }
}
