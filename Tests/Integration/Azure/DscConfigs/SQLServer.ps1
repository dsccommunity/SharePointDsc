Configuration SQLServer
{
    param(
        [Parameter(Mandatory=$true)] 
		[ValidateNotNullorEmpty()] 
		[PSCredential] 
		$DomainAdminCredential,

        [Parameter(Mandatory=$true)] 
		[ValidateNotNullorEmpty()] 
		[PSCredential] 
		$SqlServiceAccount
    )

    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.0.1
    Import-DscResource -ModuleName xComputerManagement -ModuleVersion 1.9.0.0
	Import-DscResource -ModuleName xNetworking -ModuleVersion 3.2.0.0
    Import-DscResource -ModuleName xSQLServer -ModuleVersion 5.0.0.0

    node localhost
    {
        Registry DisableIPv6 
        {
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
            ValueName = "DisabledComponents"
            ValueData = "ff"
            ValueType = "Dword"
            Hex       = $true
            Ensure    = 'Present'
        }

        xComputer DomainJoin
        {
            Name       = $env:COMPUTERNAME
            DomainName = "demo.lab"
            Credential = $DomainAdminCredential
            DependsOn  = "[Registry]DisableIPv6"
        }

        xCredSSP CredSSPServer 
        { 
            Ensure = "Present" 
            Role = "Server" 
        } 

        xCredSSP CredSSPClient 
        { 
            Ensure = "Present" 
            Role = "Client" 
            DelegateComputers = "*.demo.lab"
        }

		xFirewall SQLEngineFirewallRule
        {
            Name         = "SQLDatabaseEngine"
            DisplayName  = "SQL Server Database Engine"
            Group        = "SQL Server Rules"
            Ensure       = "Present"
            Action       = "Allow"
            Enabled      = "True"
            Profile      = ("Domain", "Private")
            Direction    = "Inbound"
            LocalPort    = ("1433", "1434")         
            Protocol     = "TCP"
            Description  = "SQL Database engine exception"  
        }

        xSQLServerLogin DomainAdminLogin
        {
            Name = "DEMO\Domain Admins"
            LoginType = "WindowsGroup"
            SQLServer = $env:COMPUTERNAME
            SQLInstanceName = "MSSQLSERVER"
            DependsOn = "[xComputer]DomainJoin"
        }

        xSQLServerRole DomainAdminsAdmin
        {
            Name = "DEMO\Domain Admins"
            Ensure = "Present"
            ServerRole = "sysadmin"
            SQLServer = $env:COMPUTERNAME
            SQLInstanceName = "MSSQLSERVER"
            DependsOn = "[xSQLServerLogin]DomainAdminLogin"
        }

        xSQLServerLogin SPSetupLogin
        {
            Name = "DEMO\svcSPSetup"
            LoginType = "WindowsUser"
            SQLServer = $env:COMPUTERNAME
            SQLInstanceName = "MSSQLSERVER"
            DependsOn = "[xComputer]DomainJoin"
        }

        xSQLServerRole SPSetupAdmin
        {
            Name = "DEMO\svcSPSetup"
            Ensure = "Present"
            SQLServer = $env:COMPUTERNAME
            SQLInstanceName = "MSSQLSERVER"
            ServerRole = "sysadmin"
            DependsOn = "[xSQLServerLogin]SPSetupLogin"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = "ContinueConfiguration"
        }
    }
}
