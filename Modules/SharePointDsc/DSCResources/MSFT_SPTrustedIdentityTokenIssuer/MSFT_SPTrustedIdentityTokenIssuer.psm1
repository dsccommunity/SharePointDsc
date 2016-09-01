function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $Description,

        [parameter(Mandatory = $true)]
        [String]
        $Realm,

        [parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [parameter(Mandatory = $true)] 
        [String]
        $IdentifierClaim,

        [parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [parameter(Mandatory = $true)]
        [String]
        $SigningCertificateThumbPrint,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [String]
        $ClaimProviderName,

        [parameter(Mandatory = $false)]
        [String]
        $ProviderSignOutUri,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPTrustedIdentityTokenIssuer '$Name'..."

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $claimsMappings = @()
        $spTrust = Get-SPTrustedIdentityTokenIssuer -Identity $params.Name `
                                                    -ErrorAction SilentlyContinue
        if ($spTrust) 
        { 
            $description = $spTrust.Description
            $realm = $spTrust.DefaultProviderRealm
            $signInUrl = $spTrust.ProviderUri.OriginalString
            $identifierClaim = $spTrust.IdentityClaimTypeInformation.MappedClaimType
            $signingCertificateThumbPrint = $spTrust.SigningCertificate.Thumbprint
            $currentState = "Present"
            $claimProviderName = $sptrust.ClaimProviderName
            $providerSignOutUri = $sptrust.ProviderSignOutUri.OriginalString
            $spTrust.ClaimTypeInformation| Foreach-Object -Process {
                $claimsMappings = $claimsMappings + @{
                    Name = $_.DisplayName; 
                    IncomingClaimType = $_.InputClaimType; 
                    LocalClaimType = $_.MappedClaimType}
            }
        } 
        else 
        { 
            $description = ""
            $realm = ""
            $signInUrl = ""
            $identifierClaim = ""
            $signingCertificateThumbPrint = ""
            $currentState = "Absent"
            $claimProviderName = ""
            $providerSignOutUri = ""
        }

        return @{
            Name                         = $params.Name
            Description                  = $description
            Realm                        = $realm
            SignInUrl                    = $signInUrl
            IdentifierClaim              = $identifierClaim
            ClaimsMappings               = $claimsMappings
            SigningCertificateThumbPrint = $signingCertificateThumbPrint
            Ensure                       = $currentState
            ClaimProviderName            = $claimProviderName
            ProviderSignOutUri           = $providerSignOutUri
        }        
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $Description,

        [parameter(Mandatory = $true)]
        [String]
        $Realm,

        [parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [parameter(Mandatory = $true)] 
        [String]
        $IdentifierClaim,

        [parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [parameter(Mandatory = $true)]
        [String]
        $SigningCertificateThumbPrint,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [String]
        $ClaimProviderName,

        [parameter(Mandatory = $false)]
        [String]
        $ProviderSignOutUri,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq "Present") 
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            Write-Verbose -Message "Create SPTrustedIdentityTokenIssuer '$Name'..."

            $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                          -Arguments $PSBoundParameters `
                                          -ScriptBlock {
                $params = $args[0]

                $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object -FilterScript {
                    $_.Thumbprint -match $params.SigningCertificateThumbPrint
                }
                if (!$cert) 
                {
                    throw ("The certificate thumbprint does not match a certificate in " + `
                           "certificate store LocalMachine\My.")
                    return
                }
                
                $claimsMappingsArray = @()
                $params.ClaimsMappings| Foreach-Object -Process {
                    $runParams = @{}
                    $runParams.Add("IncomingClaimTypeDisplayName", $_.Name)
                    $runParams.Add("IncomingClaimType", $_.IncomingClaimType)
                    if ($null -eq $_.LocalClaimType) 
                    { 
                        $runParams.Add("LocalClaimType", $_.IncomingClaimType) 
                    }
                    else 
                    { 
                        $runParams.Add("LocalClaimType", $_.LocalClaimType) 
                    }

                    $newMapping = New-SPClaimTypeMapping @runParams
                    $claimsMappingsArray += $newMapping
                }

                if (!($claimsMappingsArray| Where-Object -FilterScript {
                        $_.MappedClaimType -like $params.IdentifierClaim
                    })) 
                {
                    throw ("IdentifierClaim does not match any claim type specified in " + `
                           "ClaimsMappings.")
                    return
                }

                $runParams = @{}
                $runParams.Add("ImportTrustCertificate", $cert)
                $runParams.Add("Name", $params.Name)
                $runParams.Add("Description", $params.Description)
                $runParams.Add("Realm", $params.Realm)
                $runParams.Add("SignInUrl", $params.SignInUrl)
                $runParams.Add("IdentifierClaim", $params.IdentifierClaim)
                $runParams.Add("ClaimsMappings", $claimsMappingsArray)
                $trust = New-SPTrustedIdentityTokenIssuer @runParams

                if ((Get-SPClaimProvider| Where-Object -FilterScript {
                        $_.DisplayName -like $ClaimProviderName
                    })) 
                {
                    $trust.ClaimProviderName = $params.ClaimProviderName
                }
                if ($ProviderSignOutUri) 
                { 
                    $trust.ProviderSignOutUri = new-object System.Uri($ProviderSignOutUri) 
                }
                $trust.Update()
             }
        }
    }
    else
    {
        Write-Verbose -Message "Remove SPTrustedIdentityTokenIssuer '$Name'..."
        $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                      -Arguments $PSBoundParameters `
                                      -ScriptBlock {
            $params = $args[0]
            # SPTrustedIdentityTokenIssuer must be removed from each zone of each web app before 
            # it can be deleted
            Get-SPWebApplication | Foreach-Object -Process {
                $wa = $_
                $urlZones = [Enum]::GetNames([Microsoft.SharePoint.Administration.SPUrlZone]) 
                $urlZones | Foreach-Object -Process {
                    $zone = $_
                    $providers = Get-SPAuthenticationProvider -WebApplication $wa.Url `
                                                              -Zone $_ `
                                                              -ErrorAction SilentlyContinue

                    if (!$providers) 
                    { 
                        return 
                    }
                    $providers| Where-Object -FilterScript {
                        $_ -is [Microsoft.SharePoint.Administration.SPTrustedAuthenticationProvider] `
                        -and $_.LoginProviderName -like $params.Name
                    } | Foreach-Object -Process {
                        Write-Verbose -Message ("Removing $($_.LoginProviderName) from web " + `
                                                "app $($wa.Url) in zone $zone") 
                        
                        $iisSettings = $wa.GetIisSettingsWithFallback($zone) 
                        $iisSettings.ClaimsAuthenticationProviders.Remove($_) | Out-Null
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
        [parameter(Mandatory = $true)]
        [String]
        $Name,

        [parameter(Mandatory = $true)]
        [String]
        $Description,

        [parameter(Mandatory = $true)]
        [String]
        $Realm,

        [parameter(Mandatory = $true)]
        [String]
        $SignInUrl,

        [parameter(Mandatory = $true)] 
        [String]
        $IdentifierClaim,

        [parameter(Mandatory = $true)]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ClaimsMappings,

        [parameter(Mandatory = $true)]
        [String]
        $SigningCertificateThumbPrint,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [String]
        $ClaimProviderName,

        [parameter(Mandatory = $false)]
        [String]
        $ProviderSignOutUri,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Test if SPTrustedIdentityTokenIssuer '$Name' exists ..."
    $CurrentValues = Get-TargetResource @PSBoundParameters
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
