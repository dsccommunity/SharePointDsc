function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $Forest,

        [parameter(Mandatory = $true)] 
        [System.Management.Automation.PSCredential] 
        $ConnectionCredentials,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $UserProfileService,

        [parameter(Mandatory = $true)] 
        [System.String[]] 
        $IncludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $ExcludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Server,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Force,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $UseSSL,

        [parameter(Mandatory = $false)] 
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")] 
        [System.String] 
        $ConnectionType,

        [parameter(Mandatory = $false)] 
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
 
        if ($null -eq $ups)
        {
            return $null
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
                return $null
            }
            $namingContext = $connection.NamingContexts | Select-Object -First 1
            if ($null -eq $namingContext)
            {
                return $null
            }
            $accountCredentials = "$($connection.AccountDomain)\$($connection.AccountUsername)"
            $domainController = $namingContext.PreferredDomainControllers | Select-Object -First 1
            return @{
                UserProfileService = $UserProfileService
                Forest = $connection.Server
                Name = $namingContext.DisplayName
                Credentials = $accountCredentials 
                IncludedOUs = $namingContext.ContainersIncluded
                ExcludedOUs = $namingContext.ContainersExcluded
                Server =$domainController
                UseSSL = $connection.UseSSL
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $Name,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $Forest,

        [parameter(Mandatory = $true)] 
        [System.Management.Automation.PSCredential] 
        $ConnectionCredentials,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $UserProfileService,

        [parameter(Mandatory = $true)] 
        [System.String[]] 
        $IncludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $ExcludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Server,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Force,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $UseSSL,

        [parameter(Mandatory = $false)] 
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")] 
        [System.String] 
        $ConnectionType,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
   )

    Write-Verbose -Message "Setting user profile service sync connection $Name"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments @($PSBoundParameters, $PSScriptRoot) `
                        -ScriptBlock {

        $params = $args[0]
        $scriptRoot = $args[1]
        
        Import-Module -Name (Join-Path $scriptRoot "MSFT_SPUserProfileSyncConnection.psm1")
        
        if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
                
        if ($null -eq $ups) { 
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
        
        $connection = $upcm.ConnectionManager | Where-Object -FilterScript { 
            $_.DisplayName -eq $params.Name
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
            Write-Verbose -Message "creating a new connection "
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
        $Name,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $Forest,

        [parameter(Mandatory = $true)] 
        [System.Management.Automation.PSCredential] 
        $ConnectionCredentials,

        [parameter(Mandatory = $true)] 
        [System.String] 
        $UserProfileService,

        [parameter(Mandatory = $true)] 
        [System.String[]] 
        $IncludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String[]] 
        $ExcludedOUs,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $Server,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $Force,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $UseSSL,

        [parameter(Mandatory = $false)] 
        [ValidateSet("ActiveDirectory","BusinessDataCatalog")] 
        [System.String] 
        $ConnectionType,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing for user profile service sync connection $Name"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }

    if ($Force -eq $true)
    {
        return $false 
    }    

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Name", 
                                                     "Forest", 
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
        [string] $LdapPath
    )
    return [ADSI]($LdapPath)
}

            
Export-ModuleMember -Function *-TargetResource, Get-SPDSCADSIObject
