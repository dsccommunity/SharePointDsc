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

    Write-Verbose "Checking for local SP Farm"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

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

        [parameter(Mandatory = $true)]
        [System.String]
        $AdminContentDatabaseName
    )

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    Write-Verbose "Creating new configuration database"
    Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        New-SPConfigurationDatabase -DatabaseName $params.FarmConfigDatabaseName `
                                    -DatabaseServer $params.DatabaseServer `
                                    -Passphrase (ConvertTo-SecureString $params.Passphrase -AsPlainText -force) `
                                    -FarmCredentials $params.FarmAccount `
                                    -SkipRegisterAsDistributedCacheHost:$true `
                                    -AdministrationContentDatabaseName $params.AdminContentDatabaseName
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

    Write-Verbose "Creating Central Administration Website"
    Invoke-Command -Session $session -ScriptBlock {
        New-SPCentralAdministration -Port 9999 -WindowsAuthProvider NTLM
    }

    Write-Verbose "Installing application content"
    Invoke-Command -Session $session -ScriptBlock {
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
        $AdminContentDatabaseName
    )

    $result = Get-TargetResource -FarmConfigDatabaseName $FarmConfigDatabaseName -DatabaseServer $DatabaseServer -FarmAccount $FarmAccount -InstallAccount $InstallAccount -Passphrase $Passphrase -AdminContentDatabaseName $AdminContentDatabaseName

    if ($result.Count -eq 0) { return $false }
    return $true
}


Export-ModuleMember -Function *-TargetResource

