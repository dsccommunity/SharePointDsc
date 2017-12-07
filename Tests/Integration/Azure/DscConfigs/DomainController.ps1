Configuration DomainController
{
    param(
        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PSCredential]
        $DomainAdminCredential,
        
        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PSCredential]
        $SafemodeAdministratorPassword,

        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PSCredential]
        $ServiceAccountCredential
    )
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion 2.16.0.0
    Import-DscResource -ModuleName xCredSSP -ModuleVersion 1.0.1
    Import-DscResource -ModuleName xDnsServer -ModuleVersion 1.7.0.0

    node localhost
    {
        $domainName = "demo.lab"

        xCredSSP CredSSPServer 
        {
            Ensure = "Present" 
            Role = "Server" 
        } 
        xCredSSP CredSSPClient 
        {
            Ensure = "Present" 
            Role = "Client" 
            DelegateComputers = "*.$domainName"
        } 

        @(
            "AD-Domain-Services", 
            "RSAT-ADDS", 
            "RSAT-AD-AdminCenter", 
            "RSAT-ADDS-Tools", 
            "RSAT-AD-PowerShell" 
        ) | ForEach-Object -Process {
            WindowsFeature "Feature-$_"
            {
                Ensure = "Present" 
                Name = $_
            }
        }
        
        xADDomain CreateDomain 
        {
            DomainName = $domainName
			DomainNetbiosName = $domainName.Substring(0, $domainName.IndexOf(".")).ToUpper()
            DomainAdministratorCredential = $DomainAdminCredential
            SafemodeAdministratorPassword = $SafemodeAdministratorPassword
            DependsOn = "[WindowsFeature]Feature-AD-Domain-Services" 
        }
        xWaitForADDomain DscForestWait 
        {
            DomainName = $domainName
            DomainUserCredential = $DomainAdminCredential 
            RetryCount = 20 
            RetryIntervalSec = 30 
            DependsOn = "[xADDomain]CreateDomain" 
        }

        $userAccounts = @(
            "svcSql",
            "svcSPSetup",
            "svcSPFarm",
            "svcSPWebApp",
            "svcSPSvcApp",
            "svcSPCrawl",
            "svcSPUPSync",
            "svcSPSuperUser",
            "svcSPReader"
        )

        $userAccounts | ForEach-Object -Process {
            xADUser "User-$_"
            {
                DomainName = $domainName
                DomainAdministratorCredential = $DomainAdminCredential 
                UserName = $_ 
                Password = $ServiceAccountCredential 
                Ensure = "Present" 
                DependsOn = "[xWaitForADDomain]DscForestWait" 
            }
        }

        xDnsARecord SPSitesDns
        {
            Name = "*.sharepoint"
            Target = "192.168.0.6"
            Zone = "demo.lab"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = "ContinueConfiguration"
        }
    }
}
