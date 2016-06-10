[CmdletBinding()]param()

$ErrorActionPreference = 'stop'
Set-StrictMode -Off

Describe -Tags @("Preflight") "xSharePoint Integration Tests - Preflight Check" {
    
    it "Includes all required service accounts" {
        $Global:xSPIntegrationCredPool.ContainsKey("Setup") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("Farm") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("WebApp") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("ServiceApp") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("SuperUser") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("SuperReader") | Should Be $true
        $Global:xSPIntegrationCredPool.ContainsKey("Crawler") | Should Be $true
    }

    it "is being run from a machine on the specified domain" {
        $env:USERDOMAIN | Should Be $global:xSPIntegrationGlobals.ActiveDirectory.NetbiosName
    }

    it "Has valid credentials for all service accounts" {
        $failedCredentials = $false
        $Global:xSPIntegrationCredPool.Keys | ForEach-Object {
            $cred = $Global:xSPIntegrationCredPool.$_
            $username = $cred.username
            $password = $cred.GetNetworkCredential().password
            $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
            $domain = New-Object System.DirectoryServices.DirectoryEntry("",$UserName,$Password)
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
            Invoke-Command -Credential $Global:xSPIntegrationCredPool.Setup -ComputerName . {
                $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                $SqlConnection.ConnectionString = "Server=$($Global:xSPIntegrationGlobals.SQL.DatabaseServer);Database=master;Trusted_Connection=True;"
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
            Import-DscResource -ModuleName xSharePoint
            node "localhost" {
                xSPInstallPrereqs PrereqCheck {
                    InstallerPath = (Join-Path $Global:xSPIntegrationGlobals.SharePoint.BinaryPath "prerequisiteinstaller.exe")
                    Ensure = "Present"
                    OnlineMode = $true
                    PsDscRunAsCredential = $RunAs
                }
            }
        }
        PrereqTest -ConfigurationData $global:xSPIntegrationConfigData -RunAs $Global:xSPIntegrationCredPool.Setup -OutputPath "TestDrive:\PrereqTest"
        (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\PrereqTest\localhost.mof").InDesiredState | Should be $true
    }

    it "Has the SharePoint installed" {
        Configuration InstallCheck {
            Import-DscResource -ModuleName xSharePoint
            node "localhost" {
                xSPInstall InstallCheck {
                    BinaryDir = $Global:xSPIntegrationGlobals.SharePoint.BinaryPath
                    Ensure = "Present"
                    ProductKey = "TestValueOnly"
                    PsDscRunAsCredential = $Global:xSPIntegrationCredPool.Setup
                }
            }
        }
        InstallCheck -ConfigurationData $global:xSPIntegrationConfigData -OutputPath "TestDrive:\InstallCheck\"
        (Test-DscConfiguration -ComputerName "localhost" -ReferenceConfiguration "TestDrive:\InstallCheck\localhost.mof").InDesiredState | Should be $true
    }
}
