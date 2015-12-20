function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $false)] [System.String] $AppDomain,
        [parameter(Mandatory = $true)]  [System.String] $Prefix,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount

    )

    Write-Verbose -Message "Checking app urls settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $prefix = Get-SPAppSiteSubscriptionName
        if($params.ContainsKey("WebApplication")){
            $params.Add("Confirm", $false)
            $requestParams = @() 
            $requestParams.Add("WebApplication", $params.WebApplication) 
            if($requestParams.ContainsKey("Zone")) {
                $requestParams.Add("Zone", $params.Zone) 
            }
                $webAppAppDomain =   Get-SPWebApplicationAppDomain @requestParams
            return @{
                AppDomain = $webAppAppDomain.AppDomain 
                WebApplication = $webAppAppDomain.WebApplication
                Zone = $webAppAppDomain.Zone
                Port = $webAppAppDomain.Port
                SSL = $webAppAppDomain.SecureSocketsLayer
                Prefix= $prefix
                InstallAccount = $params.InstallAccount
            }
        }else{
            return @{
                AppDomain = Get-SPAppDomain
                Prefix= $prefix
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
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $Account,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $EmailNotification,
        [parameter(Mandatory = $false)] [System.UInt32] $PreExpireDays,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $true)]  [System.String] $AccountName
    )

  

    Write-Verbose -Message "Updating app domain settings "
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $prefix = $params | Remove-xSharePointParamValue -name "Prefix"
        if($prefix -ne $null){
            Set-SPAppSiteSubscriptionName -Name $params.Prefix -Confirm:$false
        }

        if($params.ContainsKey("WebApplication")){
            $params.Add("Confirm", $false)
            if((Get-SPWebApplicationAppDomain  -WebApplication $params.WebApplication )-ne $null){
                Update-SPWebApplicationAppDomain @params  
            }else{
                New-SPWebApplicationAppDomain @params
            }
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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $true)] [System.String] $AppDomain,
        [parameter(Mandatory = $false)]  [System.String] $Prefix
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing app domain settings"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AppDomain", "Prefix") 
}


Export-ModuleMember -Function *-TargetResource

