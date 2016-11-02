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
        $SMTPServer,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $FromAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ReplyToAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $CharacterSet,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting outgoing email settings configuration for $WebAppUrl"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        $webApp = Get-SPWebApplication -Identity $params.WebAppUrl `
                                       -IncludeCentralAdministration `
                                       -ErrorAction SilentlyContinue

        if ($null -eq $webApp) 
        { 
            return $null
        }
        
        $mailServer = $null
        if ($null -ne $webApp.OutboundMailServiceInstance) 
        {
            $mailServer = $webApp.OutboundMailServiceInstance.Server.Name
        }
        
        return @{
            WebAppUrl = $webApp.Url
            SMTPServer= $mailServer
            FromAddress= $webApp.OutboundMailSenderAddress
            ReplyToAddress= $webApp.OutboundMailReplyToAddress
            CharacterSet = $webApp.OutboundMailCodePage
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
        $SMTPServer,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $FromAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ReplyToAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $CharacterSet,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting outgoing email settings configuration for $WebAppUrl"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        $webApp = $null

        Write-Verbose -Message "Retrieving $($params.WebAppUrl)  settings"
        
        $webApp = Get-SPWebApplication $params.WebAppUrl -IncludeCentralAdministration 
        if ($null -eq $webApp)
        {
            throw "Web Application $webAppUrl not found"
        }
        $webApp.UpdateMailSettings($params.SMTPServer, `
                                   $params.FromAddress, `
                                   $params.ReplyToAddress, `
                                   $params.CharacterSet) 
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
        $SMTPServer,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $FromAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $ReplyToAddress,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $CharacterSet,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting outgoing email settings configuration for $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false
    }
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("SMTPServer",
                                                     "FromAddress",
                                                     "ReplyToAddress",
                                                     "CharacterSet") 
}

Export-ModuleMember -Function *-TargetResource
