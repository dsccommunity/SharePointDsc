function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $IssuerName,
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

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
        
        $paramRealms = $params.ProviderRealms | ForEach-Object {
                        "$([System.Uri]$_.RealmUrl)=$($_.RealmUrn)" }

        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                                    -ErrorAction SilentlyContinue
        
        if (!$spTrust)
        {
            throw "SPTrustedIdentityTokenIssuer '$($params.IssuerName)' not found"
        }

        $currentRealms =$spTrust.ProviderRealms.GetEnumerator() | ForEach-Object { 
                        "$($_.Key)=$($_.Value)" 
        }

        $diffObjects = $paramRealms | Where-Object {
                        $currentRealms -contains $_
        }

        if($params.Ensure -eq "Present")
        {
            $present = $($diffObjects).Count -eq $($paramRealms).Count
        }
        else
        {
            $present = !$($($diffObjects).Count -eq 0)
        }
        
        $currentState = @{$true = "Present"; $false = "Absent"}[$present]
        
        return @{
            IssuerName                   = $params.IssuerName
            ProviderRealms               = $spTrust.ProviderRealms
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
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present")
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            Write-Verbose -Message "Setting SPTrustedIdentityTokenIssuer provider realms"

            $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                          -Arguments $PSBoundParameters `
                                          -ScriptBlock {
                $params = $args[0]
                
                $trust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                                    -ErrorAction SilentlyContinue
                
                foreach($cKey in $params.ProviderRealms)
                {
                    $url= New-Object System.Uri($cKey.RealmUrl)
                    if ($trust.ProviderRealms.ContainsKey($url))
                    {
                        if($trust.ProviderRealms[$url.AbsoluteUri] -ne $cKey.RealmUrn)
                        {
                            Write-Verbose -Message "The provider realm '$($cKey.RealmUrl)' exists but has different value. Updating to '$($cKey.RealmUrn)'"
                            $trust.ProviderRealms.Remove($url)                        
                            $trust.ProviderRealms.Add($url, $cKey.Value)
                        }
                        else
                        {
                            Write-Verbose -Message "Provider realm '$($cKey.RealmUrl)' exists. Skipping."
                        }
                    }
                    else
                    {
                        Write-Verbose -Message "Adding new provider realm '$($cKey.RealmUrl)'"
                        $trust.ProviderRealms.Add($url, $cKey.Value)
                        
                    }
                }

                $trust.Update()
            }
        }
    }
    else
    {
        Write-Verbose "Removing SPTrustedIdentityTokenIssuer provider realms"
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]
            $update = $false
            $trust = Get-SPTrustedIdentityTokenIssuer -Identity $params.IssuerName `
                                                    -ErrorAction SilentlyContinue

                foreach($cKey in $params.ProviderRealms)
                {
                    $url=[System.Uri]$cKey.RealmUrl
                    
                    if ($trust.ProviderRealms.ContainsKey($url))
                    {
                        Write-Verbose -Message "Removing provider realm '$($cKey.RealmUrl)'."
                        $trust.ProviderRealms.Remove($url)
                        $update = $true
                    }
                }
                
                if($update -eq $true)
                {
                   $trust.Update()
                }
                else
                {
                    throw "Provider realm '$($cKey.RealmUrl)' does not exist."
                }
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
        
        [Parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ProviderRealms,

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
