function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]   $ProxyName,
        [parameter(Mandatory = $true)]  [System.String[]] $CreatePersonalSite,
        [parameter(Mandatory = $true)]  [System.String[]] $FollowAndEditProfile,
        [parameter(Mandatory = $true)]  [System.String[]] $UseTagsAndNotes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    Write-Verbose -Message "Getting all security options for $SecurityType in $ServiceAppName"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $proxy = Get-SPServiceApplicationProxy | Where-Object { $_.DisplayName -eq $params.ProxyName }
        if ($null -eq $proxy) {
            return @{
                ProxyName = $params.ProxyName
                CreatePersonalSite = $null
                FollowAndEditProfile = $null
                UseTagsAndNotes = $null
                InstallAccount = $params.InstallAccount
            }
        }
        $security = Get-SPProfileServiceApplicationSecurity -ProfileServiceApplicationProxy $proxy

        $createPersonalSite = @()
        $followAndEditProfile = @()
        $useTagsAndNotes = @()

        foreach ($securityEntry in $security.AccessRules) {
            
            $user = $securityEntry.Name
            if ($user -ne "c:0(.s|true" -and $user -ne "nt authority\authenticated users") {
                if ($user -like "i:*|*" -or $user -like "c:*|*") {
                    $user = (New-SPClaimsPrincipal -Identity $user -IdentityType EncodedClaim).Value    
                }

                if ($securityEntry.AllowedRights.ToString() -eq "All") {
                    $createPersonalSite += $user
                    $followAndEditProfile += $user
                    $useTagsAndNotes += $user
                }
                if ($securityEntry.AllowedRights -contains "UsePersonalFeatures") {
                    $followAndEditProfile += $user
                }
                if ($securityEntry.AllowedRights -contains "CreatePersonalSite") {
                    $createPersonalSite += $user
                }
                if (($securityEntry.AllowedRights -contains "UseSocialFeatures") `
                    -and ($securityEntry.AllowedRights -contains "UseMicrobloggingAndFollowing")) {
                    $useTagsAndNotes += $user
                }
            }
        }

        $allClaimsUsers = $security.AccessRules `
                          | Where-Object -FilterScript { $_.Name -eq "c:0(.s|true" }
        $allUsers = $security.AccessRules `
                    | Where-Object -FilterScript { $_.Name -eq "nt authority\authenticated users" }

        if (($null -ne $allClaimsUsers) -and ($null -ne $allUsers)) {
            if ($allClaimsUsers.AllowedRights.ToString() -ne $allUsers.AllowedRights.ToString()) {
                Write-Warning -Message "The claims based 'all authenticated users' entry does not " + `
                                       "match the non-claims entry. The 'Everyone' permission will" + `
                                       "no be returned so this can be corrected in the Set method" + `
                                       "of this resource."
            } else {
                if ($allClaimsUsers.AllowedRights.ToString() -eq "All") {
                    $createPersonalSite += "Everyone"
                    $followAndEditProfile += "Everyone"
                    $useTagsAndNotes += "Everyone"
                }
                if ($allClaimsUsers.AllowedRights -contains "UsePersonalFeatures") {
                    $followAndEditProfile += "Everyone"
                }
                if ($allClaimsUsers.AllowedRights -contains "CreatePersonalSite") {
                    $createPersonalSite += "Everyone"
                }
                if (($allClaimsUsers.AllowedRights -contains "UseSocialFeatures") `
                    -and ($allClaimsUsers.AllowedRights -contains "UseMicrobloggingAndFollowing")) {
                    $useTagsAndNotes += "Everyone"
                }
            }
        }

        if ($createPersonalSite.Length -eq 0) { $createPersonalSite += "None" }
        if ($followAndEditProfile.Length -eq 0) { $followAndEditProfile += "None" }
        if ($useTagsAndNotes.Length -eq 0) { $useTagsAndNotes += "None" }

        return @{
            ProxyName = $params.ProxyName
            CreatePersonalSite = $createPersonalSite
            FollowAndEditProfile = $followAndEditProfile
            UseTagsAndNotes = $useTagsAndNotes
            InstallAccount = $params.InstallAccount
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $ProxyName,
        [parameter(Mandatory = $true)]  [System.String[]] $CreatePersonalSite,
        [parameter(Mandatory = $true)]  [System.String[]] $FollowAndEditProfile,
        [parameter(Mandatory = $true)]  [System.String[]] $UseTagsAndNotes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $ProxyName,
        [parameter(Mandatory = $true)]  [System.String[]] $CreatePersonalSite,
        [parameter(Mandatory = $true)]  [System.String[]] $FollowAndEditProfile,
        [parameter(Mandatory = $true)]  [System.String[]] $UseTagsAndNotes,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
}

