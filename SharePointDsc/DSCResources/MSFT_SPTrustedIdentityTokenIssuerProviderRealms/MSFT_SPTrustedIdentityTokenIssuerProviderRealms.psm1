function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$IssuerName,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present"
    )

    if ($ProviderRealms.Count -gt 0 -and ($ProviderRealmsToInclude.Count -gt 0 -or $ProviderRealmsToExclude.Count -gt 0))
    {
        $message = ("Cannot use the ProviderRealms parameter together with the " + `
                "ProviderRealmsToInclude or ProviderRealmsToExclude parameters")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    if ($ProviderRealms.Count -eq 0 -and $ProviderRealmsToInclude.Count -eq 0 -and $ProviderRealmsToExclude.Count -eq 0)
    {
        $message = ("At least one of the following parameters must be specified: " + `
                "ProviderRealms, ProviderRealmsToInclude, ProviderRealmsToExclude")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $paramRealms = @{ }
    $includeRealms = @{ }
    $excludeRealms = @{ }

    if ($ProviderRealms.Count -gt 0)
    {
        $ProviderRealms | ForEach-Object {
            $paramRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
        }
    }

    if ($ProviderRealmsToInclude.Count -gt 0)
    {
        $ProviderRealmsToInclude | ForEach-Object {
            $includeRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
        }
    }

    if ($ProviderRealmsToExclude.Count -gt 0)
    {
        $ProviderRealmsToExclude | ForEach-Object {
            $excludeRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
        }
    }

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer ProviderRealms"

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]
        $currentRealms = @{ }

        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
            -ErrorAction SilentlyContinue

        if ($null -eq $spTrust)
        {
            Write-Verbose -Message "SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found"
            return $null
        }

        if ($spTrust.ProviderRealms.Count -gt 0)
        {
            $spTrust.ProviderRealms.Keys | ForEach-Object {
                $currentRealms.Add("$($_.ToString())", "$($spTrust.ProviderRealms[$_])")
            }
        }
        return $currentRealms
    }

    if ($null -eq $result)
    {
        return @{
            IssuerName              = $IssuerName
            ProviderRealms          = $null
            ProviderRealmsToInclude = $null
            ProviderRealmsToExclude = $null
            CurrentRealms           = $null
            RealmsToAdd             = $null
            Ensure                  = "Absent"
        }
    }
    $currentStatus = Get-ProviderRealmsStatus -currentRealms $result `
        -desiredRealms $paramRealms `
        -includeRealms $includeRealms `
        -excludeRealms $excludeRealms `
        -Ensure $Ensure

    return @{
        IssuerName              = $IssuerName
        ProviderRealms          = $paramRealms
        ProviderRealmsToInclude = $includeRealms
        ProviderRealmsToExclude = $excludeRealms
        CurrentRealms           = $result
        RealmsToAdd             = $currentStatus.NewRealms
        Ensure                  = $currentStatus.CurrentStatus
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $IssuerName,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present"
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($CurrentValues.RealmsToAdd.Count -gt 0)
    {
        $PSBoundParameters.Add('RealmsToAdd', $CurrentValues.RealmsToAdd)

        Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer provider realms"
        $null = Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
            -ScriptBlock {
            $params = $args[0]
            $eventSource = $args[1]

            $trust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                -ErrorAction SilentlyContinue

            if ($null -eq $trust)
            {
                $message = ("SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found")
                Add-SPDscEvent -Message $message `
                    -EntryType 'Error' `
                    -EventID 100 `
                    -Source $eventSource
                throw $message
            }

            $trust.ProviderRealms.Clear()
            $params.RealmsToAdd.Keys | ForEach-Object {
                Write-Verbose "Setting Realm: $([System.Uri]$_)=$($params.RealmsToAdd[$_])"
                $trust.ProviderRealms.Add([System.Uri]$_, $params.RealmsToAdd[$_])
            }
            $trust.Update()
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $IssuerName,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToInclude,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealmsToExclude,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]
        $Ensure = "Present"
    )

    Write-Verbose -Message "Testing SPTrustedIdentityTokenIssuer provider realms"

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

Export-ModuleMember -Function *-TargetResource

function Get-ProviderRealmsStatus()
{
    param
    (
        [Parameter()]
        $currentRealms = $null,

        [Parameter()]
        $desiredRealms = $null,

        [Parameter()]
        $includeRealms = $null,

        [Parameter()]
        $excludeRealms = $null,

        [Parameter()]
        $Ensure = "Present"
    )

    $res = $null
    $res = New-Object PsObject
    Add-Member -InputObject $res -Name "CurrentStatus" -MemberType NoteProperty -Value $null
    Add-Member -InputObject $res -Name "NewRealms" -MemberType NoteProperty -Value $null
    $res.CurrentStatus = "Present"
    $res.NewRealms = $null

    if ($currentRealms.Count -eq 0)
    {
        $res.CurrentStatus = "Present"
        $res.NewRealms = @{ }

        if ($desiredRealms.Count -gt 0)
        {
            $res.CurrentStatus = "Absent"
            $res.NewRealms = $desiredRealms
        }
        else
        {
            if ($includeRealms.Count -gt 0)
            {
                if ($excludeRealms.Count -gt 0)
                {
                    $excludeRealms.Keys | Where-Object
                    {
                        $includeRealms.ContainsKey($_) -and $includeRealms[$_] -eq $excludeRealms[$_]
                    } | ForEach-Object { $includeRealms.Remove($_) }
                }

                $res.CurrentStatus = "Absent"
                $res.NewRealms = $includeRealms
            }
        }
        return $res
    }

    if ($Ensure -eq "Present")
    {
        if ($desiredRealms.Count -gt 0)
        {
            $eqBoth = @{ }

            $desiredRealms.Keys | Where-Object {
                $currentRealms.ContainsKey($_) -and $currentRealms[$_] -eq $desiredRealms[$_]
            } | ForEach-Object { $eqBoth.Add("$($_)", "$($currentRealms[$_])") }

            if ($eqBoth.Count -eq $desiredRealms.Count)
            {
                return $res
            }
            else
            {
                $res.CurrentStatus = "Absent"
                $res.NewRealms = $desiredRealms
                return $res
            }
        }
        else
        {
            $update = @{ }
            $inclusion = @{ }

            if ($includeRealms.Count -gt 0)
            {
                $includeRealms.Keys | Where-Object {
                    !$currentRealms.ContainsKey($_) -and $currentRealms[$_] -ne $includeRealms[$_]
                } | ForEach-Object { $inclusion.Add("$($_)", "$($includeRealms[$_])") }

                $includeRealms.Keys | Where-Object {
                    $currentRealms.ContainsKey($_) -and $currentRealms[$_] -ne $includeRealms[$_]
                } | ForEach-Object { $update.Add("$($_)", "$($includeRealms[$_])") }
            }

            if ($update.Count -gt 0)
            {
                $update.Keys | ForEach-Object { $currentRealms[$_] = $update[$_] }
            }

            if ($inclusion.Count -gt 0)
            {
                $inclusion.Keys | ForEach-Object { $currentRealms.Add($_, $inclusion[$_]) }
            }

            $exclusion = @{ }

            if ($excludeRealms.Count -gt 0)
            {
                $excludeRealms.Keys | Where-Object {
                    $currentRealms.ContainsKey($_) -and $currentRealms[$_] -eq $excludeRealms[$_]
                } | ForEach-Object { $exclusion.Add("$($_)", "$($excludeRealms[$_])") }

                if ($exclusion.Count -gt 0)
                {
                    $exclusion.Keys | ForEach-Object { $currentRealms.Remove($_) }
                }
            }

            if ($inclusion.Count -gt 0 -or $update.Count -gt 0 -or $exclusion.Count -gt 0)
            {
                $res.CurrentStatus = "Absent"
                $res.NewRealms = $currentRealms
                return $res
            }
            else
            {
                return $res
            }
        }
    }
    else
    {
        if ($includeRealms.Count -gt 0 -or $excludeRealms.Count -gt 0)
        {
            $message = ("Parameters ProviderRealmsToInclude and/or ProviderRealmsToExclude can not be used together with Ensure='Absent' use ProviderRealms instead")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        if ($desiredRealms.Count -eq 0)
        {
            $message = ("Parameter ProviderRealms is empty or Null")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }

        $eqBoth = $desiredRealms.Keys | Where-Object {
            $currentRealms.ContainsKey($_) -and $currentRealms[$_] -eq $desiredRealms[$_]
        } | ForEach-Object {
            $returnval = @{
                "$($_)" = "$($currentRealms[$_])"
            }

            return $returnval
        }

        if ($eqBoth.Count -eq 0)
        {
            $res.CurrentStatus = "Absent"
            return $res
        }
        else
        {
            $res.NewRealms = $eqBoth
            return $res
        }
    }
}
