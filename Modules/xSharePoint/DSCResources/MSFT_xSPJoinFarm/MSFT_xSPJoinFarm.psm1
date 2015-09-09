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

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -ScriptBlock {
        try {
            $spFarm = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPFarm" -ErrorAction SilentlyContinue
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
        $params = $args[0]
        $loopCount = 0

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

        $WaitTime = $params.WaitTime
        $WaitCount = $params.WaitCount
		
        $success = $false
        while ($loopCount -le $WaitCount) {
            try
            {
                Invoke-xSharePointSPCmdlet -CmdletName "Connect-SPConfigurationDatabase" -Arguments $joinFarmArgs
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
			Invoke-xSharePointSPCmdlet -CmdletName "Install-SPHelpCollection" -Arguments @{ All = $true }
			Invoke-xSharePointSPCmdlet -CmdletName "Initialize-SPResourceSecurity"
			Invoke-xSharePointSPCmdlet -CmdletName "Install-SPService"
			Invoke-xSharePointSPCmdlet -CmdletName "Install-SPFeature" -Arguments @{ AllExistingFeatures = $true; Force = $true }
			Invoke-xSharePointSPCmdlet -CmdletName "Install-SPApplicationContent"
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

    $result = Get-TargetResource @PSBoundParameters
 
    if ($result.Count -eq 0) { return $false }
    return $true   
}


Export-ModuleMember -Function *-TargetResource

