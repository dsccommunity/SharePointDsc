function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Checking for local SP Farm"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        try {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
        } catch {
            Write-Verbose -Message "Unable to detect local farm."
        }
        
        if ($null -eq $spFarm) {return @{ }}

        $configDb = Get-SPDatabase | Where-Object { $_.Name -eq $spFarm.Name -and $_.Type -eq "Configuration Database" }

        return @{
            FarmConfigDatabaseName = $spFarm.Name
            DatabaseServer = $configDb.Server.Name
            InstallAccount = $params.InstallAccount
            Passphrase = $params.Passphrase
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Joining existing farm configuration database"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $joinFarmArgs = @{
            DatabaseServer = $params.DatabaseServer
            DatabaseName = $params.FarmConfigDatabaseName
            Passphrase = (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force)
            SkipRegisterAsDistributedCacheHost = $true
        }
        
        switch((Get-xSharePointInstalledProductVersion).FileMajorPart) {
            15 {
                Write-Verbose -Message "Detected Version: SharePoint 2013"
            }
            16 {
                Write-Verbose -Message "Detected Version: SharePoint 2016"
                $joinFarmArgs.Add("LocalServerRole", "Custom")
            }
            Default {
                throw [Exception] "An unknown version of SharePoint (Major version $_) was detected. Only versions 15 (SharePoint 2013) or 16 (SharePoint 2016) are supported."
            }
        }

        Connect-SPConfigurationDatabase @joinFarmArgs
        Install-SPHelpCollection -All
        Initialize-SPResourceSecurity
        Install-SPService
        Install-SPFeature -AllExistingFeatures -Force 
        Install-SPApplicationContent
    }

    Write-Verbose -Message "Starting timer service"
    Start-Service -Name sptimerv4

    Write-Verbose -Message "Pausing for 5 minutes to allow the timer service to fully provision the server"
    Start-Sleep -Seconds 300
    Write-Verbose -Message "Join farm complete. Restarting computer to allow configuration to continue"

    $global:DSCMachineStatus = 1
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $FarmConfigDatabaseName,
        [parameter(Mandatory = $true)]  [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $Passphrase,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose "Checking for local farm presence"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("FarmConfigDatabaseName") 
}


Export-ModuleMember -Function *-TargetResource

