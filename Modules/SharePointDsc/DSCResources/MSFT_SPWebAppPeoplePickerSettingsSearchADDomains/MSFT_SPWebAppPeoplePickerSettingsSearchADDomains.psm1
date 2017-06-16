function Get-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Collections.HashTable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        [Parameter(Mandatory = $false)]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $false)] 
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message ("Looking for web application $Url " + `
                            "SearchActiveDirectoryDomain $DomainName")

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $returnValue = @{
            Url             = $params.Url
            DomainName      = $null
            LoginName       = $params.LoginName
            Ensure          = 'Absent'
            InstallAccount  = $params.InstallAccount
        }

        $spWebApplication = Get-SPWebApplication -Identity $params.Url `
                                                 -ErrorAction SilentlyContinue

        if ($null -eq $spWebApplication)
        {
            return $returnValue
        }

        $spSearchADDomain = $spWebApplication.PeoplePickerSettings.SearchActiveDirectoryDomains | Where-Object -FilterScript {
            $_.DomainName -eq $params.DomainName
        }

        if ($spSearchADDomain.DomainName -eq $params.DomainName)
        {
            $returnValue.Ensure     = 'Present'
            $returnValue.DomainName = $spSearchADDomain.DomainName
            $returnValue.LoginName  = $spSearchADDomain.LoginName
        }

        return $returnValue
    }
    return $result    
}

function Set-TargetResource()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        [Parameter(Mandatory = $false)]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $false)] 
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message ("Setting SearchActiveDirectoryDomain $DomainName " + `
                            "for the web application $Url ")
    
    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]

        $spWebApplication = Get-SPWebApplication -Identity $params.Url `
                                                 -ErrorAction SilentlyContinue
        if ($null -eq $spWebApplication) 
        {
            throw "Web Application with URL $($params.Url) does not exist"
        }
        
        try
        {
            $spWebApplication = Get-SPWebApplication -Identity $params.Url `
                                                     -ErrorAction SilentlyContinue
            switch ($params.Ensure)
            {
                'Present'
                {
                    Write-Verbose -Message ("Adding SearchActiveDirectoryDomain $DomainName " + `
                                            "to web application $Url")
                    $newSearchADDomain = New-Object -TypeName Microsoft.SharePoint.Administration.SPPeoplePickerSearchActiveDirectoryDomain
                    if ($params.LoginName)
                    {
                        $newSearchADDomain.LoginName = $params.LoginName
                    }

                    $newSearchADDomain.DomainName = $params.DomainName
                    $spWebApplication.PeoplePickerSettings.SearchActiveDirectoryDomains.Add($newSearchADDomain)
                }
                
                'Absent'
                {
                    Write-Verbose -Message ("Removing SearchActiveDirectoryDomain $DomainName " + `
                                            "to web application $Url")
                    $searchADDomainToRemove = $spWebApplication.PeoplePickerSettings.SearchActiveDirectoryDomains | Where-Object -FilterScript { 
                        $_.DomainName -eq $params.DomainName
                    }
                    
                    $spWebApplication.PeoplePickerSettings.SearchActiveDirectoryDomains.Remove($searchADDomainToRemove)
                }
            }
            
            $spWebApplication.Update()
        }
        catch
        {
            throw $_.Exception.Message
        }
    }
}

function Test-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        [Parameter(Mandatory = $false)]
        [System.String]
        $LoginName,

        [Parameter(Mandatory = $false)] 
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message ("Testing SearchActiveDirectoryDomain $DomainName " + `
                            "for the web application $Url ")

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @('Ensure', 'DomainName')
}

Export-ModuleMember -Function *-TargetResource
