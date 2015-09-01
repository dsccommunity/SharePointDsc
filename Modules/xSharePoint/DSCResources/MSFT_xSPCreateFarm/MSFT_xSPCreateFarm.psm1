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

        [parameter(Mandatory = $false)]
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

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
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
    return $result
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

        [parameter(Mandatory = $false)]
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
        
    if (-not $PSBoundParameters.ContainsKey("CentralAdministrationPort")) { $PSBoundParameters.Add("CentralAdministrationPort", 9999) }

    Write-Verbose -Message "Setting up new SharePoint farm"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $params = Rename-xSharePointParamValue -params $params -oldName "FarmConfigDatabaseName" -newName "DatabaseName"
        $params = Rename-xSharePointParamValue -params $params -oldName "FarmAccount" -newName "FarmCredentials"
        $params = Rename-xSharePointParamValue -params $params -oldName "AdminContentDatabaseName" -newName "AdministrationContentDatabaseName"
        $params.Passphrase = (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force)
        $params.Remove("InstallAccount")

        $caPort = $params.CentralAdministrationPort
        $params.Remove("CentralAdministrationPort")

        if (Test-Path -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.dll") {
            Write-Verbose -Message "Detected Version: SharePoint 2016"
            $params.Add("LocalServerRole", "Custom")
        } else {
            Write-Verbose -Message "Detected Version: SharePoint 2013"
        }

        New-SPConfigurationDatabase @params -SkipRegisterAsDistributedCacheHost:$true
        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures -Force
        New-SPCentralAdministration -Port $caPort -WindowsAuthProvider NTLM
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

        [parameter(Mandatory = $false)]
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
