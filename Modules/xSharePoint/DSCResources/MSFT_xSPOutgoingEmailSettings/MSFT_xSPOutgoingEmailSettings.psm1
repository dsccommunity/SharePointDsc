function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $SMTPServer,
        [parameter(Mandatory = $true)]  [System.String] $FromAddress,
        [parameter(Mandatory = $true)]  [System.String] $ReplyToAddress,
        [parameter(Mandatory = $true)]  [System.String] $CharacterSet,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
        
    )

    Write-Verbose -Message "Retrieving outgoing email settings configuration "

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $webApp = Get-SPWebApplication $params.WebAppUrl -IncludeCentralAdministration -ErrorAction SilentlyContinue

        if ($null -eq $webApp) { 
            return $null
        }
        
        $mailServer = $null
        if ($webApp.OutboundMailServiceInstance -ne $null) {
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
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $SMTPServer,
        [parameter(Mandatory = $true)]  [System.String] $FromAddress,
        [parameter(Mandatory = $true)]  [System.String] $ReplyToAddress,
        [parameter(Mandatory = $true)]  [System.String] $CharacterSet,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Updating outgoing email settings configuration for $WebAppUrl"
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $webApp = $null
        Write-Verbose -Message "retrieving $($params.WebAppUrl)  settings"
        $webApp = Get-SPWebApplication $params.WebAppUrl -IncludeCentralAdministration 
        if($null -eq $webApp)
        {
            throw "Web Application $webAppUrl not found"
        }
        $webApp.UpdateMailSettings($params.SMTPServer, $params.FromAddress, $params.ReplyToAddress, $params.CharacterSet) 
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $SMTPServer,
        [parameter(Mandatory = $true)]  [System.String] $FromAddress,
        [parameter(Mandatory = $true)]  [System.String] $ReplyToAddress,
        [parameter(Mandatory = $true)]  [System.String] $CharacterSet,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Comparing Current and Target Outgoing email settings"
    if ($null -eq $CurrentValues) { return $false }
    
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("SMTPServer","FromAddress","ReplyToAddress","CharacterSet") 
}


Export-ModuleMember -Function *-TargetResource

