function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $Description,
        [parameter(Mandatory = $true)]  [String]   $Realm,
        [parameter(Mandatory = $true)]  [String]   $SignInUrl,
        [parameter(Mandatory = $true)]  [String]   $IdentifierClaim,
        [parameter(Mandatory = $true)]  [Object[]] $ClaimsMappings,
        [parameter(Mandatory = $true)]  [String]   $SigningCertificateThumbPrint,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $ClaimProviderName,
        [parameter(Mandatory = $false)] [String]   $ProviderSignOutUri,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer '$Name'..."

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $spTrust = Get-SPTrustedIdentityTokenIssuer $params.Name -ErrorAction SilentlyContinue
        if ($spTrust) { 
            $currentState = "Present"
        } else { 
            $currentState = "Absent"
        }

        return @{
            Name   = $params.Name
            Ensure = $currentState
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $Description,
        [parameter(Mandatory = $true)]  [String]   $Realm,
        [parameter(Mandatory = $true)]  [String]   $SignInUrl,
        [parameter(Mandatory = $true)]  [String]   $IdentifierClaim,
        [parameter(Mandatory = $true)]  [Object[]] $ClaimsMappings,
        [parameter(Mandatory = $true)]  [String]   $SigningCertificateThumbPrint,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $ClaimProviderName,
        [parameter(Mandatory = $false)] [String]   $ProviderSignOutUri,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present") 
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            Write-Verbose "Create SPTrustedIdentityTokenIssuer '$Name'..."

            $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]

                $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $SigningCertificateThumbPrint}
                if (!$cert) {
                    throw "The certificate thumbprint does not match a certificate in certificate store LocalMachine\My."
                    return
                }

                $ClaimsMappingsArray = @()
                $params.ClaimsMappings| %{
                    $runParams = @{}
                    $runParams.Add("IncomingClaimTypeDisplayName", $_["Name"])
                    $runParams.Add("IncomingClaimType", $_["IncomingClaimType"])
                    if (!$_["LocalClaimType"]) { $runParams.Add("LocalClaimType", $_["IncomingClaimType"]) }
                    else { $runParams.Add("LocalClaimType", $_["LocalClaimType"]) }
                    $ClaimsMappingsArray = $ClaimsMappingsArray + (New-SPClaimTypeMapping @runParams)
                }

                if (!($ClaimsMappingsArray| ?{$_.MappedClaimType -like $IdentifierClaim})) {
                    throw "IdentifierClaim does not match any claim type specified in ClaimsMappings."
                    return
                }

                $runParams = @{}
                $runParams.Add("ImportTrustCertificate", $cert)
                $runParams.Add("Name", $params.Name)
                $runParams.Add("Description", $params.Description)
                $runParams.Add("Realm", $params.Realm)
                $runParams.Add("SignInUrl", $params.SignInUrl)
                $runParams.Add("IdentifierClaim", $params.IdentifierClaim)
                $runParams.Add("ClaimsMappings", $ClaimsMappingsArray)
                $trust = New-SPTrustedIdentityTokenIssuer @runParams

                if ((Get-SPClaimProvider| ?{$_.DisplayName -like $ClaimProviderName})) {
                    $trust.ClaimProviderName = $params.ClaimProviderName
                }
                if ($ProviderSignOutUri) { $trust.ProviderSignOutUri = new-object System.Uri($ProviderSignOutUri) }
                $trust.Update()
             }
        }
    }
    else
    {
        Write-Verbose "Remove SPTrustedIdentityTokenIssuer."
        $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            # SPTrustedIdentityTokenIssuer must be removed from each zone of each web app before it can be deleted
            Get-SPWebApplication| %{
                $wa = $_
                [Enum]::GetNames( [Microsoft.SharePoint.Administration.SPUrlZone] )| %{
                    $zone = $_
                    $providers = Get-SPAuthenticationProvider -WebApplication $wa.Url -Zone $_ -ErrorAction SilentlyContinue
                    if (!$providers) { return }
                    $providers| ?{$_ -is [Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider] -and $_.LoginProviderName -like $Name}| %{
                        Write-Verbose "Removing " $_.LoginProviderName " from web app " $wa.Url " in zone " $zone
                        $wa.GetIisSettingsWithFallback($zone).ClaimsAuthenticationProviders.Remove($_)| Out-Null
                        $wa.Update()
                        return
                    }
                }
            }
        
            $runParams = @{ 
                Identity = $params.Name
                Confirm = $false
            }
            Remove-SPTrustedIdentityTokenIssuer @runParams
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $Description,
        [parameter(Mandatory = $true)]  [String]   $Realm,
        [parameter(Mandatory = $true)]  [String]   $SignInUrl,
        [parameter(Mandatory = $true)]  [String]   $IdentifierClaim,
        [parameter(Mandatory = $true)]  [Object[]] $ClaimsMappings,
        [parameter(Mandatory = $true)]  [String]   $SigningCertificateThumbPrint,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $ClaimProviderName,
        [parameter(Mandatory = $false)] [String]   $ProviderSignOutUri,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Test if SPTrustedIdentityTokenIssuer '$Name' exists ..."
    $CurrentValues = Get-TargetResource @PSBoundParameters
    $valuesToCheck = @("Ensure")
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck $valuesToCheck
}

Export-ModuleMember -Function *-TargetResource
