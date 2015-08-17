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
        $AdminContentDatabaseName,

        [System.UInt32]
        $CentralAdministrationPort
    )

    Write-Verbose -Message "Checking for local SP Farm"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ScriptBlock {
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
    $result
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
        $AdminContentDatabaseName,

        [System.UInt32]
        $CentralAdministrationPort = 9999
    )

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount -ForceNewSession $true

    Write-Verbose -Message "Setting up farm"
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        if (Test-Path -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.dll") {
            Write-Verbose -Message "Version: SharePoint 2016"
    
            New-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                        -DatabaseServer $params.DatabaseServer `
                                        -Passphrase (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force) `
                                        -FarmCredentials $params.FarmAccount `
                                        -SkipRegisterAsDistributedCacheHost:$true `
                                        -LocalServerRole Custom `
                                        -AdministrationContentDatabaseName $params.AdminContentDatabaseName
        } else {
            Write-Verbose -Message "Version: SharePoint 2013"

            New-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                        -DatabaseServer $params.DatabaseServer `
                                        -Passphrase (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force) `
                                        -FarmCredentials $params.FarmAccount `
                                        -SkipRegisterAsDistributedCacheHost:$true `
                                        -AdministrationContentDatabaseName $params.AdminContentDatabaseName
        }

        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures -Force
        New-SPCentralAdministration -Port 9999 -WindowsAuthProvider NTLM
        Install-SPApplicationContent
    }
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
        $AdminContentDatabaseName,

        [System.UInt32]
        $CentralAdministrationPort = 9999
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -FarmAccount $FarmAccount -InstallAccount $InstallAccount -Passphrase $Passphrase -AdminContentDatabaseName $AdminContentDatabaseName -CentralAdministrationPort $CentralAdministrationPort

    if ($result.Count -eq 0) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource
