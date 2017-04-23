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
        $ApplicationPool,

        [parameter(Mandatory = $true)]  
        [System.String]  
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String] 
        $HostHeader,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Path,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UseSSL,

        [parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos","Claims")]
        [System.String] 
        $AuthenticationMethod,

        [parameter(Mandatory = $false)]
        [System.String] 
        $AuthenticationProvider,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$Name' config"
   
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) 
        { 
            return @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                Url = $params.Url
                Ensure = "Absent"
            } 
        }
        ### COMMENT: Are we making an assumption here, about Default Zone
        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default" 
        if($authProvider.DisplayName -eq "Windows Authentication") 
        {
            if ($authProvider.DisableKerberos -eq $true) 
            { 
                $localAuthMode = "NTLM" 
            } 
            else 
            { 
                $localAuthMode = "Kerberos" 
            }
              $authenticationProvider = "Windows Authentication"
        }
        else 
        {
            $localAuthMode = "Claims"
            $authenticationProvider = $authProvider.DisplayName
        }

        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            Url = $wa.Url
            AllowAnonymous = $authProvider.AllowAnonymous
            DatabaseName = $wa.ContentDatabases[0].Name
            DatabaseServer = $wa.ContentDatabases[0].Server
            HostHeader = (New-Object -TypeName System.Uri $wa.Url).Host
            Path = $wa.IisSettings[0].Path
            Port = (New-Object -TypeName System.Uri $wa.Url).Port
            AuthenticationMethod = $localAuthMode
            AuthenticationProvider = $authenticationProvider
            UseSSL = (New-Object -TypeName System.Uri $wa.Url).Scheme -eq "https"
            InstallAccount = $params.InstallAccount
            Ensure = "Present"
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
        $ApplicationPool,

        [parameter(Mandatory = $true)]  
        [System.String]  
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String] 
        $HostHeader,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Path,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UseSSL,

        [parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos","Claims")]
        [System.String] 
        $AuthenticationMethod,

        [parameter(Mandatory = $false)]
        [System.String] 
        $AuthenticationProvider,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$Name' config"
    
    if ($Ensure -eq "Present") 
    {

        if ($AuthenticationMethod -eq "Claims" -and [string]::IsNullOrEmpty($AuthenticationProvider))
        {
            throw [Exception] "When configuring SPWebApplication to use Claims the AuthenticationProvider value must be specified."
        }

        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters,$PSScriptRoot) `
                            -ScriptBlock {
            $params = $args[0]
            $ScriptRoot = $args[1]

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -eq $wa) 
            {
                $newWebAppParams = @{
                    Name = $params.Name
                    ApplicationPool = $params.ApplicationPool
                    Url = $params.Url
                }

                # Get a reference to the Administration WebService
                $admService = Get-SPDSCContentService
                $appPools = $admService.ApplicationPools | Where-Object -FilterScript { 
                    $_.Name -eq $params.ApplicationPool 
                }
                if ($null -eq $appPools) 
                {
                    # Application pool does not exist, create a new one.
                    # Test if the specified managed account exists. If so, add 
                    # ApplicationPoolAccount parameter to create the application pool
                    try 
                    {
                        Get-SPManagedAccount $params.ApplicationPoolAccount -ErrorAction Stop
                        $newWebAppParams.Add("ApplicationPoolAccount", $params.ApplicationPoolAccount)
                    }
                    catch 
                    {
                        if ($_.Exception.Message -like "*No matching accounts were found*") 
                        {
                            throw ("The specified managed account was not found. Please make " + `
                                   "sure the managed account exists before continuing.")
                            return
                        } 
                        else 
                        {
                            throw ("Error occurred. Web application was not created. Error " + `
                                   "details: $($_.Exception.Message)")
                            return
                        }
                    }
                }
                
                if ($params.ContainsKey("AuthenticationMethod") -eq $true) 
                {
                    if($params.AuthenticationMethod -eq "Claims")
                    {
                        $ap = Get-SPTrustedIdentityTokenIssuer -Identity $params.AuthenticationProvider
                    }
                    else 
                    {
                        $disableKerberos = ($params.AuthenticationMethod -eq "NTLM")
                        $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication `
                                                            -DisableKerberos:$disableKerberos
                    }
                    
                    $newWebAppParams.Add("AuthenticationProvider", $ap)
                }
                
                if ($params.ContainsKey("AllowAnonymous") -eq $true) 
                {
                    $newWebAppParams.Add("AllowAnonymousAccess", $params.AllowAnonymous) 
                }
                if ($params.ContainsKey("DatabaseName") -eq $true) 
                { 
                    $newWebAppParams.Add("DatabaseName", $params.DatabaseName) 
                }
                if ($params.ContainsKey("DatabaseServer") -eq $true) 
                { 
                    $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer) 
                }
                if ($params.ContainsKey("HostHeader") -eq $true) 
                { 
                    $newWebAppParams.Add("HostHeader", $params.HostHeader) 
                }
                if ($params.ContainsKey("Path") -eq $true) 
                { 
                    $newWebAppParams.Add("Path", $params.Path) 
                }
                if ($params.ContainsKey("Port") -eq $true) 
                { 
                    $newWebAppParams.Add("Port", $params.Port) 
                } 
                if ($params.ContainsKey("UseSSL") -eq $true) 
                { 
                    $newWebAppParams.Add("SecureSocketsLayer", $params.UseSSL) 
                } 
            
                New-SPWebApplication @newWebAppParams | Out-Null
            }
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters,$PSScriptRoot) `
                            -ScriptBlock {
            $params = $args[0]
            $ScriptRoot = $args[1]

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -ne $wa) 
            {
                $wa | Remove-SPWebApplication -Confirm:$false -DeleteIISSite
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
        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [parameter(Mandatory = $true)]  
        [System.String]  
        $ApplicationPoolAccount,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $false)]
        [System.String] 
        $DatabaseServer,

        [parameter(Mandatory = $false)]
        [System.String] 
        $HostHeader,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Path,

        [parameter(Mandatory = $false)]
        [System.String] 
        $Port,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $UseSSL,

        [parameter(Mandatory = $false)]
        [ValidateSet("NTLM","Kerberos","Claims")]
        [System.String] 
        $AuthenticationMethod,

        [parameter(Mandatory = $false)]
        [System.String] 
        $AuthenticationProvider,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing for web application '$Name' config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $testReturn = Test-SPDscParameterState -CurrentValues $CurrentValues `
                                                     -DesiredValues $PSBoundParameters `
                                                     -ValuesToCheck @("Ensure")
    return $testReturn
}

Export-ModuleMember -Function *-TargetResource
