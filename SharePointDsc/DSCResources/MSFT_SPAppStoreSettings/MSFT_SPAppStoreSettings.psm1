$script:SPDscUtilModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\SharePointDsc.Util'
Import-Module -Name $script:SPDscUtilModulePath

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting app store settings of $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullreturn = @{
            WebAppUrl = $null
        }

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return $nullreturn
        }

        $currentAAP = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
        $AllowAppPurchases = [System.Convert]::ToBoolean($currentAAP)
        $currentAAFO = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enable
        $AllowAppsForOffice = [System.Convert]::ToBoolean($currentAAFO)

        return @{
            WebAppUrl          = $params.WebAppUrl
            AllowAppPurchases  = $AllowAppPurchases
            AllowAppsForOffice = $AllowAppsForOffice
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

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting app store settings of $WebAppUrl"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            $message = "Specified web application does not exist."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }

        if ($params.ContainsKey("AllowAppPurchases"))
        {
            $current = (Get-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl).Enabled
            $AllowAppPurchases = [System.Convert]::ToBoolean($current)
            if ($AllowAppPurchases -ne $params.AllowAppPurchases)
            {
                Set-SPAppAcquisitionConfiguration -WebApplication $params.WebAppUrl `
                    -Enable $params.AllowAppPurchases
            }
        }

        if ($params.ContainsKey("AllowAppsForOffice"))
        {
            $current = (Get-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl).Enable
            $AllowAppsForOffice = [System.Convert]::ToBoolean($current)
            if ($AllowAppsForOffice -ne $params.AllowAppsForOffice)
            {
                Set-SPOfficeStoreAppsDefaultActivation -WebApplication $params.WebAppUrl `
                    -Enable $params.AllowAppsForOffice
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
        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAppPurchases,

        [Parameter()]
        [System.Boolean]
        $AllowAppsForOffice,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing app store settings of $WebAppUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($null -eq $currentValues.WebAppUrl)
    {
        $message = "Specified web application does not exist."
        Write-Verbose -Message $message
        Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

        Write-Verbose -Message "Test-TargetResource returned false"
        return $false
    }

    if ($PSBoundParameters.ContainsKey("AllowAppPurchases"))
    {
        if ($AllowAppPurchases -ne $CurrentValues.AllowAppPurchases)
        {
            $message = ("The parameter AllowAppPurchases for web application $WebAppUrl " + `
                    "is not in the desired state. Actual: " + `
                    "$($CurrentValues.AllowAppPurchases), Desired: $AllowAppPurchases")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    if ($PSBoundParameters.ContainsKey("AllowAppsForOffice"))
    {
        if ($AllowAppsForOffice -ne $CurrentValues.AllowAppsForOffice)
        {
            $message = ("The parameter AllowAppsForOffice for web application $WebAppUrl " + `
                    "is not in the desired state. Actual: " + `
                    "$($CurrentValues.AllowAppsForOffice), Desired: $AllowAppsForOffice")
            Write-Verbose -Message $message
            Add-SPDscEvent -Message $message -EntryType 'Error' -EventID 1 -Source $MyInvocation.MyCommand.Source

            Write-Verbose -Message "Test-TargetResource returned false"
            return $false
        }
    }

    Write-Verbose -Message "Test-TargetResource returned true"
    return $true
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPAppStoreSettings\MSFT_SPAppStoreSettings.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication

    $i = 1
    $total = $webApps.Length
    foreach ($webApp in $webApps)
    {
        try
        {
            Write-Host "Scanning App Store Settings [$i/$total] for Web Application {$($webApp.Url)}"
            $PartialContent = "        SPAppStoreSettings " + $webApp.Name.Replace(" ", "") + [System.Guid]::NewGuid().ToString() + "`r`n"
            $PartialContent += "        {`r`n"
            $params.WebAppUrl = $webApp.Url
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $Content += $PartialContent
        }
        catch
        {
            $Global:ErrorLog += "[SPAppStoreSettings] Couldn't obtain information from App Store Settings for Web Application {$($webApp.Url)}`r`n"
        }
        $i++
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
