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
        $ServiceAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting service application pool '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $sap = Get-SPServiceApplicationPool -Identity $params.Name `
            -ErrorAction SilentlyContinue
        if ($null -eq $sap)
        {
            return @{
                Name           = $params.Name
                ServiceAccount = $params.ProcessAccountName
                Ensure         = "Absent"
            }
        }
        return @{
            Name           = $sap.Name
            ServiceAccount = $sap.ProcessAccountName
            Ensure         = "Present"
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
        $ServiceAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting service application pool '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($CurrentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating Service Application Pool $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            New-SPServiceApplicationPool -Name $params.Name `
                -Account $params.ServiceAccount

            $sap = Get-SPServiceApplicationPool -Identity $params.Name `
                -ErrorAction SilentlyContinue
            if ($null -ne $sap)
            {
                if ($sap.ProcessAccountName -ne $params.ServiceAccount)
                {
                    Set-SPServiceApplicationPool -Identity $params.Name `
                        -Account $params.ServiceAccount
                }
            }
        }
    }
    if ($CurrentValues.Ensure -eq "Present" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating Service Application Pool $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $sap = Get-SPServiceApplicationPool -Identity $params.Name `
                -ErrorAction SilentlyContinue
            if ($sap.ProcessAccountName -ne $params.ServiceAccount)
            {
                Set-SPServiceApplicationPool -Identity $params.Name `
                    -Account $params.ServiceAccount
            }
        }
    }
    if ($Ensure -eq "Absent")
    {
        Write-Verbose -Message "Removing Service Application Pool $Name"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            Remove-SPServiceApplicationPool -Identity $params.Name -Confirm:$false
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
        $ServiceAccount,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing service application pool '$Name'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    if ($Ensure -eq "Present")
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("ServiceAccount", "Ensure")
    }
    else
    {
        $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck @("Ensure")
    }

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPServiceAppPool\MSFT_SPServiceAppPool.psm1" -Resolve
    $spServiceAppPools = Get-SPServiceApplicationPool | Sort-Object -Property Name
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module

    $i = 1
    $total = $spServiceAppPools.Length
    foreach ($spServiceAppPool in $spServiceAppPools)
    {
        try
        {
            $appPoolName = $spServiceAppPool.Name
            Write-Host "Scanning SPServiceApplicationPool [$i/$total] {$appPoolName}"
            $PartialContent = "        SPServiceAppPool " + $spServiceAppPool.Name.Replace(" ", "") + "`r`n"
            $PartialContent += "        {`r`n"
            $params.Name = $appPoolName
            $results = Get-TargetResource @params
            $results = Repair-Credentials -results $results

            $serviceAccount = Get-Credentials $results.ServiceAccount
            $convertToVariable = $false
            if ($serviceAccount)
            {
                $convertToVariable = $true
                $results.ServiceAccount = (Resolve-Credentials -UserName $results.ServiceAccount) + ".UserName"
            }

            if ($null -eq $results.Get_Item("AllowAnonymous"))
            {
                $results.Remove("AllowAnonymous")
            }
            $currentDSCBlock = Get-DSCBlock -Params $results -ModulePath $module
            if ($convertToVariable)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "ServiceAccount"
            }
            $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentDSCBlock

            $PartialContent += "        }`r`n"
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Service Application Pool]" + $spServiceAppPool.Name + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
