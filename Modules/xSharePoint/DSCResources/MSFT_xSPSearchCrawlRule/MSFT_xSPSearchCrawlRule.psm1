function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Path,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $false)] [ValidateSet("DefaultRuleAccess", "BasicAccountRuleAccess", "CertificateRuleAccess", "NTLMAccountRuleAccess", "FormRuleAccess", "CookieRuleAccess", "AnonymousAccess")] [System.String] $AuthenticationType,
        [parameter(Mandatory = $false)] [ValidateSet("InclusionRule","ExclusionRule")] [System.String] $Type,
        [parameter(Mandatory = $false)] [ValidateSet("FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP")] [System.String[]] $CrawlConfigurationRules,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $AuthenticationCredentials,
        [parameter(Mandatory = $false)]  [System.String] $CertificateName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting Search Crawl Rule '$Path'"

    # Absent specified: Can only contain Path and ServiceAppName
    if ($Ensure -eq "Absent" -and ($AuthenticationCredentials -or $Type -or $CertificateName -or $CrawlConfigurationRules -or $AuthenticationType)) {
        Write-Verbose "Cannot use Ensure=Absent together with the AuthenticationType, Type, CrawlConfigurationRules, AuthenticationCredentials or CertificateName parameters"
        return $null        
    }

    # AuthenticationType=CertificateName and CertificateRuleAccess parameters not specified correctly
    if (($AuthenticationType -eq "CertificateRuleAccess" -and -not $CertificateName) -or ($AuthenticationType -ne "CertificateRuleAccess" -and $CertificateName)) {
        Write-Verbose "You need to specify both the AuthenticationType=CertificateRuleAccess and CertificateName parameters"
        return $null        
    }

    # AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentialsparameters not specified correctly
    if (($AuthenticationType -eq "NTLMAccountRuleAccess" -and -not $AuthenticationCredentials) -or ($AuthenticationType -ne "NTLMAccountRuleAccess" -and $AuthenticationCredentials)) {
        Write-Verbose "You need to specify both the AuthenticationType=NTLMAccountRuleAccess and AuthenticationCredentials parameters"
        return $null        
    }

    # AuthenticationType=BasicAccountRuleAccess and AuthenticationCredentialsparameters not specified correctly
    if (($AuthenticationType -eq "BasicAccountRuleAccess" -and -not $AuthenticationCredentials) -or ($AuthenticationType -ne "BasicAccountRuleAccess" -and $AuthenticationCredentials)) {
        Write-Verbose "You need to specify both the AuthenticationType=BasicAccountRuleAccess and AuthenticationCredentials parameters"
        return $null        
    }
    
    # ExclusionRule only with CrawlConfigurationRules=CrawlComplexUrls
    if ($Type -eq "ExclusionRule" -and ($CrawlConfigurationRules -contains "CrawlAsHTTP" -or $CrawlConfigurationRules -contains "FollowLinksNoPageCrawl")) {
        Write-Verbose "You cannot specify FollowLinksNoPageCrawl or CrawlAsHTTP as CrawlConfigurationRules value when specifying Type=ExclusionRule"
        return $null        
    }

    # ExclusionRule cannot be used with AuthenticationCredentials, CertificateName or AuthenticationType parameters
    if ($Type -eq "ExclusionRule" -and ($AuthenticationCredentials -or $CertificateName -or $AuthenticationType)) {
        Write-Verbose "You cannot specify AuthenticationCredentials, CertificateName or AuthenticationType when specifying Type=ExclusionRule"
        return $null        
    }

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.ServiceAppName -ErrorAction SilentlyContinue
        
        $nullReturn = @{
            Path = $params.Path
            ServiceAppName = $params.ServiceAppName
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }
         
        if ($null -eq $serviceApps) {
            Write-Verbose -Verbose "Service Application $($params.ServiceAppName) not found"
            return $nullReturn 
        }
        
        $serviceApp = $serviceApps | Where-Object { $_.TypeName -eq "Search Service Application" }

        If ($null -eq $serviceApp) { 
            Write-Verbose -Verbose "Service Application $($params.ServiceAppName) not found"
            return $nullReturn
        } else {
            $crawlRule = Get-SPEnterpriseSearchCrawlRule -SearchApplication $params.ServiceAppName | Where-Object { $_.Path -eq $params.Path }

            if ($crawlRule -eq $null) {
                Write-Verbose -Verbose "Crawl rule $($params.Path) not found"
                return $nullReturn
            } else {
                $crawlConfigurationRules = @()
                if ($crawlRule.SuppressIndexing) { $crawlConfigurationRules += "FollowLinksNoPageCrawl" }
                if ($crawlRule.FollowComplexUrls) { $crawlConfigurationRules += "CrawlComplexUrls" }
                if ($crawlRule.CrawlAsHttp) { $crawlConfigurationRules += "CrawlAsHTTP" }

                switch ($crawlRule.AuthenticationType) {
                    {"BasicAccountRuleAccess", "NTLMAccountRuleAccess" -contains $_ } {
                        $returnVal = @{
                            Path = $params.Path
                            ServiceAppName = $params.ServiceAppName
                            AuthenticationType = $crawlRule.AuthenticationType
                            Type = $crawlRule.Type
                            CrawlConfigurationRules = $crawlConfigurationRules
                            AuthenticationCredentials = $crawlRule.AccountName
                            Ensure = "Present"
                            InstallAccount = $params.InstallAccount
                        } 
                    }
                    "CertificateRuleAccess" {
                        $returnVal = @{
                            Path = $params.Path
                            ServiceAppName = $params.ServiceAppName
                            AuthenticationType = $crawlRule.AuthenticationType
                            Type = $crawlRule.Type
                            CrawlConfigurationRules = $crawlConfigurationRules
                            CertificateName = $crawlRule.AccountName
                            Ensure = "Present"
                            InstallAccount = $params.InstallAccount
                        } 
                    }
                    default {
                        # DefaultRuleAccess, FormRuleAccess, CookieRuleAccess, AnonymousAccess
                        $returnVal = @{
                            Path = $params.Path
                            ServiceAppName = $params.ServiceAppName
                            AuthenticationType = $crawlRule.AuthenticationType.ToString()
                            Type = $crawlRule.Type.ToString()
                            CrawlConfigurationRules = $crawlConfigurationRules
                            Ensure = "Present"
                            InstallAccount = $params.InstallAccount
                        }                
                    }
                }
                return $returnVal
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
        [parameter(Mandatory = $true)]  [System.String] $Path,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $false)] [ValidateSet("DefaultRuleAccess", "BasicAccountRuleAccess", "CertificateRuleAccess", "NTLMAccountRuleAccess", "FormRuleAccess", "CookieRuleAccess", "AnonymousAccess")] [System.String] $AuthenticationType,
        [parameter(Mandatory = $false)] [ValidateSet("InclusionRule","ExclusionRule")] [System.String] $Type,
        [parameter(Mandatory = $false)] [ValidateSet("FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP")] [System.String[]] $CrawlConfigurationRules,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $AuthenticationCredentials,
        [parameter(Mandatory = $false)]  [System.String] $CertificateName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    $result = Get-TargetResource @PSBoundParameters

    # Check if Get-TargetResource returned null, invalid parameters specified.
    if ($null -eq $result) { Throw "Invalid parameters specified. Please check verbose messages to check which parameters are invalid." }

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") {
        # Create the crawl rule as it doesn't exist
         
        Write-Verbose -Message "Creating Crawl Rule $Path"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $newParams = @{
                Path = $params.Path
                SearchApplication = $params.ServiceAppName
            }
            if ($params.ContainsKey("AuthenticationType") -eq $true) { $newParams.Add("AuthenticationType", $params.AuthenticationType) }
            if ($params.ContainsKey("Type") -eq $true) { $newParams.Add("Type", $params.Type) }
            if ($params.ContainsKey("CrawlConfigurationRules") -eq $true) {
                if($params.CrawlConfigurationRules -contains "FollowLinksNoPageCrawl") { $newParams.Add("SuppressIndexing",1) }
                if($params.CrawlConfigurationRules -contains "CrawlComplexUrls") { $newParams.Add("FollowComplexUrls",1) }
                if($params.CrawlConfigurationRules -contains "CrawlAsHTTP") { $newParams.Add("CrawlAsHttp",1) }
            }
            if ($params.ContainsKey("AuthenticationCredentials") -eq $true) {
                $newParams.Add("AccountName", $params.AuthenticationCredentials.UserName)
                $newParams.Add("AccountPassword", (ConvertTo-SecureString -String $params.AuthenticationCredentials.GetNetworkCredential().Password -AsPlainText -Force))
            }
            if ($params.ContainsKey("CertificateName") -eq $true) { $newParams.Add("CertificateName", $params.CertificateName) }
            
            New-SPEnterpriseSearchCrawlRule @newParams 
        }
    }
    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") {
        # Update the crawl rule that already exists
        
        Write-Verbose -Message "Updating Crawl Rule $Path"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $crawlRule = Get-SPEnterpriseSearchCrawlRule -SearchApplication $params.ServiceAppName | Where-Object { $_.Path -eq $params.Path }

            if ($crawlRule -ne $null) {
                $setParams = @{
                    Identity = $params.Path
                    SearchApplication = $params.ServiceAppName
                }
                if ($params.ContainsKey("AuthenticationType") -eq $true) { $setParams.Add("AuthenticationType", $params.AuthenticationType) }
                if ($params.ContainsKey("Type") -eq $true) { $setParams.Add("Type", $params.Type) }
                if ($params.ContainsKey("CrawlConfigurationRules") -eq $true) {
                    if($params.CrawlConfigurationRules -contains "FollowLinksNoPageCrawl") { $setParams.Add("SuppressIndexing",1) }
                    if($params.CrawlConfigurationRules -contains "CrawlComplexUrls") { $setParams.Add("FollowComplexUrls",1) }
                    if($params.CrawlConfigurationRules -contains "CrawlAsHTTP") { $setParams.Add("CrawlAsHttp",1) }
                }
                if ($params.ContainsKey("AuthenticationCredentials") -eq $true) {
                    $setParams.Add("AccountName", $params.AuthenticationCredentials.UserName)
                    $setParams.Add("AccountPassword", (ConvertTo-SecureString -String $params.AuthenticationCredentials.GetNetworkCredential().Password -AsPlainText -Force))
                }
                if ($params.ContainsKey("CertificateName") -eq $true) { $setParams.Add("AccountName", $params.CertificateName) }

                Set-SPEnterpriseSearchCrawlRule @setParams 
            }
        }
    }
    
    if ($Ensure -eq "Absent") {
        # The crawl rule should not exit
        Write-Verbose -Message "Removing Crawl Rule $Path"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            Remove-SPEnterpriseSearchCrawlRule -SearchApplication $params.ServiceAppName -Identity $params.Path -Confirm:$false
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Path,
        [parameter(Mandatory = $true)]  [System.String] $ServiceAppName,
        [parameter(Mandatory = $false)] [ValidateSet("DefaultRuleAccess", "BasicAccountRuleAccess", "CertificateRuleAccess", "NTLMAccountRuleAccess", "FormRuleAccess", "CookieRuleAccess", "AnonymousAccess")] [System.String] $AuthenticationType,
        [parameter(Mandatory = $false)] [ValidateSet("InclusionRule","ExclusionRule")] [System.String] $Type,
        [parameter(Mandatory = $false)] [ValidateSet("FollowLinksNoPageCrawl","CrawlComplexUrls", "CrawlAsHTTP")] [System.String[]] $CrawlConfigurationRules,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $AuthenticationCredentials,
        [parameter(Mandatory = $false)]  [System.String] $CertificateName,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing Search Crawl Rule '$Path'"

    # Check if Get-TargetResource returned null, invalid parameters specified.
    if ($null -eq $CurrentValues) { return $false }
        
    $PSBoundParameters.Ensure = $Ensure
    if ($Ensure -eq "Present") {
        if ($CrawlConfigurationRules) {
            if ($CurrentValues.ContainsKey("CrawlConfigurationRules")) {
                if ((Compare-Object -ReferenceObject $CrawlConfigurationRules -DifferenceObject $CurrentValues.CrawlConfigurationRules) -ne $null) { return $false }
            } else { return $false }
        }

        if ($CurrentValues.ContainsKey("AuthenticationCredentials") -and $AuthenticationCredentials) { 
            if ($AuthenticationCredentials.UserName -ne $CurrentValues.AuthenticationCredentials) { return $false }
        }
        
        return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure", "AuthenticationType", "Type", "CertificateName")    
    } else {
        return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
    }
    
}

Export-ModuleMember -Function *-TargetResource
