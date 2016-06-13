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

        if ((Test-SPDSCRunningAsFarmAccount -InstallAccount $params.InstallAccount) -eq $false) {
            throw ("The UserProfileServiceAppPermissions resource must be run as the farm account." + `
                   "Please ensure either PSDscRunAsCredential or InstallAccount is set to the farm account.")
        }

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
                if ($securityEntry.AllowedRights.ToString() -like "*UsePersonalFeatures*") {
                    $followAndEditProfile += $user
                }
                if ($securityEntry.AllowedRights.ToString() -like "*UseSocialFeatures*") {
                    $useTagsAndNotes += $user
                }
                if (($securityEntry.AllowedRights.ToString() -like "*CreatePersonalSite*") `
                    -and ($securityEntry.AllowedRights.ToString() -like "*UseMicrobloggingAndFollowing*")) {
                    $createPersonalSite += $user
                }
            }
        }

        $allClaimsUsers = $security.AccessRules `
                          | Where-Object -FilterScript { $_.Name -eq "c:0(.s|true" }
        $allUsers = $security.AccessRules `
                    | Where-Object -FilterScript { $_.Name -eq "nt authority\authenticated users" }

        if (($null -ne $allClaimsUsers) -and ($null -ne $allUsers)) {
            if ($allClaimsUsers.AllowedRights -ne $allUsers.AllowedRights) {
                Write-Warning -Message ("The claims based 'all authenticated users' entry does not " + `
                                       "match the non-claims entry. The 'Everyone' permission will" + `
                                       "no be returned so this can be corrected in the Set method" + `
                                       "of this resource.")
            } else {
                if ($allClaimsUsers.AllowedRights.ToString() -eq "All") {
                    $createPersonalSite += "Everyone"
                    $followAndEditProfile += "Everyone"
                    $useTagsAndNotes += "Everyone"
                }
                if ($allClaimsUsers.AllowedRights.ToString() -like "*UsePersonalFeatures*") {
                    $followAndEditProfile += "Everyone"
                }
                if ($allClaimsUsers.AllowedRights.ToString() -like "*UseSocialFeatures*") {
                    $useTagsAndNotes += "Everyone"
                }
                if (($allClaimsUsers.AllowedRights.ToString() -like "*CreatePersonalSite*") `
                    -and ($allClaimsUsers.AllowedRights.ToString() -like "*UseMicrobloggingAndFollowing*")) {
                    $createPersonalSite += "Everyone"
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
    
    $CurrentValues = Get-TargetResource @PSBoundParameters

    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @($PSBoundParameters, $CurrentValues) -ScriptBlock {
        $params = $args[0]
        $CurrentValues = $args[1]

        if ((Test-SPDSCRunningAsFarmAccount -InstallAccount $params.InstallAccount) -eq $false) {
            throw ("The UserProfileServiceAppPermissions resource must be run as the farm account." + `
                   "Please ensure either PSDscRunAsCredential or InstallAccount is set to the farm account.")
        }

        $proxy = Get-SPServiceApplicationProxy | Where-Object { $_.DisplayName -eq $params.ProxyName }
        $security = Get-SPProfileServiceApplicationSecurity -ProfileServiceApplicationProxy $proxy

        $personalSiteDiff = Compare-Object -ReferenceObject $CurrentValues.CreatePersonalSite `
                                           -DifferenceObject  $params.CreatePersonalSite
                                           
        $everyoneDiff = $personalSiteDiff | Where-Object -FilterScript { $_.InputObject -eq "Everyone" }
        $noneDiff = $personalSiteDiff | Where-Object -FilterScript { $_.InputObject -eq "None" }


        if (($null -eq $noneDiff) -and ($noneDiff.SideIndicator -eq "=>")) 
        {
            # Need to remove everyone
            foreach($user in $CurrentValues.CreatePersonalSite)
            {
                $isUser = Test-SPDSCIsADUser -IdentityName $user
                if ($isUser -eq $true) {
                    $claim = New-SPClaimsPrincipal -Identity $user -IdentityType WindowsSamAccountName  
                } else {
                    $claim = New-SPClaimsPrincipal -Identity $user -IdentityType WindowsSecurityGroupName
                }
                Revoke-SPObjectSecurity -Identity $security -Principal $claim
            }
        }
        elseif (($null -eq $everyoneDiff) -and ($everyoneDiff.SideIndicator -eq "=>")) 
        {
            # Need to add averyone, so remove all the permissions that exist currently of this type
            # and then add the everyone permissions
            foreach($user in $CurrentValues.CreatePersonalSite)
            {
                $isUser = Test-SPDSCIsADUser -IdentityName $user
                if ($isUser -eq $true) {
                    $claim = New-SPClaimsPrincipal -Identity $user -IdentityType WindowsSamAccountName    
                } else {
                    $claim = New-SPClaimsPrincipal -Identity $user -IdentityType WindowsSecurityGroupName
                }
                Revoke-SPObjectSecurity -Identity $security -Principal $claim
            }

            $allUsersClaim = New-SPClaimsPrincipal -Identity "NT Authority\Authenticated Users" -IdentityType WindowsSamAccountName 
            $alLClaimsUsersClaim = New-SPClaimsPrincipal -Identity "c:0(.s|true" -IdentityType EncodedClaim

            #TODO: ADD THE CLAIMS HERE
        } 
        else 
        {
            # permission changes aren't to everyone or none, process each change

        }

    }
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

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($null -eq $CurrentValues) 
    {
        return $false
    }
    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("CreatePersonalSite", `
                                                         "FollowAndEditProfile", `
                                                         "UseTagsAndNotes")
}

