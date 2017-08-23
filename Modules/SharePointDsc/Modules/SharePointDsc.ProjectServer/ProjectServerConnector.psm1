function New-SPDscProjectServerWebService
{
    [OutputType([System.IDisposable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PwaUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Admin", "Archive", "Calendar", "CubeAdmin", "CustomFields", 
                     "Driver", "Events", "LookupTable", "Notifications", "ObjectLinkProvider", 
                     "PortfolioAnalyses", "Project", "QueueSystem", "ResourcePlan", "Resource", 
                     "Security", "Statusing", "TimeSheet", "Workflow", "WssInterop")] 
        $EndpointName
    )

    $psDllPath = Join-Path -Path $PSScriptRoot -ChildPath "ProjectServerServices.dll"
    Add-Type -Path $psDllPath
    $maxSize = 500000000
    $svcRouter = "_vti_bin/PSI/ProjectServer.svc"
    $pwaUri = New-Object -TypeName "System.Uri" -ArgumentList $pwaUrl
    
    if ($pwaUri.Scheme -eq [System.Uri]::UriSchemeHttps)
    {
        $binding = New-Object -TypeName "System.ServiceModel.BasicHttpBinding" `
                              -ArgumentList ([System.ServiceModel.BasicHttpSecurityMode]::Transport)
    }
    else 
    {
        $binding = New-Object -TypeName "System.ServiceModel.BasicHttpBinding" `
                              -ArgumentList ([System.ServiceModel.BasicHttpSecurityMode]::TransportCredentialOnly)
    }
    $binding.Name = "basicHttpConf"
    $binding.SendTimeout = [System.TimeSpan]::MaxValue
    $binding.MaxReceivedMessageSize = $maxSize
    $binding.ReaderQuotas.MaxNameTableCharCount = $maxSize
    $binding.MessageEncoding = [System.ServiceModel.WSMessageEncoding]::Text
    $binding.Security.Transport.ClientCredentialType = [System.ServiceModel.HttpClientCredentialType]::Ntlm
    
    if ($pwaUrl.EndsWith('/') -eq $false)
    {
        $pwaUrl = $pwaUrl + "/"
    }
    $address = New-Object -TypeName "System.ServiceModel.EndpointAddress" `
                          -ArgumentList ($pwaUrl + $svcRouter)
    
    $webService = New-Object -TypeName "Svc$($EndpointName).$($EndpointName)Client" `
                             -ArgumentList @($binding, $address)

    $webService.ChannelFactory.Credentials.Windows.AllowedImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::Impersonation

    return $webService
}

function Use-SPDscProjectServerWebService
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IDisposable] 
        $Service,
        
        [Parameter(Mandatory = $true)]
        [ScriptBlock] 
        $ScriptBlock
    )
 
    try
    {
        & $ScriptBlock
    }
    finally
    {
        if ($null -ne $Service)
        {
            $Service.Dispose()
        }
    }
}

Export-ModuleMember -Function *
