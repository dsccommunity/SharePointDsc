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
        $Passphrase
    )

    Write-Verbose -Message "Checking for local SP Farm"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount -ForceNewSession $true

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

        [System.UInt32]
        $WaitTime = 30,

        [System.UInt32]
        $WaitCount = 60
    )

    Write-Verbose -Message "Joining existing farm configuration database"
    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount -ForceNewSession $true
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $loopCount = 0    

        while ($loopCount -le $WaitCount) {
            try
            {
                Connect-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                                -DatabaseServer $params.DatabaseServer `
                                                -Passphrase (ConvertTo-SecureString -String $params.Passphrase -AsPlainText -force) `
                                                -SkipRegisterAsDistributedCacheHost:$true 
                $loopCount = $WaitCount + 1
            }
            catch
            {
                $loopCount = $loopCount + 1
                Start-Sleep -Seconds $WaitTime
            }
        }
    }

    Write-Verbose -Message "Installing help collection"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPHelpCollection -All
    }

    Write-Verbose -Message "Initialising farm resource security"
    Invoke-Command -Session $session -ScriptBlock {
        Initialize-SPResourceSecurity
    }

    Write-Verbose -Message "Installing farm services"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPService
    }

    Write-Verbose -Message "Installing farm features"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPFeature -AllExistingFeatures -Force
    }

    Write-Verbose -Message "Installing application content"
    Invoke-Command -Session $session -ScriptBlock {
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

        [System.UInt32]
        $WaitTime = 30,

        [System.UInt32]
        $WaitCount = 60
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -FarmAccount $FarmAccount -InstallAccount $InstallAccount -Passphrase $Passphrase
 
    if ($result.Count -eq 0) { return $false }
    return $true   
}


Export-ModuleMember -Function *-TargetResource

