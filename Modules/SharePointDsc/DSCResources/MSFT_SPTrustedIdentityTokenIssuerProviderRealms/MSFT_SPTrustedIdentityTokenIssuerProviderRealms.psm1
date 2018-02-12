function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer ProviderRealms"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock     {
        $params = $args[0]
        $paramRealms = $null
        $includeRealms = $null
        $excludeRealms = $null

        if(!!$params.ProviderRealms)
        {
             $paramRealms = $params.ProviderRealms | ForEach-Object {
                        "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
        }

        if(!!$params.ProviderRealmsToInclude)
        {
             $includeRealms = $params.ProviderRealmsToInclude | ForEach-Object {
                        "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
        }

        if(!!$params.ProviderRealmsToExclude)
        {
             $excludeRealms = $params.ProviderRealmsToExclude | ForEach-Object {
                        "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
        }

        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                                    -ErrorAction SilentlyContinue

        if (!$spTrust)
        {
            throw "SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found"
        }

        if($spTrust.ProviderRealms.Count -gt 0)
        {
            $currentRealms = $spTrust.ProviderRealms.GetEnumerator() | ForEach-Object {
                            "$($_.Key)=$($_.Value)" 
            }
        }

        $diffObjects = Get-ProviderRealmsChanges -currentRealms $currentRealms -desiredRealms $paramRealms `
                                      -includeRealms $includeRealms -excludeRealms $excludeRealms

        $state = $diffObjects.Count -eq 0

        if($params.Ensure -eq "Absent")
        {
            if($state)
            {
                $state = $currentRealms.Count -gt 0
            }
            else
            {
                $state = $true
            }
        }

        $currentState = @{$true = "Present"; $false = "Absent"}[$state]

        return @{
            IssuerName                   = $params.IssuerName
            ProviderRealms               = $spTrust.ProviderRealms
            ProviderRealmsToInclude      = $params.ProviderRealmsToInclude
            ProviderRealmsToExclude      = $params.ProviderRealmsToExclude
            Ensure                       = $currentState
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
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
        $CurrentValues = Get-TargetResource @PSBoundParameters
        
        Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer provider realms"
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]

            $paramRealms = $null
            $includeRealms = $null
            $excludeRealms = $null

            if(!!$params.ProviderRealms)
            {
            $paramRealms = $params.ProviderRealms | ForEach-Object {
                            "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
            }

            if(!!$params.ProviderRealmsToInclude)
            {
            $includeRealms = $params.ProviderRealmsToInclude | ForEach-Object {
                            "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
            }

            if(!!$params.ProviderRealmsToExclude)
            {
            $excludeRealms = $params.ProviderRealmsToExclude | ForEach-Object {
                            "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }
            }

            $trust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName -ErrorAction SilentlyContinue

            $currentRealms =$trust.ProviderRealms.GetEnumerator() | ForEach-Object {
                        "$($_.Key)=$($_.Value)" 
            }

            $diffObjects = Get-ProviderRealmsChanges -currentRealms $currentRealms -desiredRealms $paramRealms `
                                          -includeRealms $includeRealms -excludeRealms $excludeRealms

            $needsUpdate = $false
            if($params.Ensure -eq "Absent" `
                -and $params.Ensure -ne $CurrentValues.Ensure `
                -and $diffObjects.Count -le 1)
            {
                $currentRealms | ForEach-Object { 
                        Write-Verbose "Removing Realm $([System.Uri]$_.Split('=')[0])"
                        $trust.ProviderRealms.Remove([System.Uri]$_.Split('=')[0])
                        $needsUpdate = $true
                }
            }
            else
            {
                $diffObjects | Where-Object {$_.Split('=')[0]-eq "Remove"} | ForEach-Object {
                        Write-Verbose "Removing Realm $([System.Uri]$_.Split('=')[1])"
                        $trust.ProviderRealms.Remove([System.Uri]$_.Split('=')[1])
                        $needsUpdate = $true
                }
                $diffObjects | Where-Object {$_.Split('=')[0]-eq "Add"} | ForEach-Object {
                        Write-Verbose "Adding Realm $([System.Uri]$_.Split('=')[1])"
                        $trust.ProviderRealms.Add([System.Uri]$_.Split('=')[1],$_.Split('=')[2])
                        $needsUpdate = $true
                }
            }
            if($needsUpdate)
            {
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
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPTrustedIdentityTokenIssuer provider realms"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
