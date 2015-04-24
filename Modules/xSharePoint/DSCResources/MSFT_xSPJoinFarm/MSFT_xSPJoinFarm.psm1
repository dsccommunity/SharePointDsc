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

    Write-Verbose "Checking for local SP Farm"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount -ForceNewSession $true

    $result = Invoke-Command -Session $session -ScriptBlock {
        try {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
        } catch {}
        
        if ($spFarm -eq $null) {return @{ }}

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
        $WaitTime,

        [System.UInt32]
        $WaitCount
    )

    Write-Verbose "Joining existing farm configuration database"
    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount -ForceNewSession $true
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $WaitTime = 30
        $WaitCount = 60
        if ($PSBoundParameters.ContainsKey("WaitTime") -and $PSBoundParameters.WaitTime -gt 0) { $WaitTime = $PSBoundParameters.WaitTime } 
        if ($PSBoundParameters.ContainsKey("WaitCount") -and $PSBoundParameters.WaitCount -gt 0) { $WaitCount = $PSBoundParameters.WaitCount } 
        
        $loopCount = 0    

        while ($loopCount -le $WaitCount) {
            try
            {
                Connect-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                                -DatabaseServer $params.DatabaseServer `
                                                -Passphrase (ConvertTo-SecureString $params.Passphrase -AsPlainText -force) `
                                                -SkipRegisterAsDistributedCacheHost:$true 
                $loopCount = $WaitCount + 1
            }
            catch
            {
                $loopCount = $loopCount + 1
                Start-Sleep $WaitTime
            }
        }
    }

    Write-Verbose "Installing help collection"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPHelpCollection -All
    }

    Write-Verbose "Initialising farm resource security"
    Invoke-Command -Session $session -ScriptBlock {
        Initialize-SPResourceSecurity
    }

    Write-Verbose "Installing farm services"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPService
    }

    Write-Verbose "Installing farm features"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPFeature -AllExistingFeatures -Force
    }

    Write-Verbose "Installing application content"
    Invoke-Command -Session $session -ScriptBlock {
        Install-SPApplicationContent
    }

    Write-Verbose "Starting timer service"
    Start-Service sptimerv4
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
        $WaitTime,

        [System.UInt32]
        $WaitCount
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -FarmAccount $FarmAccount -InstallAccount $InstallAccount -Passphrase $Passphrase
 
    if ($result.Count -eq 0) { return $false }
    return $true   
}


Export-ModuleMember -Function *-TargetResource

