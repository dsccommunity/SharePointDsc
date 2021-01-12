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
        $RelativeUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting managed path $RelativeUrl in $WebAppUrl"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $getParams = @{
            Identity = $params.RelativeUrl
        }
        if ($params.HostHeader)
        {
            $getParams.Add("HostHeader", $true)
        }
        else
        {
            $getParams.Add("WebApplication", $params.WebAppUrl)
        }
        $path = Get-SPManagedPath @getParams -ErrorAction SilentlyContinue
        if ($null -eq $path)
        {
            return @{
                WebAppUrl   = $params.WebAppUrl
                RelativeUrl = $params.RelativeUrl
                Explicit    = $params.Explicit
                HostHeader  = $params.HostHeader
                Ensure      = "Absent"
            }
        }

        return @{
            RelativeUrl = $path.Name
            Explicit    = ($path.Type -eq "ExplicitInclusion")
            WebAppUrl   = $params.WebAppUrl
            HostHeader  = $params.HostHeader
            Ensure      = "Present"
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
        $RelativeUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting managed path $RelativeUrl in $WebAppUrl"

    $CurrentResults = Get-TargetResource @PSBoundParameters

    if ($CurrentResults.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating the managed path $RelativeUrl in $WebAppUrl"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $newParams = @{
                RelativeURL = $params.RelativeUrl
                Explicit    = $params.Explicit
            }
            if ($params.HostHeader)
            {
                $newParams.Add("HostHeader", $params.HostHeader)
            }
            else
            {
                $newParams.Add("WebApplication", $params.WebAppUrl)
            }
            New-SPManagedPath @newParams
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing the managed path $RelativeUrl from $WebAppUrl"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $removeParams = @{
                Identity = $params.RelativeUrl
            }
            if ($params.HostHeader)
            {
                $removeParams.Add("HostHeader", $params.HostHeader)
            }
            else
            {
                $removeParams.Add("WebApplication", $params.WebAppUrl)
            }

            Remove-SPManagedPath @removeParams -Confirm:$false
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $RelativeUrl,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Explicit,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $HostHeader,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing managed path $RelativeUrl in $WebAppUrl"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("WebAppUrl",
        "RelativeUrl",
        "Explicit",
        "HostHeader",
        "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPManagedPath\MSFT_SPManagedPath.psm1" -Resolve
    $Content = ''
    $spWebApps = Get-SPWebApplication
    $params = Get-DSCFakeParameters -ModulePath $module

    foreach ($spWebApp in $spWebApps)
    {
        $spManagedPaths = Get-SPManagedPath -WebApplication $spWebApp.Url | Sort-Object -Property Name

        $i = 1
        $total = $spManagedPaths.Length
        foreach ($spManagedPath in $spManagedPaths)
        {
            try
            {
                Write-Host "Scanning Web Application Managed Path [$i/$total] {"$spManagedPath.Name"}"
                if ($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
                {
                    $PartialContent = "        SPManagedPath " + [System.Guid]::NewGuid().toString() + "`r`n"
                    $PartialContent += "        {`r`n"
                    if ($null -ne $spManagedPath.Name)
                    {
                        $params.RelativeUrl = $spManagedPath.Name
                    }
                    $params.WebAppUrl = $spWebApp.Url
                    $params.HostHeader = $false;
                    if ($params.Contains("InstallAccount"))
                    {
                        $params.Remove("InstallAccount")
                    }
                    $results = Get-TargetResource @params

                    $results = Repair-Credentials -results $results

                    $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                    $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                    $PartialContent += $currentBlock
                    $PartialContent += "        }`r`n"
                }
                $i++
            }
            catch
            {
                $Global:ErrorLog += "[Web Application Managed Path]" + $spManagedPath.Name + "`r`n"
                $Global:ErrorLog += "$_`r`n`r`n"
            }
            $Content += $PartialContent
        }
    }
    $spManagedPaths = Get-SPManagedPath -HostHeader | Sort-Object -Property Name
    $i = 0
    $total = $spManagedPaths.Length
    foreach ($spManagedPath in $spManagedPaths)
    {
        try
        {
            Write-Host "Scanning Host Header Managed Path [$i/$total] {"$spManagedPath.Name"}"
            if ($spManagedPath.Name.Length -gt 0 -and $spManagedPath.Name -ne "sites")
            {
                $PartialContent = "        SPManagedPath " + [System.Guid]::NewGuid().toString() + "`r`n"
                $PartialContent += "        {`r`n"

                if ($null -ne $spManagedPath.Name)
                {
                    $params.RelativeUrl = $spManagedPath.Name
                }
                if ($params.ContainsKey("Explicit"))
                {
                    $params.Explicit = ($spManagedPath.Type -eq "ExplicitInclusion")
                }
                else
                {
                    $params.Add("Explicit", ($spManagedPath.Type -eq "ExplicitInclusion"))
                }
                $params.WebAppUrl = "*"
                $params.HostHeader = $true;
                $results = Get-TargetResource @params
                $results = Repair-Credentials -results $results
                $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
                $PartialContent += $currentBlock
                $PartialContent += "        }`r`n"
            }
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Host Header Managed Path]" + $spManagedPath.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
