function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Visio Graphics service app '$Name'"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication | Where-Object -FilterScript {
            $_.Name -eq $params.Name
        }

        $nullReturn = @{
            Name            = $params.Name
            ApplicationPool = $params.ApplicationPool
            Ensure          = "Absent"
        }
        if ($null -eq $serviceApps)
        {
            return $nullReturn
        }
        $serviceApp = $serviceApps | Where-Object -FilterScript {
            $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            $serviceAppProxies = Get-SPServiceApplicationProxy -ErrorAction SilentlyContinue
            if ($null -ne $serviceAppProxies)
            {
                $serviceAppProxy = $serviceAppProxies | Where-Object -FilterScript {
                    $serviceApp.IsConnected($_)
                }
                if ($null -ne $serviceAppProxy)
                {
                    $proxyName = $serviceAppProxy.Name
                }
            }

            return @{
                Name            = $serviceApp.DisplayName
                ProxyName       = $proxyName
                ApplicationPool = $serviceApp.ApplicationPool.Name
                Ensure          = "Present"
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Visio Graphics service app '$Name'"

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Visio Graphics Service Application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $visioApp = New-SPVisioServiceApplication -Name $params.Name `
                -ApplicationPool $params.ApplicationPool

            if ($params.ContainsKey("ProxyName"))
            {
                $pName = $params.ProxyName
                $params.Remove("ProxyName") | Out-Null
            }

            if ($null -eq $pName)
            {
                $pName = "$($params.Name) Proxy"
            }
            if ($null -ne $visioApp)
            {
                New-SPVisioServiceApplicationProxy -Name $pName `
                    -ServiceApplication $visioApp.Name | Out-Null
            }
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        if ($ApplicationPool -ne $result.ApplicationPool)
        {
            Write-Verbose -Message "Updating Visio Graphics Service Application $Name"
            Invoke-SPDscCommand -Arguments $PSBoundParameters `
                -ScriptBlock {
                $params = $args[0]

                $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool

                Get-SPServiceApplication | Where-Object -FilterScript {
                    $_.Name -eq $params.Name -and `
                    $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
                } | Set-SPVisioServiceApplication -ServiceApplicationPool $appPool
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Visio service application $Name"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $app = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name -and `
                $_.GetType().FullName -eq "Microsoft.Office.Visio.Server.Administration.VisioGraphicsServiceApplication"
            }

            $proxies = Get-SPServiceApplicationProxy
            foreach ($proxyInstance in $proxies)
            {
                if ($app.IsConnected($proxyInstance))
                {
                    $proxyInstance.Delete()
                }
            }

            Remove-SPServiceApplication -Identity $app -Confirm:$false
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [System.String]
        $ProxyName,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing Visio Graphics service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("ApplicationPool", "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPVisioServiceApp\MSFT_SPVisioServiceApp.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $serviceApps = Get-SPServiceApplication | Where-Object { $_.GetType().Name -eq "VisioGraphicsServiceApplication" }

    $i = 1
    $total = $serviceApps.Length
    foreach ($serviceApp in $serviceApps)
    {
        try
        {
            if ($null -ne $serviceApp)
            {
                $serviceName = $serviceApp.Name
                Write-Host "Scanning Visio Service Application [$i/$total] {$serviceName}"

                $params.Name = $serviceName
                $PartialContent = "        SPVisioServiceApp " + $serviceApp.Name.Replace(" ", "") + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Visio Graphics Service Application]" + $serviceApp.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
