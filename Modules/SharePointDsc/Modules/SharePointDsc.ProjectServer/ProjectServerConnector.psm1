function Get-SPDscProjectServerResourceId
{
    [OutputType([System.Guid])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PwaUrl
    )

    $resourceService = New-SPDscProjectServerWebService -PwaUrl $PwaUrl -EndpointName Resource

    $returnVal = $null
    Use-SPDscProjectServerWebService -Service $resourceService -ScriptBlock {
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Project.Server.Library") | Out-Null
        $ds = [SvcResource.ResourceDataSet]::new()

        $filter = New-Object -TypeName "Microsoft.Office.Project.Server.Library.Filter"
        $filter.FilterTableName = $ds.Resources.TableName

        $idColumn = New-Object -TypeName "Microsoft.Office.Project.Server.Library.Filter+Field" `
                               -ArgumentList @(
                                 $ds.Resources.TableName,
                                 $ds.Resources.RES_UIDColumn.ColumnName,
                                 [Microsoft.Office.Project.Server.Library.Filter+SortOrderTypeEnum]::None
                               )
        $filter.Fields.Add($idColumn)

        $nameFieldFilter = New-Object -TypeName "Microsoft.Office.Project.Server.Library.Filter+FieldOperator" `
                                      -ArgumentList @(
                                        [Microsoft.Office.Project.Server.Library.Filter+FieldOperationType]::Equal,
                                        $ds.Resources.RES_NAMEColumn.ColumnName,
                                        $ResourceName
                                      )
        $filter.Criteria = $nameFieldFilter
        
        $filterXml = $filter.GetXml()

        $resourceDs = $resourceService.ReadResources($filterXml, $false)
        if ($resourceDs.Resources.Count -ge 1)
        {
            $returnVal = $resourceDs.Resources[0].RES_UID
        }
        else
        {
            throw "Resource '$ResoruceName' not found"
        }
    }
    return $returnVal
}

function Get-SPDscProjectServerResourceName
{
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Guid]
        $ResourceId,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PwaUrl
    )

    $resourceService = New-SPDscProjectServerWebService -PwaUrl $PwaUrl -EndpointName Resource

    $returnVal = ""
    Use-SPDscProjectServerWebService -Service $resourceService -ScriptBlock {
        $userName = $resourceService.ReadResource($ResourceId).Resources.WRES_ACCOUNT
        if ($userName.Contains(":0") -eq $true)
        {
            $realUserName = New-SPClaimsPrincipal -Identity $userName `
                                                  -IdentityType EncodedClaim
            $returnVal = $realUserName.Value
        }
        else 
        {
            $returnVal = $userName
        }
    }
    return $returnVal
}

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
