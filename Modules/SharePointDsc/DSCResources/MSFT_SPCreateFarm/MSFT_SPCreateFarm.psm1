function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [Parameter()] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [Parameter()] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )

    Write-Verbose -Message "Getting local SP Farm settings"

    throw ("SPCreateFarm: This resource has been removed. Please update your configuration " + `
           "to use SPFarm instead. See http://aka.ms/SPDsc-SPFarm for details.")
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [Parameter()] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [Parameter()] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )
    
    Write-Verbose -Message ("WARNING! SPCreateFarm is deprecated and will be removed in " + `
                            "SharePointDsc v2.0. Swap to use the new SPFarm resource as " + `
                            "an alternative. See http://aka.ms/SPDsc-SPFarm for details.")

    Write-Verbose -Message "Setting local SP Farm settings"

    throw ("SPCreateFarm: This resource has been removed. Please update your configuration " + `
           "to use SPFarm instead. See http://aka.ms/SPDsc-SPFarm for details.")
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]  
        [System.String] 
        $FarmConfigDatabaseName,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseServer,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $FarmAccount,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

        [Parameter(Mandatory = $true)]  
        [System.Management.Automation.PSCredential] 
        $Passphrase,

        [Parameter(Mandatory = $true)]  
        [System.String] 
        $AdminContentDatabaseName,

        [Parameter()] 
        [System.UInt32] 
        $CentralAdministrationPort,

        [Parameter()] 
        [System.String] 
        [ValidateSet("NTLM","Kerberos")]
        $CentralAdministrationAuth,

        [Parameter()] 
        [System.String] 
        [ValidateSet("Application",
                     "ApplicationWithSearch",
                     "Custom",
                     "DistributedCache",
                     "Search",
                     "SingleServer",
                     "SingleServerFarm",
                     "WebFrontEnd",
                     "WebFrontEndWithDistributedCache")] 
        $ServerRole
    )

    Write-Verbose -Message "Testing local SP Farm settings"

    throw ("SPCreateFarm: This resource has been removed. Please update your configuration " + `
           "to use SPFarm instead. See http://aka.ms/SPDsc-SPFarm for details.")
}

Export-ModuleMember -Function *-TargetResource
