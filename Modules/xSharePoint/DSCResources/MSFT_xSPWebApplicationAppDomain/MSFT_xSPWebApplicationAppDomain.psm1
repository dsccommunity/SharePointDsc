function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $AppDomain,
        [parameter(Mandatory = $true)] [System.String] $Prefix,
        [parameter(Mandatory = $false)]  [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.UInt32] $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL

    )

    Write-Verbose -Message "Checking app urls settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $prefix = Get-SPAppSiteSubscriptionName -ErrorAction SilentlyContinue
        if($params.ContainsKey("WebApplication")){
            $params.Add("Confirm", $false)
            $ssl = $params | Remove-xSharePointParamValue -name "SSL" 
            $appDomain = $params | Remove-xSharePointParamValue -name "AppDomain"
            $port = $params | Remove-xSharePointParamValue -name "Port"
            $webAppAppDomain =   Get-SPWebApplicationAppDomain $params
            return @{
                AppDomain = $webAppAppDomain.AppDomain 
                WebApplication = $webAppAppDomain.WebApplication
                Zone = $webAppAppDomain.UrlZone
                Port = $webAppAppDomain.Port
                SSL = $webAppAppDomain.IsSchemeSSL
                Prefix= $prefix
                InstallAccount = $params.InstallAccount
            }
        }else{
            return @{
                AppDomain = Get-SPAppDomain
                Prefix= $prefix
                Zone = $null
                Port = $null
                SSL = $null
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)] [System.String] $AppDomain,
        [parameter(Mandatory = $true)] [System.String] $Prefix,
        [parameter(Mandatory = $false)] [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.UInt32] $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL
    )

    Write-Verbose -Message "Updating app domain settings "
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $prefix = $params | Remove-xSharePointParamValue -name "Prefix"
        if($prefix -ne $null){
            Set-SPAppSiteSubscriptionName -Name $prefix -Confirm:$false
        }

        if($params.ContainsKey("WebApplication")){
            $getParams = @{}
            $params.Add("Confirm", $false)
            $getParams.Add("ErrorAction", 0)
            $getParams.Add("WebApplication", $params.WebApplication)
            if($params.ContainsKey("Zone")){
                $getPArams.Add("Zone",$Params.Zone)
            }

            $appDomain = (Get-SPWebApplicationAppDomain  @getParams )
            $params = $params | Rename-xSharePointParamValue -oldName  "SSL"  -newName "SecureSocketsLayer"
            if($appDomain -ne $null){
                Remove-SPWebApplicationAppDomain $appDomain
                Sleep -Seconds 1
            }
               New-SPWebApplicationAppDomain @params
            
        }else{
            Set-SPAppDomain $params.AppDomain  -Confirm:$false    
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $AppDomain,
        [parameter(Mandatory = $true)] [System.String] $Prefix,
        [parameter(Mandatory = $false)] [System.String] $WebApplication,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.String] $Zone,
        [parameter(Mandatory = $false)] [System.UInt32] $Port,
        [parameter(Mandatory = $false)] [System.Boolean] $SSL
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AppDomain", "Prefix", "Zone", "SSL", "WebApplication") 
}


Export-ModuleMember -Function *-TargetResource

