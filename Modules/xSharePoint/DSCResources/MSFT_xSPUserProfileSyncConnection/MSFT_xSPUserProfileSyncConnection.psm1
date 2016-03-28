function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Forest,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $ConnectionCredentials,
        [parameter(Mandatory = $true)] [System.String] $UserProfileService,
        [parameter(Mandatory = $true)] [System.String[]] $IncludedOUs,
        [parameter(Mandatory = $false)] [System.String[]] $ExcludedOUs,
        [parameter(Mandatory = $false)] [System.String] $Server,
        [parameter(Mandatory = $false)] [System.Boolean] $Force,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [ValidateSet("ActiveDirectory","BusinessDataCatalog")] [System.String] $ConnectionType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting user profile service sync connection $ConnectionDomain"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
 
        If ($null -eq $ups)
        {
            return $null
        }
        else
        {
            $context = Get-xSharePointServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup 
            $upcm = New-Object -TypeName Microsoft.Office.Server.UserProfiles.UserProfileConfigManager $context

            $connection = $upcm.ConnectionManager | Where-Object { $_.DisplayName -eq $params.Name}
            if($connection -eq $null){
                return $null
            }
            $namingContext = $connection.NamingContexts | select -first 1
            if($namingContext -eq $null){
                return $null
            }
            $accountCredentials = "$($connection.AccountDomain)\$($connection.AccountUsername)"
            $domainController = $namingContext.PreferredDomainControllers | select -First 1
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Forest,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $ConnectionCredentials,
        [parameter(Mandatory = $true)] [System.String] $UserProfileService,
        [parameter(Mandatory = $true)] [System.String[]] $IncludedOUs,
        [parameter(Mandatory = $false)] [System.String[]] $ExcludedOUs,
        [parameter(Mandatory = $false)] [System.String] $Server,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [System.Boolean] $Force,
        [parameter(Mandatory = $false)] [ValidateSet("ActiveDirectory","BusinessDataCatalog")] [System.String] $ConnectionType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
   )

    Write-Verbose -Message "Creating user profile service application $Name"


    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
        $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
                
        if ($null -eq $ups) { 
            throw "User Profile Service Application $($params.UserProfileService) not found"
        }
        $context = Get-xSharePointServiceContext -ProxyGroup $ups.ServiceApplicationProxyGroup

        Write-Verbose -Message "retrieving UserProfileConfigManager "
        $upcm = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager $context

        if($upcm.IsSynchronizationRunning())
        {
            throw "Synchronization is in Progress."
        }
        
        $securePassword =  ConvertTo-SecureString  $params.ConnectionCredentials.GetNetworkCredential().password -AsPlainText -Force
        $connection = $upcm.ConnectionManager | Where-Object { $_.DisplayName -eq $params.Name} | select -first 1
        if($connection -ne $null -and $params.Forest -ieq  $connection.Server)
        {
            $domain = $params.ConnectionCredentials.UserName.Split("\")[0]
            $userName= $params.ConnectionCredentials.UserName.Split("\")[1]
            $connection.SetCredentials($domain, $userName, $securePassword);

            $connection.NamingContexts | %{
                $namingContext = $_
                if($params.ContainsKey("IncludedOUs")){
                    $namingContext.ContainersIncluded.Clear()
                    $params.IncludedOUs| %{$namingContext.ContainersIncluded.Add($_) }
                }
                $namingContext.ContainersExcluded.Clear()
                if($params.ContainsKey("ExcludedOUs")){
                    $params.IncludedOUs| %{$namingContext.ContainersExcluded.Add($_) }
                }
            }
            $connection.Update();
            $connection.RefreshSchema($securePassword);
            
            return;
        } else {
            Write-Verbose -Message "creating a new connection "
            if($connection -ne $null -and $params.Forest -ine  $connection.Server){
                if($params.ContainsKey("Force") -and $params.Force -eq $true){
                    $connection.Delete();
                }else{
                    throw "connection exists and forest is different. use force  "
                }
                
            }

            $servers = New-Object System.Collections.Generic.List[[System.String]]
            if($params.ContainsKey("Server")){
                $servers.add($params.Server) 
            }
            $listIncludedOUs = New-Object System.Collections.Generic.List[[System.String]]
            $params.IncludedOUs | %{ 
                $listIncludedOUs.Add($_) 
            }

            $listExcludedOUs = New-Object System.Collections.Generic.List[[System.String]]
            if($params.ContainsKey("ExcludedOus")){
                $params.ExcludedOus | %{$listExcludedOUs.Add($_) }
            }
            $list = New-Object System.Collections.Generic.List[[Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext]]

            $partition = [ADSI]("LDAP://" +("DC=" + $params.Forest.Replace(".", ",DC=")))
            $list.Add((New-Object Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext (
                                            $partition.distinguishedName,
                                            $params.Forest, 
                                            $false, 
                                            (New-Object Guid($partition.objectGUID)) , 
                                            $listIncludedOUs , 
                                            $listExcludedOUs ,
                                            $null , 
                                            $false)))
            $partition = [ADSI]("LDAP://CN=Configuration," +("DC=" + $params.Forest.Replace(".", ",DC=")))
            $list.Add((New-Object Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext (
                                            $partition.distinguishedName,
                                            $params.Forest, 
                                            $true, 
                                            (New-Object Guid($partition.objectGUID)) , 
                                            $listIncludedOUs , 
                                            $listExcludedOUs ,
                                            $null , 
                                            $false)))

            $userDomain = $params.ConnectionCredentials.UserName.Split("\")[0]
            $userName= $params.ConnectionCredentials.UserName.Split("\")[1]
            
            $newUPSADConnection =  $upcm.ConnectionManager.AddActiveDirectoryConnection( [Microsoft.Office.Server.UserProfiles.ConnectionType]::ActiveDirectory,  `
                                            $params.Name, `
                                            $params.Forest, `
                                            $params.UseSSL, `
                                            $userDomain, `
                                            $userName, `
                                            $securePassword, `
                                            $list, `
                                            $null,`
                                            $null)
        }
    }
}



function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $true)]  [System.String] $Forest,
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $ConnectionCredentials,
        [parameter(Mandatory = $true)] [System.String] $UserProfileService,
        [parameter(Mandatory = $true)] [System.String[]] $IncludedOUs,
        [parameter(Mandatory = $false)] [System.String[]] $ExcludedOUs,
        [parameter(Mandatory = $false)] [System.String] $Server,
        [parameter(Mandatory = $false)] [System.Boolean] $Force,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [ValidateSet("ActiveDirectory","BusinessDataCatalog")] [System.String] $ConnectionType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service sync connection $Name"
    if ($null -eq $CurrentValues) { return $false }
    if($Force -eq $true)
    {
        return $false 
    }    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name", "Forest", "UserProfileService", "Server", "UseSSL","IncludedOUs", "ExcludedOUs" )
}

Export-ModuleMember -Function *-TargetResource

