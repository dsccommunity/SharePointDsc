function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPool,
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]
        
        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) { return $null }

        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default" 
        if ($authProvider.DisableKerberos -eq $true) { $localAuthMode = "NTLM" } else { $localAuthMode = "Kerberos" }

        return @{
            Name = $wa.DisplayName
            ApplicationPool = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            Url = $wa.Url
            AllowAnonymous = $authProvider.AllowAnonymous
            DatabaseName = $wa.ContentDatabases[0].Name
            DatabaseServer = $wa.ContentDatabases[0].Server
            HostHeader = (New-Object System.Uri $wa.Url).Host
            Path = $wa.IisSettings[0].Path
            Port = (New-Object System.Uri $wa.Url).Port
            AuthenticationMethod = $localAuthMode
            UseSSL = (New-Object System.Uri $wa.Url).Scheme -eq "https"
            InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating web application '$Name'"
    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments @($PSBoundParameters,$PSScriptRoot) -ScriptBlock {
        $params = $args[0]
        $ScriptRoot = $args[1]

        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa) {
            $newWebAppParams = @{
                Name = $params.Name
                ApplicationPool = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                Url = $params.Url
            }
            if ($params.ContainsKey("AuthenticationMethod") -eq $true) {
                if ($params.AuthenticationMethod -eq "NTLM") {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication -DisableKerberos:$true
                } else {
                    $ap = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication  -DisableKerberos:$false
                }
                $newWebAppParams.Add("AuthenticationProvider", $ap)
            }
            if ($params.ContainsKey("AllowAnonymous")) { 
                $newWebAppParams.Add("AllowAnonymousAccess", $params.AllowAnonymous)
            }
            if ($params.ContainsKey("DatabaseName") -eq $true) { $newWebAppParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabaseServer") -eq $true) { $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("HostHeader") -eq $true) { $newWebAppParams.Add("HostHeader", $params.HostHeader) }
            if ($params.ContainsKey("Path") -eq $true) { $newWebAppParams.Add("Path", $params.Path) }
            if ($params.ContainsKey("Port") -eq $true) { $newWebAppParams.Add("Port", $params.Port) } 
            if ($params.ContainsKey("UseSSL") -eq $true) { $newWebAppParams.Add("SecureSocketsLayer", $params.UseSSL) } 
         
            $wa = New-SPWebApplication @newWebAppParams
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
        [parameter(Mandatory = $true)]  [System.String]  $ApplicationPoolAccount,
        [parameter(Mandatory = $true)]  [System.String]  $Url,
        [parameter(Mandatory = $false)] [System.Boolean] $AllowAnonymous,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseName,
        [parameter(Mandatory = $false)] [System.String]  $DatabaseServer,
        [parameter(Mandatory = $false)] [System.String]  $HostHeader,
        [parameter(Mandatory = $false)] [System.String]  $Path,
        [parameter(Mandatory = $false)] [System.String]  $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $UseSSL,
        [parameter(Mandatory = $false)] [ValidateSet("NTLM","Kerberos")] [System.String] $AuthenticationMethod,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing for web application '$Name'"
    if ($null -eq $CurrentValues) { return $false }

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentValues `
                                                     -DesiredValues $PSBoundParameters `
                                                     -ValuesToCheck @("ApplicationPool")
    return $testReturn
}


Export-ModuleMember -Function *-TargetResource

