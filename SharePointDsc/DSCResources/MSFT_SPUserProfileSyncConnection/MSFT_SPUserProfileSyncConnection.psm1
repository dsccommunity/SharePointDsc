$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

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
        [ValidateSet("ActiveDirectory", "BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service sync connection $Name"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $ups = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.UserProfileService
        }

        $nullReturn = @{
            Name                  = $params.Name
            UserProfileService    = $null
            Forest                = $null
            ConnectionCredentials = $null
            IncludedOUs           = $null
            ExcludedOUs           = $null
            Server                = $null
            Port                  = $null
            UseSSL                = $null
            UseDisabledFilter     = $null
            ConnectionType        = $null
            Force                 = $null
            Ensure                = "Absent"
        }

        if ($null -eq $ups)
        {
            return $nullReturn
        }
        else
        {
            $context = Get-SPDscServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup
            $upcm = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
                -ArgumentList $context

            $Name = $params.Name
            $connection = $upcm.ConnectionManager | Where-Object -FilterScript {
                $_.DisplayName -eq $Name
            }

            # In SP2016, the forest name is used as name but the dot is replaced by a dash
            $installedVersion = Get-SPDscInstalledProductVersion
            if ($installedVersion.FileMajorPart -eq 16 -and $null -eq $connection)
            {
                $Name = $params.Forest -replace "\.", "-"
                $connection = $upcm.ConnectionManager | Where-Object -FilterScript {
                    $_.DisplayName -eq $Name
                }
            }

            if ($null -eq $connection)
            {
                return $nullReturn
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

                if ($null -eq $namingContexts)
                {
                    return $nullReturn
                }

                if ($null -eq $namingContexts.ContainersIncluded)
                {
                    $inclOUs = @()
                }
                else
                {
                    $inclOUs = @($namingContexts.ContainersIncluded)
                }

                if ($null -eq $namingContexts.ContainersExcluded)
                {
                    $exclOUs = @()
                }
                else
                {
                    $exclOUs = @($namingContexts.ContainersExcluded)
                }

                return @{
                    Name                  = $params.Name
                    UserProfileService    = $params.UserProfileService
                    Forest                = $namingContexts.DistinguishedName.Replace(",DC=", ".").Replace("DC=", "");
                    ConnectionCredentials = $accountCredentials
                    IncludedOUs           = $inclOUs
                    ExcludedOUs           = $exclOUs
                    Server                = $null
                    Port                  = $params.Port
                    UseSSL                = $useSSL
                    UseDisabledFilter     = $useDisabledFilter
                    ConnectionType        = $connection.Type -replace "Import", ""
                    Force                 = $params.Force
                    Ensure                = "Present"
                }
            }

            $accountCredentials = "$($connection.AccountDomain)\$($connection.AccountUsername)"
            $domainController = $namingContext.PreferredDomainControllers | Select-Object -First 1

            if ($null -eq $namingContext.ContainersIncluded)
            {
                $inclOUs = @()
            }
            else
            {
                $inclOUs = @($namingContext.ContainersIncluded)
            }

            if ($null -eq $namingContext.ContainersExcluded)
            {
                $exclOUs = @()
            }
            else
            {
                $exclOUs = @($namingContext.ContainersExcluded)
            }

            return @{
                Name                  = $params.Name
                UserProfileService    = $params.UserProfileService
                Forest                = $connection.Server
                ConnectionCredentials = $accountCredentials
                IncludedOUs           = $inclOUs
                ExcludedOUs           = $exclOUs
                Server                = $domainController
                UseSSL                = $connection.UseSSL
                UseDisabledFilter     = $connection.UseDisabledFilter
                Port                  = $params.Port
                ConnectionType        = $connection.Type.ToString()
                Force                 = $params.Force
                Ensure                = "Present"
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
        [ValidateSet("ActiveDirectory", "BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting user profile service sync connection $Name"

    $PSBoundParameters.Ensure = $Ensure

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

    $installedVersion = Get-SPDscInstalledProductVersion

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

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source, $PSScriptRoot) `
        -ScriptBlock {

        $params = $args[0]
        $eventSource = $args[1]
        $scriptRoot = $args[2]

        Import-Module -Name (Join-Path -Path $scriptRoot -ChildPath "MSFT_SPUserProfileSyncConnection.psm1")

        if ($params.ContainsKey("InstallAccount"))
        {
            $params.Remove("InstallAccount") | Out-Null
        }
        $ups = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.UserProfileService
        }

        if ($null -eq $ups)
        {
            $message = "User Profile Service Application $($params.UserProfileService) not found"
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
        $context = Get-SPDscServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup

        Write-Verbose -Message "retrieving UserProfileConfigManager "
        $upcm = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
            -ArgumentList @($context)

        if ($upcm.IsSynchronizationRunning())
        {
            $message = "Synchronization is in Progress."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        # In SP2016, the forest name is used as name but the dot is replaced by a dash
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -eq 16)
        {
            $Name = $params.Forest -replace "\.", "-"
        }
        else
        {
            $Name = $params.Name
        }

        $connection = $upcm.ConnectionManager | Where-Object -FilterScript {
            $_.DisplayName -eq $Name
        } | Select-Object -First 1

        if ($params.Ensure -eq "Present")
        {
            if ($null -ne $connection -and $params.Forest -ieq $connection.Server)
            {
                $domain = $params.ConnectionCredentials.UserName.Split("\")[0]
                $userName = $params.ConnectionCredentials.UserName.Split("\")[1]
                $connection.SetCredentials($domain, $userName, $params.ConnectionCredentials.Password)

                $connection.NamingContexts | ForEach-Object -Process {
                    $namingContext = $_
                    if ($params.ContainsKey("IncludedOUs"))
                    {
                        $namingContext.ContainersIncluded.Clear()
                        $params.IncludedOUs | ForEach-Object -Process {
                            $namingContext.ContainersIncluded.Add($_)
                        }
                    }
                    $namingContext.ContainersExcluded.Clear()
                    if ($params.ContainsKey("ExcludedOUs"))
                    {
                        $params.ExcludedOUs | ForEach-Object -Process {
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

                $userDomain = $params.ConnectionCredentials.UserName.Split("\")[0]
                $userName = $params.ConnectionCredentials.UserName.Split("\")[1]

                $installedVersion = Get-SPDscInstalledProductVersion

                switch ($installedVersion.FileMajorPart)
                {
                    15
                    {
                        if ($null -ne $connection -and $params.Forest -ine $connection.Server)
                        {
                            if ($params.ContainsKey("Force") -and $params.Force -eq $true)
                            {
                                Write-Verbose -Message "Force specified, deleting already existing connection"
                                $connection.Delete()
                            }
                            else
                            {
                                $message = "connection exists and forest is different. use force"
                                Add-SPDscEvent -Message $message `
                                    -EntryType 'Error' `
                                    -EventID 100 `
                                    -Source $eventSource
                                throw $message
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

                        $partition = Get-SPDscADSIObject -LdapPath ("LDAP://" + ("DC=" + $params.Forest.Replace(".", ",DC=")))
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
                        $partition = Get-SPDscADSIObject -LdapPath ("LDAP://CN=Configuration," + ("DC=" + $params.Forest.Replace(".", ",DC=")))
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

                        Write-Verbose -Message "Creating the new connection via object model (SP2013)"
                        $upcm.ConnectionManager.AddActiveDirectoryConnection( [Microsoft.Office.Server.UserProfiles.ConnectionType]::ActiveDirectory, `
                                $params.Name, `
                                $params.Forest, `
                                $params.UseSSL, `
                                $userDomain, `
                                $userName, `
                                $params.ConnectionCredentials.Password, `
                                $list, `
                                $null, `
                                $null) | Out-Null
                    }
                    16
                    {
                        Write-Verbose -Message "Creating the new connection via cmdlet (SP2016 or SP2019)"

                        if ($null -ne $connection)
                        {
                            $BINDING_FLAGS = ([System.Reflection.BindingFlags]::NonPublic -bOr [System.Reflection.BindingFlags]::Instance)
                            $adImportNamespace = [Microsoft.Office.Server.UserProfiles.ActiveDirectoryImportConnection]
                            $METHOD_GET_USEDISABLEDFILTER = $adImportNamespace.GetMethod("get_UseDisabledFilter", $BINDING_FLAGS)
                            $METHOD_GET_USESSL = $adImportNamespace.GetMethod("get_UseSSL", $BINDING_FLAGS)
                            $useDisabledFilter = $METHOD_GET_USEDISABLEDFILTER.Invoke($connection, $null)
                            $useSSL = $METHOD_GET_USESSL.Invoke($connection, $null)

                            if (($params.ContainsKey("UseSSL") -and $useSSL -ne $params.UseSSL) -or `
                                ($params.ContainsKey("UseDisabledFilter") -and $useDisabledFilter -ne $params.UseDisabledFilter))
                            {
                                Write-Verbose -Message "Parameters UseSSL or UseDisabledFilter are not in desired state. Recreating connection!"
                                $connection.Delete()
                            }
                        }

                        Write-Verbose -Message "Adding IncludedOUs to the connection"
                        foreach ($ou in $params.IncludedOUs)
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

                        Write-Verbose -Message "Removing ExcludedOUs from the connection"
                        foreach ($ou in $params.ExcludedOUs)
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
        else
        {
            Write-Verbose -Message "Removing the new connection "
            if ($null -ne $connection -and $params.Forest -ine $connection.Server)
            {
                $connection.Delete()
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
        [ValidateSet("ActiveDirectory", "BusinessDataCatalog")]
        [System.String]
        $ConnectionType,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile service sync connection $Name"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $installedVersion = Get-SPDscInstalledProductVersion
    $valuesToCheck = @("Forest",
        "UserProfileService",
        "UseSSL",
        "UseDisabledFilter",
        "IncludedOUs",
        "Ensure")

    if ($installedVersion.FileMajorPart -eq 15)
    {
        if ($Force -eq $true)
        {
            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }

        $valuesToCheck += "ExcludedOUs"
        $valuesToCheck += "Server"
    }

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $valuesToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

<#
.DESCRIPTION

This method is not intensed for public use, and was created to facilitate unit testing
#>
function Get-SPDscADSIObject
{
    param
    (
        [Parameter()]
        [string] $LdapPath
    )
    return [ADSI]($LdapPath)
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPUserProfileSyncConnection\MSFT_SPUserProfileSyncConnection.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $userProfileServiceApps = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "UserProfileApplication" }
    $caURL = (Get-SpWebApplication -IncludeCentralAdministration |
            Where-Object -FilterScript { $_.IsAdministrationWebApplication -eq $true }).Url
    $context = Get-SPServiceContext -Site $caURL
    try
    {
        $userProfileConfigManager = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" `
            -ArgumentList $context
        if ($null -ne $userProfileConfigManager.ConnectionManager)
        {
            $connections = $userProfileConfigManager.ConnectionManager
            foreach ($conn in $connections)
            {
                try
                {
                    $params.Name = $conn.DisplayName
                    $params.ConnectionCredentials = $Global:spFarmAccount
                    $params.UserProfileService = $userProfileServiceApps[0].Name
                    $results = Get-TargetResource @params
                    if ($null -ne $results)
                    {
                        if ($results.ConnectionType -eq "ActiveDirectoryImport")
                        {
                            $results.ConnectionType = "ActiveDirectory"
                        }
                        $PartialContent = "        SPUserProfileSyncConnection " + [System.Guid]::NewGuid().ToString() + "`r`n"
                        $PartialContent += "        {`r`n"
                        $results = Repair-Credentials -results $results
                        if ($results.Contains("Ensure"))
                        {
                            $results.Remove("Ensure")
                        }
                        if (!$results.UseDisabledFilter)
                        {
                            $results.Remove("UseDisabledFilter")
                        }
                        $results.ConnectionCredentials = "`$Credsinstallaccount"
                        $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "ConnectionCredentials"
                        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                        $PartialContent += $currentBlock
                        $PartialContent += "        }`r`n"
                        $Content += $PartialContent
                    }
                }
                catch
                {
                    $Global:ErrorLog += "[User Profile Sync Connection]" + $conn.DisplayName + "`r`n"
                    $Global:ErrorLog += "$_`r`n`r`n"
                }
            }
        }
    }
    catch
    {
        Write-Verbose $_
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource, Get-SPDscADSIObject
