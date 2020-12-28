function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting app catalog status of $SiteUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $site = Get-SPSite $params.SiteUrl -ErrorAction SilentlyContinue
        $nullreturn = @{
            SiteUrl = $null
        }
        if ($null -eq $site)
        {
            Write-Verbose -Message "Could not find site collection"
            return $nullreturn
        }
        $wa = $site.WebApplication
        $feature = $wa.Features.Item([Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5828"))
        if ($null -eq $feature)
        {
            Write-Verbose -Message "Could not find app catalog feature in site collection"
            return $nullreturn
        }
        if ($site.ID -ne $feature.Properties["__AppCatSiteId"].Value)
        {
            Write-Verbose -Message "AppCatSiteId does not match Site ID"
            return $nullreturn
        }
        return @{
            SiteUrl = $site.Url
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
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting app catalog status of $SiteUrl"

    Write-Verbose -Message "Retrieving farm account"
    $farmAccount = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        return Get-SPDscFarmAccount
    }

    Write-Verbose -Message "Check if InstallAccount or PsDscRunAsCredential is the farm account"
    if ($null -ne $farmAccount)
    {
        if ($PSBoundParameters.ContainsKey("InstallAccount") -eq $true)
        {
            # InstallAccount used
            if ($InstallAccount.UserName -eq $farmAccount.UserName)
            {
                $message = ("Specified InstallAccount ($($InstallAccount.UserName)) is the Farm " + `
                        "Account. Make sure the specified InstallAccount isn't the Farm Account " + `
                        "and try again")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $MyInvocation.MyCommand.Source
                throw $message
            }
        }
        else
        {
            # PSDSCRunAsCredential or System
            if (-not $Env:USERNAME.Contains("$"))
            {
                # PSDSCRunAsCredential used
                $localaccount = "$($Env:USERDOMAIN)\$($Env:USERNAME)"
                if ($localaccount -eq $farmAccount.UserName)
                {
                    $message = ("Specified PSDSCRunAsCredential ($localaccount) is the Farm " + `
                            "Account. Make sure the specified PSDSCRunAsCredential isn't the " + `
                            "Farm Account and try again")
                    Add-SPDscEvent -Message $message `
                        -EntryType 'Error' `
                        -EventID 100 `
                        -Source $MyInvocation.MyCommand.Source
                    throw $message
                }
            }
        }
    }
    else
    {
        $message = "Unable to retrieve the Farm Account. Check if the farm exists."
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    # Add the FarmAccount to the local Administrators group, if it's not already there
    $isLocalAdmin = Test-SPDscUserIsLocalAdmin -UserName $farmAccount.UserName

    if (!$isLocalAdmin)
    {
        Write-Verbose -Message "Adding farm account to Local Administrators group"
        Add-SPDscUserToLocalAdmin -UserName $farmAccount.UserName

        # Cycle the Timer Service and flush Kerberos tickets
        # so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"

        Clear-SPDscKerberosToken -Account $farmAccount.UserName
    }

    Invoke-SPDscCommand -Credential $farmAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            Update-SPAppCatalogConfiguration -Site $params.SiteUrl -Confirm:$false
        }
        catch [System.UnauthorizedAccessException]
        {
            $message = ("This resource must be run as the farm account (not a setup account). " + `
                    "Please ensure either the PsDscRunAsCredential or InstallAccount " + `
                    "credentials are set to the farm account and run this resource again")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
        }
    } | Out-Null

    # Remove the FarmAccount from the local Administrators group, if it was added above
    if (!$isLocalAdmin)
    {
        Write-Verbose -Message "Removing farm account from Local Administrators group"
        Remove-SPDscUserToLocalAdmin -UserName $farmAccount.UserName

        # Cycle the Timer Service and flush Kerberos tickets
        # so that it picks up the local Admin token
        Restart-Service -Name "SPTimerV4"

        Clear-SPDscKerberosToken -Account $farmAccount.UserName
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
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing app catalog status of $SiteUrl"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("SiteUrl")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPAppCatalog\MSFT_SPAppCatalog.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $webApps = Get-SPWebApplication

    foreach ($webApp in $webApps)
    {
        try
        {
            $feature = $webApp.Features.Item([Guid]::Parse("f8bea737-255e-4758-ab82-e34bb46f5828"))
            if ($null -ne $feature)
            {
                $appCatalogSiteId = $feature.Properties["__AppCatSiteId"].Value
                $appCatalogSite = $webApp.Sites | Where-Object { $_.ID -eq $appCatalogSiteId }

                if ($null -ne $appCatalogSite)
                {
                    $params = Get-DSCFakeParameters -ModulePath $module

                    $catUrl = $appCatalogSite.Url
                    Write-Host "Scanning App Catalog {$catUrl}"
                    $PartialContent = "        SPAppCatalog " + [System.Guid]::NewGuid().ToString() + "`r`n"
                    $PartialContent += "        {`r`n"
                    $params.SiteUrl = $catUrl
                    $results = Get-TargetResource @params
                    $results = Repair-Credentials -results $results
                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                    $Content += $PartialContent
                }
            }
        }
        catch
        {
            $Global:ErrorLog += "[App Catalog]" + $webApp.Url + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
