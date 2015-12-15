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
        [parameter(Mandatory = $false)] [System.String] $Force,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
		[parameter(Mandatory = $false)] [System.String] $ConnectionType,
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
            $context = Get-xSharePointServiceContext  $ups.ServiceApplicationProxyGroup 
            $upcm = New-Object -TypeName Microsoft.Office.Server.UserProfiles.UserProfileConfigManager $context

            $connection = $upcm.ConnectionManager | Where-Object { $_.DisplayName -eq $params.Name}
			if($connection -eq $null){
				return $null
			}
            $namingContext = $connection.NamingContexts | select -first 1
			if($namingContext -eq $null){
				return $null
			}
            return @{
                        UserProfileService = $UserProfileService
                        Forest = $connection.Server #"contoso.com" #TODO: GetCorrect Forest
                        Domain = $namingContext.DisplayName
                        Credentials = "$($connection.AccountDomain)\$($connection.AccountUsername)"
                        IncludedOUs = $namingContext.ContainersIncluded
                        ExcludedOUs = $namingContext.ContainersExcluded
                        Server =$namingContext.PreferredDomainControllers;
                        UseSSL = $connection.UseSSL;
                        ConnectionType = $connection.Type;
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
		[parameter(Mandatory = $false)] [System.String] $ConnectionType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
   )

    Write-Verbose -Message "Creating user profile service application $Name"


    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
    $params = $args[0]
        

    if ($params.ContainsKey("InstallAccount")) { $params.Remove("InstallAccount") | Out-Null }
    $ups = Get-SPServiceApplication -Name $params.UserProfileService -ErrorAction SilentlyContinue 
                
    if ($null -eq $ups) { 
        throw "User Profile Service Application $($params.UserProfileService) not found"
    }
     $context = Get-xSharePointServiceContext  $ups.ServiceApplicationProxyGroup 
     $upcm = New-Object -TypeName "Microsoft.Office.Server.UserProfiles.UserProfileConfigManager" $context

    if($upcm.IsSynchronizationRunning())
    {
        throw "Synchronization is in Progress."
    }
        
    $securePassword =  ConvertTo-SecureString  $params.ConnectionCredentials.GetNetworkCredential().password -AsPlainText -Force
    
    $connection = $upcm.ConnectionManager | Where-Object { $_.DisplayName -eq $params.Name} | select -first 1
    if($connection -ne $null -and $params.Forest -ieq  $connection.Server)
    {
            $namingContext = $connection.NamingContexts[0]
            $connection.SetCredentials($params.ConnectionCredentials.UserName, $securePassword);
            
            if($params.ContainsKey("IncludedOUs")){
                $namingContext.IncludedOUs = $params.IncludedOUs
            }
            if($params.ContainsKey("ExcludedOUs")){
                $namingContext.ExcludedOUs = $params.ExcludedOUs
            }else{
                $namingContext.ExcludedOUs = @()
            }
            $connection.RefreshSchema();
            $connection.Update();
            return;
        
    }else{
        if($connection -ne $null -and $params.Forest -ine  $connection.Server){
            if($params.ContainsKey("Force") -and $params.Force -eq $true){
                $connection.Delete();
            }else{
                throw "connection exists and forest is different. use force  "
            }
            
        }
        $namingContext =  New-Object Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext (
                                        $params.Name,
                                        $params.Forest, 
                                        $true, 
                                        [guid]::NewGuid(), 
                                        $params.IncludedOUs, 
                                        $params.ExcludedOus,
                                        $params.Server, 
                                        $false)
        $newUPSADConnection =  $upcm.ConnectionManager.AddActiveDirectoryConnection( `
                                        [Microsoft.Office.Server.UserProfiles.ConnectionType]::ActiveDirectory,  `
                                        $params.Name, `
                                        $params.Forest, `
                                        $params.UseSSL, `
                                        $params.Credential.UserName, `
                                        $securePassword, `
                                        $namingContext, `
                                        $null, $null `
                                    )


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
        [parameter(Mandatory = $false)] [System.String] $Force,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
		[parameter(Mandatory = $false)] [System.String] $ConnectionType,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for user profile service sync connection $Name"
    if ($null -eq $CurrentValues) { return $false }
    if( $Force)
    {
        return $false
    }
    
        return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name", "Forest", "UserProfileService", "Server", "UseSSL")
    
    if($CurrentValues.IncludedOUs.Count -ne $IncludedOus.Count)
    {
        return $false
    }else{
        $allGood = $true;
        $CurrentValues.IncludedOUs | for-eachobject {
                        if(-not $IncludedOUs.Contains($_)){
                            $allGood=$false;
                        }
                    }
        if($allGood -eq $false)
        {
             return $false
        }
    }

    if( ($ExcludedOus -eq $null -and $CurrentValues.ExcludedOus.Count -gt 0) -or 
        ($CurrentValues.ExcludedOUs.Count -ne $ExcludedOUs.Count)  )
    {
        return $false
    }else{
        $allGood = $true;
        $CurrentValues.ExcludedOUs | for-eachobject {
            if(-not $ExcludedOUs.Contains($_)){
                $allGood=$false;
            }
        }
        if($allGood -eq $false)
        {
             return $false
        }
    }

}
        


Export-ModuleMember -Function *-TargetResource

