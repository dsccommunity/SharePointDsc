function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase,

        [parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName
    )

    Write-Verbose -Message "Checking for local SP Farm"

    try {
        $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose -Message "Unable to detect local farm."
    }
        
    if ($null -eq $spFarm) {return @{ }}

    $returnValue = @{
        FarmName = $spFarm.Name
    }
    return $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase,

        [parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName
    )

    Write-Verbose -Message "Creating new configuration database"
    $params = $args[0]
    New-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                -DatabaseServer $params.DatabaseServer `
                                -Passphrase (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force) `
                                -FarmCredentials $params.FarmAccount `
                                -SkipRegisterAsDistributedCacheHost:$true `
                                -AdministrationContentDatabaseName $params.AdminContentDatabaseName
        
    Write-Verbose -Message "Installing help collection"
    Install-SPHelpCollection -All    

    Write-Verbose -Message "Initialising farm resource security"
    Initialize-SPResourceSecurity
    

    Write-Verbose -Message "Installing farm services"
    Install-SPService

    Write-Verbose -Message "Installing farm features"
    Install-SPFeature -AllExistingFeatures -Force
    
    Write-Verbose -Message "Creating Central Administration Website"
    New-SPCentralAdministration -Port 9999 -WindowsAuthProvider NTLM
    
    Write-Verbose -Message "Installing application content"
    Install-SPApplicationContent
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $FarmAccount,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase,

        [parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -FarmAccount $FarmAccount -InstallAccount $InstallAccount -Passphrase $Passphrase -AdminContentDatabaseName $AdminContentDatabaseName

    if ($result.Count -eq 0) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource

