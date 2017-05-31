function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $WebAppUrl,

        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Intranet","Internet","Extranet","Custom")]
        [System.String] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

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

    Write-Verbose -Message "Getting web application extension '$Name' config"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments @($PSBoundParameters,$PSScriptRoot) `
                                  -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        
        if ($null -eq $wa) 
        { 
            Write-Verbose -Message "WebApplication $($params.WebAppUrl) does not exist"
            return @{
                WebAppUrl = $params.WebAppUrl
                Name = $params.Name
                Url = $null 
                Zone = $null 
                Ensure = "Absent"
            } 
        }

        $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)
        $waExt = $wa.IisSettings[$zone]

        if ($null -eq $waExt) 
        { 
            return @{
                WebAppUrl = $params.WebAppUrl
                Name = $params.Name
                Url = $params.Url
                Zone = $params.zone 
                Ensure = "Absent"
            } 
        }

        $publicUrl = (Get-SPAlternateURL -WebApplication $params.WebAppUrl -Zone $params.zone).PublicUrl
        
        if ($null -ne $waExt.SecureBindings.HostHeader) #default to SSL bindings if present  
        {
            $HostHeader = $waExt.SecureBindings.HostHeader
            $Port = $waExt.SecureBindings.Port
            $UseSSL = $true 
        }
        else 
        {
            $HostHeader = $waExt.ServerBindings.HostHeader
            $Port = $waExt.ServerBindings.Port
            $UseSSL = $false 
        }

        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone $params.zone 
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
        }
        else 
        {
            $localAuthMode = "Claims"
            $authenticationProvider = $authProvider.DisplayName
        }

         return @{
            WebAppUrl = $params.WebAppUrl
            Name = $waExt.ServerComment
            Url = $PublicURL
            AllowAnonymous = $authProvider.AllowAnonymous
            HostHeader = $HostHeader 
            Path = $waExt.Path
            Port = $Port
            Zone = $params.zone
            AuthenticationMethod = $localAuthMode
            AuthenticationProvider = $authenticationProvider
            UseSSL = $UseSSL
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
        $WebAppUrl,

        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Intranet","Internet","Extranet","Custom")]
        [System.String] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

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

    Write-Verbose -Message "Setting web application extension '$Name' config"
    
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


            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa) 
            {
                throw "Web Application with URL $($params.WebAppUrl) does not exist"
            }


            $zone = [Microsoft.SharePoint.Administration.SPUrlZone]::$($params.Zone)
            $waExt = $wa.IisSettings[$zone]

            if ($null -eq $waExt) 
            {
                $newWebAppExtParams = @{
                    Name = $params.Name
                    Url = $params.Url
                    Zone = $params.zone 
                }

                              
                if ($params.ContainsKey("AuthenticationMethod") -eq $true) 
                {   
                    if($params.AuthenticationMethod -eq "Claims")
                    {
                        try 
                        {
                            $ap = Get-SPTrustedIdentityTokenIssuer -Identity $params.AuthenticationProvider -ErrorAction Stop
                        } 
                        catch
                        {
                            throw [Exception] "Cannot find Authentication Provider $($params.AuthenticationProvider)"
                        }
                    }
                    else 
                    {
                        $disableKerberos = ($params.AuthenticationMethod -eq "NTLM")
                        $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication `
                                                            -DisableKerberos:$disableKerberos
                    }

                    $newWebAppExtParams.Add("AuthenticationProvider", $ap)
                }
                    
                if ($params.ContainsKey("AllowAnonymous") -eq $true) 
                {
                    $newWebAppExtParams.Add("AllowAnonymousAccess", $params.AllowAnonymous) 
                }
                if ($params.ContainsKey("HostHeader") -eq $true) 
                { 
                    $newWebAppExtParams.Add("HostHeader", $params.HostHeader) 
                }
                if ($params.ContainsKey("Path") -eq $true) 
                { 
                    $newWebAppExtParams.Add("Path", $params.Path) 
                }
                if ($params.ContainsKey("Port") -eq $true) 
                { 
                    $newWebAppExtParams.Add("Port", $params.Port) 
                } 
                if ($params.ContainsKey("UseSSL") -eq $true) 
                { 
                    $newWebAppExtParams.Add("SecureSocketsLayer", $params.UseSSL) 
                } 
                
                    $wa | New-SPWebApplicationExtension @newWebAppExtParams | Out-Null
            }
            else 
            {
                if ($params.ContainsKey("AllowAnonymous") -eq $true) 
                {
                    $waExt.AllowAnonymous = $params.AllowAnonymous
                    $wa.update()
                }

                if ($params.ContainsKey("AuthenticationMethod") -eq $true)
                { 
                    if($params.AuthenticationMethod -eq "Claims")
                    {
                        try 
                        {
                            $ap = Get-SPTrustedIdentityTokenIssuer -Identity $params.AuthenticationProvider -ErrorAction Stop
                        }
                        catch
                        {
                            throw [Exception] "Cannot find Authentication Provider $($params.AuthenticationProvider)"
                        }
                    }
                    else 
                    {
                        $disableKerberos = ($params.AuthenticationMethod -eq "NTLM")
                        $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication `
                                                            -DisableKerberos:$disableKerberos
                    }

                    Set-SPWebApplication -Identity $params.WebAppUrl -Zone $params.zone -AuthenticationProvider $ap 
                }
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

            $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
            if ($null -eq $wa) 
            {
                throw "Web Application with URL $($params.WebAppUrl) does not exist"
            }
            if ($null -ne $wa) 
            {
                $wa | Remove-SPWebApplication -Zone $params.zone -Confirm:$false -DeleteIISSite
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
        $WebAppUrl,

        [parameter(Mandatory = $true)]  
        [System.String]
        $Name,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $Url,

        [parameter(Mandatory = $true)]
        [ValidateSet("Default","Intranet","Internet","Extranet","Custom")]
        [System.String] 
        $Zone,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AllowAnonymous,

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

    Write-Verbose -Message "Testing for web application extension '$Name'config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $testReturn = Test-SPDscParameterState -CurrentValues $CurrentValues `
                                                     -DesiredValues $PSBoundParameters `
                                                     -ValuesToCheck @("Ensure","AuthenticationMethod","AllowAnonymous")
    return $testReturn
}

Export-ModuleMember -Function *-TargetResource
