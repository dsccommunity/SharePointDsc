$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting web application '$Name' config"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
        if ($null -eq $wa)
        {
            return @{
                Name                   = $params.Name
                ApplicationPool        = $params.ApplicationPool
                ApplicationPoolAccount = $params.ApplicationPoolAccount
                WebAppUrl              = $params.WebAppUrl
                Ensure                 = "Absent"
            }
        }

        ### COMMENT: Are we making an assumption here, about Default Zone
        $classicAuth = $false
        $authProvider = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone "Default"
        if ($null -eq $authProvider)
        {
            $classicAuth = $true
        }

        $IISPath = $wa.IisSettings[0].Path
        if (-not [System.String]::IsNullOrEmpty($IISPath))
        {
            $IISPath = $IISPath.ToString()
        }
        return @{
            Name                   = $wa.DisplayName
            ApplicationPool        = $wa.ApplicationPool.Name
            ApplicationPoolAccount = $wa.ApplicationPool.Username
            WebAppUrl              = $wa.Url
            AllowAnonymous         = $authProvider.AllowAnonymous
            DatabaseName           = $wa.ContentDatabases[0].Name
            DatabaseServer         = $wa.ContentDatabases[0].Server
            HostHeader             = (New-Object -TypeName System.Uri $wa.Url).Host
            Path                   = $IISPath
            Port                   = (New-Object -TypeName System.Uri $wa.Url).Port
            UseClassic             = $classicAuth
            Ensure                 = "Present"
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting web application '$Name' config"

    $PSBoundParameters.UseClassic = $UseClassic

    if ($Ensure -eq "Present")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -eq $wa)
            {
                $newWebAppParams = @{
                    Name            = $params.Name
                    ApplicationPool = $params.ApplicationPool
                    Url             = $params.WebAppUrl
                }

                # Get a reference to the Administration WebService
                $admService = Get-SPDscContentService
                $appPools = $admService.ApplicationPools | Where-Object -FilterScript {
                    $_.Name -eq $params.ApplicationPool
                }
                if ($null -eq $appPools)
                {
                    # Application pool does not exist, create a new one.
                    # Test if the specified managed account exists. If so, add
                    # ApplicationPoolAccount parameter to create the application pool
                    try
                    {
                        Get-SPManagedAccount $params.ApplicationPoolAccount -ErrorAction Stop | Out-Null
                        $newWebAppParams.Add("ApplicationPoolAccount", $params.ApplicationPoolAccount)
                    }
                    catch
                    {
                        if ($_.Exception.Message -like "*No matching accounts were found*")
                        {
                            throw ("The specified managed account was not found. Please make " + `
                                    "sure the managed account exists before continuing.")
                            return
                        }
                        else
                        {
                            throw ("Error occurred. Web application was not created. Error " + `
                                    "details: $($_.Exception.Message)")
                            return
                        }
                    }
                }

                if ($params.UseClassic -eq $false)
                {
                    $ap = New-SPAuthenticationProvider
                    $newWebAppParams.Add("AuthenticationProvider", $ap)
                }

                if ($params.ContainsKey("AllowAnonymous") -eq $true)
                {
                    $newWebAppParams.Add("AllowAnonymousAccess", $params.AllowAnonymous)
                }
                if ($params.ContainsKey("DatabaseName") -eq $true)
                {
                    $newWebAppParams.Add("DatabaseName", $params.DatabaseName)
                }
                if ($params.ContainsKey("DatabaseServer") -eq $true)
                {
                    $newWebAppParams.Add("DatabaseServer", $params.DatabaseServer)
                }
                if ($params.ContainsKey("HostHeader") -eq $true)
                {
                    $newWebAppParams.Add("HostHeader", $params.HostHeader)
                }
                if ($params.ContainsKey("Path") -eq $true)
                {
                    $newWebAppParams.Add("Path", $params.Path)
                }
                if ($params.ContainsKey("Port") -eq $true)
                {
                    $newWebAppParams.Add("Port", $params.Port)
                }
                if ((New-Object -TypeName System.Uri $params.WebAppUrl).Scheme -eq "https")
                {
                    $newWebAppParams.Add("SecureSocketsLayer", $true)
                }
                if ($params.useSQLAuthentication -eq $true)
                {
                    Write-Verbose -Message "Using SQL authentication to create web app as `$useSQLAuthentication is set to $($params.useSQLAuthentication)."
                    $newWebAppParams.Add("DatabaseCredentials", $params.DatabaseCredentials)
                }
                else
                {
                    Write-Verbose -Message "`$useSQLAuthentication is false or not specified; using default Windows authentication."
                }

                New-SPWebApplication @newWebAppParams | Out-Null
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $wa = Get-SPWebApplication -Identity $params.Name -ErrorAction SilentlyContinue
            if ($null -ne $wa)
            {
                $wa | Remove-SPWebApplication -Confirm:$false -DeleteIISSite
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

        [Parameter(Mandatory = $true)]
        [System.String]
        $ApplicationPoolAccount,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [Parameter()]
        [System.Boolean]
        $AllowAnonymous,

        [Parameter()]
        [System.String]
        $DatabaseName,

        [Parameter()]
        [System.String]
        $DatabaseServer,

        [Parameter()]
        [System.Boolean]
        $UseSQLAuthentication,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter()]
        [System.String]
        $HostHeader,

        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseClassic = $false,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing for web application '$Name' config"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource {
    $content = ''
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPWebApplication\MSFT_SPWebApplication.psm1" -Resolve    

    $spWebApplications = Get-SPWebApplication | Sort-Object -Property Name


    $i = 1;
    $total = $spWebApplications.Length
    foreach($spWebApp in $spWebApplications)
    {
        try
        {
            Write-Host "Scanning SPWebApplication [$i/$total] {$webAppName}"
            $partialContent = "        SPWebApplication " + $spWebApp.Name.Replace(" ", "") + "`r`n        {`r`n"
            
            $params = Get-DSCFakeParameters -ModulePath $module
            $params.Name = $spWebApp.name

            $results = Get-TargetResource @params

            $results = Repair-Credentials -results $results

            $appPoolAccount = Get-Credentials $results.ApplicationPoolAccount
            $convertToVariable = $false
            if($appPoolAccount)
            {
                $convertToVariable = $true
                $results.ApplicationPoolAccount = (Resolve-Credentials -UserName $results.ApplicationPoolAccount) + ".UserName"
            }

            if($null -eq $results.Get_Item("AllowAnonymous"))
            {
                $results.Remove("AllowAnonymous")
            }

            Add-ConfigurationDataEntry -Node "NonNodeData" -Key "DatabaseServer" -Value $results.DatabaseServer -Description "Name of the Database Server associated with the destination SharePoint Farm;"
            $results.DatabaseServer = "`$ConfigurationData.NonNodeData.DatabaseServer"
            $results["Path"] = $results["Path"].ToString()
            $currentDSCBlock = Get-DSCBlock -Params $results -ModulePath $PSScriptRoot
            if($convertToVariable)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "ApplicationPoolAccount"
            }
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "DatabaseServer"
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "PsDscRunAsCredential"
            $partialContent += $currentDSCBlock
            $partialContent += "        }`r`n"

            if($Global:ExtractionModeValue -ge 2)
            {
                Write-Host "    -> Scanning SharePoint Designer Settings"
                #Read-SPDesignerSettings -WebAppUrl $results.WebAppUrl.ToString() -Scope "WebApplication" -WebAppName $spWebApp.Name.Replace(" ", "")
            }

            <# SPWebApplication Feature Section #>
            if(($Global:ExtractionModeValue -eq 3 -and $Quiet) -or $Global:ComponentsToExtract.Contains("SPFeature"))
            {
                $partialContent += Read-TargetResource -ResourceName SPFeature -ExportParams @{Scope = "WebApplication"; Url = $SpWebApp.Url; DependsOn="[SPWebApplication]$($spWebApp.Name.Replace(' ', ''))";}
            }
            $partialContent += Read-TargetResource -ResourceName SPOutgoingEmailSettings -ExportParams @{WebAppUrl = $spWebApp.Url; DependsOn="[SPWebApplication]$($spWebApp.Name.Replace(' ', ''))";}
            $i++
        }
        catch
        {
            $_
            $Global:ErrorLog += "[Web Application]" + $spWebApp.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }

        $content += $partialContent
    }
    Return $content
}

Export-ModuleMember -Function *-TargetResource
