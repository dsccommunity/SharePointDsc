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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Access 2010 Service app '$Name'"

    $productVersion = Get-SPDscInstalledProductVersion
    if ($productVersion.FileMajorPart -eq 16 `
            -and $productVersion.FileBuildPart -gt 13000)
    {
        $message = ("Since SharePoint Server Subscription Edition the Access Services 2010 does no longer " + `
            "exists. See https://docs.microsoft.com/en-us/sharepoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2019#access-services-2013 " + `
            "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

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
            $_.GetType().FullName -eq "Microsoft.Office.Access.Server.MossHost.AccessServerWebServiceApplication"
        }

        if ($null -eq $serviceApp)
        {
            return $nullReturn
        }
        else
        {
            return @{
                Name            = $serviceApp.DisplayName
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Access 2010 Services app '$Name'"

    $productVersion = Get-SPDscInstalledProductVersion
    if ($productVersion.FileMajorPart -eq 16 `
            -and $productVersion.FileBuildPart -gt 13000)
    {
        $message = ("Since SharePoint Server Subscription Edition the Access Services 2010 does no longer " + `
            "exists. See https://docs.microsoft.com/en-us/sharepoint/what-s-new/what-s-deprecated-or-removed-from-sharepoint-server-2019#access-services-2013 " + `
            "for more info.")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose "Creating Access 2010 Service Application '$Name'"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $accessApp = New-SPAccessServiceApplication -Name $params.Name `
                -ApplicationPool $params.ApplicationPool
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose "Updating Access 2010 service application '$Name'"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            $apps = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name
            }

            if ($null -ne $apps)
            {
                $app = $apps | Where-Object -FilterScript {
                    $_.GetType().FullName -eq "Microsoft.Office.Access.Server.MossHost.AccessServerWebServiceApplication"
                }
                if ($null -ne $app)
                {
                    $appPool = Get-SPServiceApplicationPool -Identity $params.ApplicationPool
                    if ($null -ne $appPool)
                    {
                        $app.ApplicationPool = $appPool
                        $app.Update()
                        return;
                    }
                }
            }

            $accessApp = New-SPAccessServiceApplication -Name $params.Name `
                -ApplicationPool $params.ApplicationPool
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose "Removing Access 2010 service application '$Name'"
        Invoke-SPDscCommand -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $apps = Get-SPServiceApplication | Where-Object -FilterScript {
                $_.Name -eq $params.Name
            }

            if ($null -eq $apps)
            {
                return
            }

            $app = $apps | Where-Object -FilterScript {
                $_.GetType().FullName -eq "Microsoft.Office.Access.Server.MossHost.AccessServerWebServiceApplication"
            }

            if ($null -ne $app)
            {
                Remove-SPServiceApplication -Identity $app -Confirm:$false
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
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPool,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )
    Write-Verbose -Message "Testing Access 2010 service app '$Name'"

    $PSBoundParameters.Ensure = $Ensure
    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Name", "ApplicationPool", "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
