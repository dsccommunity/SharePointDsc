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
        $Passphrase,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

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

    Write-Verbose -Message "Getting local farm presence"

    throw ("SPCreateFarm: This resource has been removed. Please update your configuration " + `
           "to use SPFarm instead. See http://aka.ms/SPDsc-SPFarm for details.")
}

function Set-TargetResource
{
    # Supressing the global variable use to allow passing DSC the reboot message
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
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
        $Passphrase,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

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

    Write-Verbose -Message "Setting local farm"

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
        $Passphrase,

        [Parameter()] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount,

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

    Write-Verbose -Message "Testing for local farm presence"

    throw ("SPCreateFarm: This resource has been removed. Please update your configuration " + `
           "to use SPFarm instead. See http://aka.ms/SPDsc-SPFarm for details.")
}

Export-ModuleMember -Function *-TargetResource
