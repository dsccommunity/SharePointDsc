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

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase
    )

    Write-Verbose -Message "Checking for local SP Farm"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

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

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase,

        [System.UInt32]
        $WaitTime = 30,

        [System.UInt32]
        $WaitCount = 60
    )

    Write-Verbose -Message "Joining existing farm configuration database"

    if ($PSBoundParameters.WaitTime -eq $null) { $PSBoundParameters.Add("WaitTime", $WaitTime) }
    if ($PSBoundParameters.WaitCount -eq $null) { $PSBoundParameters.Add("WaitCount", $WaitCount) }

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

        $params = $args[0]
        $loopCount = 0

        $params = Rename-xSharePointParamValue -params $params -oldName "FarmConfigDatabaseName" -newName "DatabaseName"
        $params.Passphrase = (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force)
        $params.Remove("InstallAccount")

        $WaitTime = $params.WaitTime
        $params.Remove("WaitTime")
        $WaitCount = $params.WaitCount
        $params.Remove("WaitCount")

        if (Test-Path -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.dll") {
            Write-Verbose -Message "Detected Version: SharePoint 2016"
            $params.Add("LocalServerRole", "Custom")
        } else {
            Write-Verbose -Message "Detected Version: SharePoint 2013"
        }

        $success = $false
        while ($loopCount -le $WaitCount) {
            try
            {
                Connect-SPConfigurationDatabase @params -SkipRegisterAsDistributedCacheHost:$true 
                $loopCount = $WaitCount + 1
                $success = $true
            }
            catch
            {
                $loopCount = $loopCount + 1
                Start-Sleep -Seconds $WaitTime
            }
        }
        if ($success) {
            Install-SPHelpCollection -All
            Initialize-SPResourceSecurity
            Install-SPService
            Install-SPFeature -AllExistingFeatures -Force
            Install-SPApplicationContent
        }
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
        [parameter(Mandatory = $true)]
        [System.String]
        $FarmConfigDatabaseName,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [parameter(Mandatory = $true)]
        [System.String]
        $Passphrase,

        [System.UInt32]
        $WaitTime = 30,

        [System.UInt32]
        $WaitCount = 60
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -InstallAccount $InstallAccount -Passphrase $Passphrase
 
    if ($result.Count -eq 0) { return $false }
    return $true   
}


Export-ModuleMember -Function *-TargetResource

