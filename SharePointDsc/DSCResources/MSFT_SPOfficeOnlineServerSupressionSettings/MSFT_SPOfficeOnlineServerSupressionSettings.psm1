function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Extension,

        [Parameter()]
        [ValidateSet("attend", "attendservice", "convert", "edit", "editnew", "embedview", "formedit", "formsubmit", "imagepreview", "interactivepreview", "legacywebservice", "mobileView", "preloadedit", "preloadview", "present", "presentservice", "rest", "rtc", "syndicate", "view")]
        [System.String[]]
        $Actions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Getting Office Online Server suppression settings"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullreturn = @{
            Extension = $params.Extension
            Actions   = $null
            Ensure    = "Absent"
        }

        $allSupressed = Get-SPWOPISuppressionSetting

        if ($null -eq $allSupressed)
        {
            return $nullreturn
        }
        else
        {
            $supressedForExtension = $allSupressed | Where-Object -FilterScript {
                $_ -like "$($params.Extension) *"
            }

            if ($null -eq $supressedForExtension)
            {
                return $nullreturn
            }

            $extensionActions = $supressedForExtension -replace "$($params.Extension) "
            return @{
                Extension = $params.Extension
                Actions   = $extensionActions
                Ensure    = "Present"
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
        $Extension,

        [Parameter()]
        [ValidateSet("attend", "attendservice", "convert", "edit", "editnew", "embedview", "formedit", "formsubmit", "imagepreview", "interactivepreview", "legacywebservice", "mobileView", "preloadedit", "preloadview", "present", "presentservice", "rest", "rtc", "syndicate", "view")]
        [System.String[]]
        $Actions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Setting Office Online Server suppression settings"

    $CurrentResults = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($PSBoundParameters.ContainsKey("Actions") -eq $false)
        {
            $message = ("You have to specify the Actions parameter if Ensure is not set to Absent")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        Write-Verbose -Message "Updating supression settings"
        Invoke-SPDscCommand -Arguments @($PSBoundParameters, $CurrentResults) `
            -ScriptBlock {
            $params = $args[0]
            $currentResults = $args[1]

            foreach ($action in $params.Actions)
            {
                if ($action -notin $currentResults.Actions)
                {
                    Write-Verbose "Adding action $action"
                    $null = New-SPWOPISuppressionSetting -Extension $params.Extension `
                        -Action $action
                }
            }

            foreach ($action in $currentResults.Actions)
            {
                if ($action -notin $params.Actions)
                {
                    Write-Verbose "Removing action $action"
                    Remove-SPWOPISuppressionSetting -Extension $params.Extension `
                        -Action $action `
                        -Confirm:$false
                }
            }
        }
    }

    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing bindings for zone '$Zone'"
        Invoke-SPDscCommand -Arguments $CurrentResults `
            -ScriptBlock {
            $currentResults = $args[0]

            foreach ($action in $currentResults.Actions)
            {
                Write-Verbose "Removing action $action"
                Remove-SPWOPISuppressionSetting -Extension $currentResults.Extension `
                    -Action $action `
                    -Confirm:$false
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
        $Extension,

        [Parameter()]
        [ValidateSet("attend", "attendservice", "convert", "edit", "editnew", "embedview", "formedit", "formsubmit", "imagepreview", "interactivepreview", "legacywebservice", "mobileView", "preloadedit", "preloadview", "present", "presentservice", "rest", "rtc", "syndicate", "view")]
        [System.String[]]
        $Actions,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing Office Online Server suppression settings"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $paramsToCheck = @("Ensure")
    if ($Ensure -eq "Present")
    {
        $paramsToCheck += @("Actions")
    }
    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $paramsToCheck

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $allSupressed = Get-SPWOPISuppressionSetting

    $extensions = $allSupressed | ForEach-Object -Process {
        ($_ -split " ")[0]
    }  | Sort-Object -Unique

    try
    {
        if ($null -ne $allSupressed)
        {
            $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
            $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPOfficeOnlineServerSupressionSettings\MSFT_SPOfficeOnlineServerSupressionSettings.psm1" -Resolve
            $Content = ''
            $params = Get-DSCFakeParameters -ModulePath $module

            foreach ($extension in $extensions)
            {
                $PartialContent = "        SPOfficeOnlineServerSupressionSettings '$extension'`r`n"
                $PartialContent += "        {`r`n"
                $params.Extension = $extension
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
        $Global:ErrorLog += "[Office Online Server Supression Settings]`r`n"
        $Global:ErrorLog += "$_`r`n`r`n"
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
