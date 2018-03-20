function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$IssuerName,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealms,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToInclude,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToExclude,
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure = "Present",
        [Parameter()]
        [System.Management.Automation.PSCredential]$InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer ProviderRealms"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        $paramRealms = @{ }
        $includeRealms = @{ }
        $excludeRealms = @{ }
        $currentRealms = @{ }

        if ($params.ProviderRealms.Count -gt 0)
        {
            $params.ProviderRealms | ForEach-Object {
                $paramRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
            }
        }

        if (!!$params.ProviderRealmsToInclude.Count -gt 0)
        {
            $params.ProviderRealmsToInclude | ForEach-Object {
                $includeRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
            }
        }

        if ($params.ProviderRealmsToExclude.Count -gt 0)
        {
            $params.ProviderRealmsToExclude | ForEach-Object {
                $excludeRealms.Add("$([System.Uri]$_.RealmUrl)", "$($_.RealmUrn)")
            }
        }

        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                                    -ErrorAction SilentlyContinue

        if ($spTrust -eq $null)
        {
            throw ("SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found")
        }

        if ($spTrust.ProviderRealms.Count -gt 0)
        {
            $spTrust.ProviderRealms.Keys | ForEach-Object {
                $currentRealms.Add("$($_.ToString())", "$($spTrust.ProviderRealms[$_])")
            }
        }

        return @{
            IssuerName = $params.IssuerName
            ProviderRealms = $currentRealms
            ProviderRealmsToInclude = $includeRealms
            ProviderRealmsToExclude = $excludeRealms
            CurrentRealms = $currentRealms
            DesiredRealms = $paramRealms
            Ensure = $params.Ensure
        }
    }

    $currentStatus = Get-ProviderRealmsStatus -currentRealms $result.ProviderRealms -desiredRealms $result.DesiredRealms `
                                                  -includeRealms $result.ProviderRealmsToInclude -excludeRealms $result.ProviderRealmsToExclude `
                                                  -Ensure $result.Ensure

    return @{
            IssuerName = $result.IssuerName
            ProviderRealms = $result.ProviderRealms
            ProviderRealmsToInclude = $result.ProviderRealmsToInclude
            ProviderRealmsToExclude = $result.ProviderRealmsToExclude
            CurrentRealms = $result.CurrentRealms
            RealmsToAdd = $currentStatus.NewRealms
            Ensure = $currentStatus.CurrentStatus
        }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$IssuerName,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealms,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToInclude,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToExclude,
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure = "Present",
        [Parameter()]
        [System.Management.Automation.PSCredential]$InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Add('CurrentValues', $CurrentValues)

    Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer provider realms"
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        if ($params.CurrentValues.RealmsToAdd.Count -gt 0)
        {
            $trust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                  -ErrorAction SilentlyContinue

            if ($trust -eq $null)
            {
                 throw ("SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found")
            }

            $trust.ProviderRealms.Clear()
            $params.CurrentValues.RealmsToAdd.Keys | ForEach-Object {
                Write-Verbose "Setting Realm: $([System.Uri]$_)=$($params.CurrentValues.RealmsToAdd[$_])"
                $trust.ProviderRealms.Add([System.Uri]$_, $params.CurrentValues.RealmsToAdd[$_])
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
        [string]$IssuerName,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealms,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToInclude,
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$ProviderRealmsToExclude,
        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure = "Present",
        [Parameter()]
        [System.Management.Automation.PSCredential]$InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedIdentityTokenIssuer provider realms"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
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

    if ($desiredRealms.Count -gt 0 -and ($includeRealms.Count -gt 0 -or $excludeRealms.Count -gt 0)) 
    {
        throw ("Cannot use the ProviderRealms parameter together with the " + `
               "ProviderRealmsToInclude or ProviderRealmsToExclude parameters")
    }

    if ($desiredRealms.Count -eq 0 -and $includeRealms.Count -eq 0 -and $excludeRealms.Count -eq 0) 
    {
        throw ("At least one of the following parameters must be specified: " + `
               "ProviderRealms, ProviderRealmsToInclude, ProviderRealmsToExclude")
    }

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
            if ($includeRealms.Count -gt 0)
            {
                $inclusion = @{ }
                $includeRealms.Keys | Where-Object {
                    !$currentRealms.ContainsKey($_) -and $currentRealms[$_] -ne $includeRealms[$_]
                } | ForEach-Object { $inclusion.Add("$($_)", "$($includeRealms[$_])") }

                $update = @{ }
                $includeRealms.Keys | Where-Object {
                    $currentRealms.ContainsKey($_) -and $currentRealms[$_] -ne $includeRealms[$_]
                } | ForEach-Object { $update.Add("$($_)", "$($includeRealms[$_])") }
            }

            if ($update.Count -gt 0)
            {
                $update.Keys | ForEach-Object{ $currentRealms[$_] = $update[$_] }
            }

            if ($inclusion.Count -gt 0)
            {
                $inclusion.Keys | ForEach-Object { $currentRealms.Add($_, $inclusion[$_]) }
            }

            if ($excludeRealms.Count -gt 0)
            {
                $exclusion = @{ }

                $excludeRealms.Keys | Where-Object {
                    $currentRealms.ContainsKey($_) -and $currentRealms[$_] -eq $excludeRealms[$_]
                } | ForEach-Object { $exclusion.Add("$($_)", "$($excludeRealms[$_])") }

                if ($exclusion.Count -gt 0)
                {
                    $exclusion.Keys | ForEach-Object{ $currentRealms.Remove($_) }
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
            throw ("Parameters ProviderRealmsToInclude and/or ProviderRealmsToExclude can not be used together with Ensure='Absent' use ProviderRealms instead")
        }

        $eqBoth = $desiredRealms.Keys | Where-Object {
            $currentRealms.ContainsKey($_) -and $currentRealms[$_] -eq $desiredRealms[$_]
        } | ForEach-Object {
            @{ "$($_)" = "$($currentRealms[$_])" }
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
