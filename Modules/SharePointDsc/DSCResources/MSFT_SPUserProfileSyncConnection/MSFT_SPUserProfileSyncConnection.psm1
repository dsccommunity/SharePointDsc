function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Forest,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ConnectionCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IncludedOUs,

        [Parameter()]
        [System.String[]]
        $ExcludedOUs,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.UInt32]
        $Port = 389,

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [System.Boolean]
        $UseDisabledFilter,

        [Parameter()]
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service sync connection $Name"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $ups = Get-SPServiceApplication -Name $params.UserProfileService `
                                        -ErrorAction SilentlyContinue

        $nullreturn = @{
            Name = $params.Name
            UserProfileService = $null
            Forest = $null
            ConnectionCredentials = $null
            IncludedOUs = $null
            ExcludedOUs = $null
            Server = $null
            Port = $null
            UseSSL = $null
            UseDisabledFilter = $null
            ConnectionType = $null
            Force = $null
        }

        if ($null -eq $ups)
        {
            return $nullreturn
        }
        else
        {
            $context = Get-SPDSCServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup
            $upcm = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
                               -ArgumentList $context

            $connection = $upcm.ConnectionManager | Where-Object -FilterScript {
                $_.DisplayName -eq $params.Name
            }
            if ($null -eq $connection)
            {
                return $nullreturn
            }
            $namingContext = $connection.NamingContexts | Select-Object -First 1
            if ($null -eq $namingContext)
            {
                $BINDING_FLAGS = ([System.Reflection.BindingFlags]::NonPublic -bOr [System.Reflection.BindingFlags]::Instance)
                $adImportNamespace = [Microsoft.Office.Server.UserProfiles.ActiveDirectoryImportConnection]
                $METHOD_GET_NAMINGCONTEXTS = $adImportNamespace.GetMethod("get_NamingContexts", $BINDING_FLAGS)
                $METHOD_GET_ACCOUNTUSERNAME = $adImportNamespace.GetMethod("get_AccountUsername", $BINDING_FLAGS)
                $METHOD_GET_ACCOUNTDOMAIN = $adImportNamespace.GetMethod("get_AccountDomain", $BINDING_FLAGS)
                $METHOD_GET_USEDISABLEDFILTER = $adImportNamespace.GetMethod("get_UseDisabledFilter", $BINDING_FLAGS)
                $METHOD_GET_USESSL = $adImportNamespace.GetMethod("get_UseSSL", $BINDING_FLAGS)
                $namingContexts = $METHOD_GET_NAMINGCONTEXTS.Invoke($connection, $null)
                $accountName = $METHOD_GET_ACCOUNTUSERNAME.Invoke($connection, $null)
                $accountDomain = $METHOD_GET_ACCOUNTDOMAIN.Invoke($connection, $null)
                $accountCredentials = $accountDomain + "\" + $accountName
                $useDisabledFilter = $METHOD_GET_USEDISABLEDFILTER.Invoke($connection, $null)
                $useSSL = $METHOD_GET_USESSL.Invoke($connection, $null)

                if($null -eq $namingContexts)
                {
                    return $nullreturn
                }

                if ($null -eq $namingContexts.ContainersIncluded)
                {
                    $inclOUs = $null
                }
                else
                {
                    $inclOUs = @($namingContexts.ContainersIncluded)
                }

                if ($null -eq $namingContexts.ContainersExcluded)
                {
                    $exclOUs = $null
                }
                else
                {
                    $exclOUs = @($namingContexts.ContainersExcluded)
                }

                return @{
                    Name = $params.Name
                    UserProfileService = $params.UserProfileService
                    Forest = $namingContexts.DistinguishedName
                    ConnectionCredentials = $accountCredentials
                    IncludedOUs = @($namingContexts.ContainersIncluded)
                    ExcludedOUs = @($namingContexts.ContainersExcluded)
                    Server = $null
                    Port = $params.Port
                    UseSSL = $useSSL
                    UseDisabledFilter = $useDisabledFilter
                    ConnectionType = $connection.Type -replace "Import",""
                    Force = $params.Force
                }
            }

            $accountCredentials = "$($connection.AccountDomain)\$($connection.AccountUsername)"
            $domainController = $namingContext.PreferredDomainControllers | Select-Object -First 1

            if ($null -eq $namingContext.ContainersIncluded)
            {
                $inclOUs = $null
            }
            else
            {
                $inclOUs = @($namingContext.ContainersIncluded)
            }

            if ($null -eq $namingContext.ContainersExcluded)
            {
                $exclOUs = $null
            }
            else
            {
                $exclOUs = @($namingContext.ContainersExcluded)
            }

            return @{
                UserProfileService = $params.UserProfileService
                Forest = $connection.Server
                Name = $params.Name
                ConnectionCredentials = $accountCredentials
                IncludedOUs = $inclOUs
                ExcludedOUs = $exclOUs
                Server = $domainController
                UseSSL = $connection.UseSSL
                UseDisabledFilter = $connection.UseDisabledFilter
                Port = $params.Port
                ConnectionType = $connection.Type.ToString()
                Force = $params.Force
            }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Forest,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ConnectionCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IncludedOUs,

        [Parameter()]
        [System.String[]]
        $ExcludedOUs,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.UInt32]
        $Port = 389,

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [System.Boolean]
        $UseDisabledFilter,

        [Parameter()]
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
   )

    Write-Verbose -Message "Setting user profile service sync connection $Name"

    if ($PSBoundParameters.ContainsKey("UseSSL") -eq $false)
    {
        Write-Verbose -Message "UseSSL is not specified. Assuming that SSL is not required."
        $PSBoundParameters.UseSSL = $false
    }
    else
    {
        if ($UseSSL -eq $true -and $PSBoundParameters.ContainsKey("Port") -eq $false)
        {
            Write-Verbose -Message ("UseSSL is set to True, but no port is specified. Assuming " + `
                                    "that port 636 (default LDAPS port) is to be used.")
            $PSBoundParameters.Port = 636
        }
    }

    if ($PSBoundParameters.ContainsKey("Port") -eq $false)
    {
        $PSBoundParameters.Port = $Port
    }
    else
    {
        if ($installedVersion.FileMajorPart -eq 15)
        {
            Write-Verbose -Message "NOTE: The Port parameter is not used in SharePoint 2013."
        }
    }

    if ($PSBoundParameters.ContainsKey("UseDisabledFilter") -eq $false)
    {
        Write-Verbose -Message ("UseDisabledFilter is not specified. Assuming that disabled " + `
                                "accounts should not be filtered.")
        $PSBoundParameters.UseDisabledFilter = $false
    }
    else
    {
        if ($installedVersion.FileMajorPart -eq 15)
        {
            Write-Verbose -Message "NOTE: The UseDisabledFilter parameter is ignored in SharePoint 2013."
        }
    }

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $PSScriptRoot) `
                        -ScriptBlock {

        $params = $args[0]
        $scriptRoot = $args[1]

        Import-Module -Name (Join-Path $scriptRoot "MSFT_SPUserProfileSyncConnection.psm1")

        if ($params.ContainsKey("InstallAccount"))
        {
            $params.Remove("InstallAccount") | Out-Null
        }
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue

        if ($null -eq $ups)
        {
            throw "User Profile Service Application $($params.UserProfileService) not found"
        }
        $context = Get-SPDSCServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup

        Write-Verbose -Message "retrieving UserProfileConfigManager "
        $upcm = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
                           -ArgumentList @($context)

        if ($upcm.IsSynchronizationRunning())
        {
            throw "Synchronization is in Progress."
        }

        if($null -ne $params.Name)
        {
            $Name = $params.Name
        }
        else {
            $Name = $params.Forest.Replace(".", "-")
        }

        $connection = $upcm.ConnectionManager | Where-Object -FilterScript {
            $_.DisplayName -eq $Name
        } | Select-Object -first 1

        if ($null -ne $connection -and $params.Forest -ieq  $connection.Server)
        {
            $domain = $params.ConnectionCredentials.UserName.Split("\")[0]
            $userName= $params.ConnectionCredentials.UserName.Split("\")[1]
            $connection.SetCredentials($domain, $userName, $params.ConnectionCredentials.Password)

            $connection.NamingContexts | ForEach-Object -Process {
                $namingContext = $_
                if ($params.ContainsKey("IncludedOUs"))
                {
                    $namingContext.ContainersIncluded.Clear()
                    $params.IncludedOUs| ForEach-Object -Process {
                        $namingContext.ContainersIncluded.Add($_)
                    }
                }
                $namingContext.ContainersExcluded.Clear()
                if ($params.ContainsKey("ExcludedOUs"))
                {
                    $params.IncludedOUs| ForEach-Object -Process {
                        $namingContext.ContainersExcluded.Add($_)
                    }
                }
            }
            $connection.Update()
            $connection.RefreshSchema($params.ConnectionCredentials.Password)

            return
        }
        else
        {
            Write-Verbose -Message "Creating a new connection "
            if ($null -ne $connection -and $params.Forest -ine  $connection.Server)
            {
                if ($params.ContainsKey("Force") -and $params.Force -eq $true)
                {
                    $connection.Delete()
                }
                else
                {
                    throw "connection exists and forest is different. use force"
                }

            }

            $servers = New-Object -TypeName "System.Collections.Generic.List[[System.String]]"
            if ($params.ContainsKey("Server"))
            {
                $servers.add($params.Server)
            }
            $listIncludedOUs = New-Object -TypeName "System.Collections.Generic.List[[System.String]]"
            $params.IncludedOUs | ForEach-Object -Process {
                $listIncludedOUs.Add($_)
            }

            $listExcludedOUs = New-Object -TypeName "System.Collections.Generic.List[[System.String]]"
            if ($params.ContainsKey("ExcludedOus"))
            {
                $params.ExcludedOus | ForEach-Object -Process {
                    $listExcludedOUs.Add($_)
                }
            }
            $list = New-Object -TypeName System.Collections.Generic.List[[Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext]]

            $partition = Get-SPDSCADSIObject -LdapPath ("LDAP://" +("DC=" + $params.Forest.Replace(".", ",DC=")))
            $list.Add((New-Object -TypeName "Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext" `
                                  -ArgumentList @(
                                            $partition.distinguishedName,
                                            $params.Forest,
                                            $false,
                                            (New-Object -TypeName "System.Guid" `
                                                        -ArgumentList $partition.objectGUID),
                                            $listIncludedOUs,
                                            $listExcludedOUs,
                                            $null ,
                                            $false)))
            $partition = Get-SPDSCADSIObject -LdapPath ("LDAP://CN=Configuration," + ("DC=" + $params.Forest.Replace(".", ",DC=")))
            $list.Add((New-Object -TypeName "Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext" `
                                  -ArgumentList @(
                                            $partition.distinguishedName,
                                            $params.Forest,
                                            $true,
                                            (New-Object -TypeName "System.Guid" `
                                                        -ArgumentList $partition.objectGUID),
                                            $listIncludedOUs ,
                                            $listExcludedOUs ,
                                            $null ,
                                            $false)))

            $userDomain = $params.ConnectionCredentials.UserName.Split("\")[0]
            $userName= $params.ConnectionCredentials.UserName.Split("\")[1]

            $installedVersion = Get-SPDSCInstalledProductVersion

            switch($installedVersion.FileMajorPart)
            {
                15
                {
                    $upcm.ConnectionManager.AddActiveDirectoryConnection( [Microsoft.Office.Server.UserProfiles.ConnectionType]::ActiveDirectory,  `
                                            $params.Name, `
                                            $params.Forest, `
                                            $params.UseSSL, `
                                            $userDomain, `
                                            $userName, `
                                            $params.ConnectionCredentials.Password, `
                                            $list, `
                                            $null,`
                                            $null) | Out-Null
               }
               16
               {
                    foreach($ou in $params.IncludedOUs)
                    {
                        Add-SPProfileSyncConnection -ProfileServiceApplication $ups `
                                                    -ConnectionForestName $params.Forest `
                                                    -ConnectionDomain $userDomain `
                                                    -ConnectionUserName $userName `
                                                    -ConnectionPassword $params.ConnectionCredentials.Password `
                                                    -ConnectionUseSSL $params.UseSSL `
                                                    -ConnectionSynchronizationOU $ou `
                                                    -ConnectionPort $params.Port `
                                                    -ConnectionUseDisabledFilter $params.UseDisabledFilter
                    }

                    foreach($ou in $params.ExcludedOUs)
                    {
                        Remove-SPProfilesyncConnection -ProfileServiceApplication $ups `
                                                       -ConnectionForestName $params.Forest `
                                                       -ConnectionDomain $userDomain `
                                                       -ConnectionUserName $userName `
                                                       -ConnectionPassword $params.ConnectionCredentials.Password `
                                                       -ConnectionSynchronizationOU $ou
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Forest,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $ConnectionCredentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserProfileService,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $IncludedOUs,

        [Parameter()]
        [System.String[]]
        $ExcludedOUs,

        [Parameter()]
        [System.String]
        $Server,

        [Parameter()]
        [System.UInt32]
        $Port = 389,

        [Parameter()]
        [System.Boolean]
        $Force,

        [Parameter()]
        [System.Boolean]
        $UseSSL,

        [Parameter()]
        [System.Boolean]
        $UseDisabledFilter,

        [Parameter()]
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile service sync connection $Name"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues.UserProfileService)
    {
        return $false
    }

    if ($Force -eq $true)
    {
        return $false
    }

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Forest",
                                                     "UserProfileService",
                                                     "Server",
                                                     "UseSSL",
                                                     "IncludedOUs",
                                                     "ExcludedOUs")
}

<#
.DESCRIPTION

This method is not intensed for public use, and was created to facilitate unit testing
#>
function Get-SPDSCADSIObject
{
    param(
        [Parameter()]
        [string] $LdapPath
    )
    return [ADSI]($LdapPath)
}

Export-ModuleMember -Function *-TargetResource, Get-SPDSCADSIObject
