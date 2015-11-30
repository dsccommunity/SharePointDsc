function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Boolean] $AuditingEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $AuditlogMaxSize,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.Boolean] $PartitionMode,
        [parameter(Mandatory = $false)] [System.Boolean] $Sharing,
        [parameter(Mandatory = $false)] [ValidateSet("Windows", "SQL")] [System.String]  $DatabaseAuthenticationType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting secure store service application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue 
        if ($null -eq $serviceApps) { 
            return $null 
        }
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Secure Store Service Application" }

        If ($null -eq $serviceApp) { 
            return $null 
        } else {
            $returnVal =  @{
                Name = $serviceApp.DisplayName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                DatabaseName = $serviceApp.Database.Name
                DatabaseServer = $serviceApp.Database.Server.Name
                InstallAccount = $params.InstallAccount
            }
            return $returnVal
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Boolean] $AuditingEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $AuditlogMaxSize,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.Boolean] $PartitionMode,
        [parameter(Mandatory = $false)] [System.Boolean] $Sharing,
        [parameter(Mandatory = $false)] [ValidateSet("Windows", "SQL")] [System.String]  $DatabaseAuthenticationType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    $params = $PSBoundParameters

    if((($params.ContainsKey("DatabaseAuthenticationType") -eq $true) -and `
        ($params.ContainsKey("DatabaseCredentials") -eq $false)) -or `
        (($params.ContainsKey("DatabaseCredentials") -eq $true) -and `
        ($params.ContainsKey("DatabaseAuthenticationType") -eq $false))) {
        throw "Where DatabaseCredentials are specified you must also specify DatabaseAuthenticationType to identify the type of credentials being passed"
        return;
    }

    switch((Get-xSharePointInstalledProductVersion).FileMajorPart) {
        16 {
            $hasOptionalParams = $false
            @("AuditlogMaxSize","DatabaseName","DatabaseServer","FailoverDatabaseServer",`
                "PartitionMode","Sharing","DatabaseCredentials") | ForEach-Object {
                if ($PSBoundParameters.ContainsKey($_) -eq $true) { $hasOptionalParams = $true }
            }
            if ($hasOptionalParams -eq $false) {
                # Add the MinDB param to ensure that the cmdlet call gets differentiated without the optional params being set
                $params.Add("EnableMinDB", $false)
            }
        }
    }

    if ($null -eq $result) { 
        Write-Verbose -Message "Creating Secure Store Service Application $Name"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $params -ScriptBlock {
            $params = $args[0]
            
            if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }

            if($params.ContainsKey("DatabaseAuthenticationType")) {
                if ($params.DatabaseAuthenticationType -eq "SQL") {
                    $params.Add("DatabaseUsername", $params.DatabaseCredentials.Username)
                    $params.Add("DatabasePassword", (ConvertTo-SecureString $params.DatabaseCredentials.GetNetworkCredential().Password -AsPlainText -Force))
                }
                $params.Remove("DatabaseAuthenticationType")
            }

            New-SPSecureStoreServiceApplication @params | New-SPSecureStoreServiceApplicationProxy -Name "$($params.Name) Proxy"
        }
    } else {
        if ([string]::IsNullOrEmpty($ApplicationPool) -eq $false -and $ApplicationPool -ne $result.ApplicationPool) {
            Write-Verbose -Message "Updating Secure Store Service Application $Name"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                $serviceApp = Get-SPServiceApplication -Name $params.Name | Where-Object { $_.TypeName -eq "Secure Store Service Application" }
                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool 
                switch((Get-xSharePointInstalledProductVersion).FileMajorPart) {
                    15 {
                        Set-SPSecureStoreServiceApplication -Identity $serviceApp -ApplicationPool $appPool
                    }
                    16 {
                        Set-SPSecureStoreServiceApplication -Identity $serviceApp -ApplicationPool $appPool -EnableMinDB:$false
                    }
                    Default {
                        throw [Exception] "An unknown version of SharePoint (Major version $_) was detected. Only versions 15 (SharePoint 2013) or 16 (SharePoint 2016) are supported."
                    }
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.Boolean] $AuditingEnabled,
        [parameter(Mandatory = $false)] [System.UInt32]  $AuditlogMaxSize,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $FailoverDatabaseServer,
        [parameter(Mandatory = $false)] [System.Boolean] $PartitionMode,
        [parameter(Mandatory = $false)] [System.Boolean] $Sharing,
        [parameter(Mandatory = $false)] [ValidateSet("Windows", "SQL")] [System.String]  $DatabaseAuthenticationType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $DatabaseCredentials,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing secure store service application $Name"
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("ApplicationPool")
}


Export-ModuleMember -Function *-TargetResource

