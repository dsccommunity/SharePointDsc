function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting $WebAppUrl Service Proxy Group Association"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $WebApp = Get-SPWebApplication $params.WebAppUrl
        if (!$WebApp)
        {
            return  @{
                WebAppUrl            = $null
                ServiceAppProxyGroup = $null
            }
        }

        if ($WebApp.ServiceApplicationProxyGroup.friendlyname -eq "[default]")
        {
            $ServiceAppProxyGroup = "Default"
        }
        else
        {
            $ServiceAppProxyGroup = $WebApp.ServiceApplicationProxyGroup.name
        }

        return @{
            WebAppUrl            = $params.WebAppUrl
            ServiceAppProxyGroup = $ServiceAppProxyGroup
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting $WebAppUrl Service Proxy Group Association"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        if ($params.ServiceAppProxyGroup -eq "Default")
        {
            $params.ServiceAppProxyGroup = "[default]"
        }

        Set-SPWebApplication -Identity $params.WebAppUrl `
            -ServiceApplicationProxyGroup $params.ServiceAppProxyGroup
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
        $WebAppUrl,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ServiceAppProxyGroup,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing $WebAppUrl Service Proxy Group Association"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if (($null -eq $CurrentValues.WebAppUrl) -or ($null -eq $CurrentValues.ServiceAppProxyGroup))
    {
        $message = "Specified web application {$WebAppUrl} does not exist."
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        $result = $false
    }
    else
    {
        if ($CurrentValues.ServiceAppProxyGroup -eq $ServiceAppProxyGroup)
        {
            $result = $true
        }
        else
        {
            $message = ("Current ServiceAppProxyGroup {$($CurrentValues.ServiceAppProxyGroup)} " + `
                    "is not in the desired state {$ServiceAppProxyGroup}.")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            $result = $false
        }
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPWebAppProxyGroup\MSFT_SPWebAppProxyGroup.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $webApps = Get-SPWebApplication
    foreach ($wa in $webApps)
    {
        try
        {
            if ($null -ne $wa)
            {
                $params.WebAppUrl = $wa.Url
                $params.ServiceAppProxyGroup = $wa.ServiceApplicationProxyGroup.FriendlyName
                $PartialContent = "        SPWebAppProxyGroup " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"
                $results = Get-TargetResource @params

                if ($results.Contains("InstallAccount"))
                {
                    $results.Remove("InstallAccount")
                }
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
                $Content += $PartialContent
            }
        }
        catch
        {
            $Global:ErrorLog += "[Web Application Proxy Group]" + $wa.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
