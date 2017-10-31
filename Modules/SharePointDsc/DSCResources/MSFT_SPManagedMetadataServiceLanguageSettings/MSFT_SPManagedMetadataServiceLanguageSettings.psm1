function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String]
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $DefaultLanguage,

        [parameter(Mandatory = $false)] 
        [System.UInt32[]]
        $Languages,
        
        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )
    Write-Verbose -Message "Getting language settings for managed metadata service application proxy $ProxyName"
    
    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                        | Where-Object -FilterScript { 
                $_.IsAdministrationWebApplication -eq $true 
            }

        $session = Get-SPTaxonomySession -Site $centralAdminSite.Url

        if ($null -eq $session)
        {
            throw ("Could not get taxonomy session. Please check if the managed metadata service is started.")
        }

        $termStore = $session.TermStores[$params.ProxyName]

        if ($null -eq $termStore) 
        {
            throw ("Specified termstore '$($params.ProxyName)' does not exist.")
        }

        return @{
            ProxyName           = $params.ProxyName
            DefaultLanguage     = $termStore.DefaultLanguage
            Languages           = $termStore.Languages           
            InstallAccount      = $params.InstallAccount
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
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [System.UInt32] 
        $DefaultLanguage,

        [parameter(Mandatory = $false)] 
        [System.UInt32[]] 
        $Languages,     
        
        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting language settings for managed metadata service application proxy $ProxyName"

    $result = Get-TargetResource @PSBoundParameters

    if ($PSBoundParameters.ContainsKey("DefaultLanguage") -eq $true) 
    {
        # The lanauge settings should be set to default
        Write-Verbose -Message "Setting the default language for Managed Metadata Service Application Proxy $ProxyName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0] 

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                        | Where-Object -FilterScript { 
                $_.IsAdministrationWebApplication -eq $true 
            }
            $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
            $termStore = $session.TermStores[$params.ProxyName]

            $termStore.DefaultLanguage = $params.DefaultLanguage
            $termStore.CommitAll()
        }
    }

    if ($PSBoundParameters.ContainsKey("Languages") -eq $true)
    {
        Write-Verbose -Message "Setting working languages for Managed Metadata Service Application Proxy $ProxyName"
        # Update the term store working languages
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments @($PSBoundParameters, $result) `
                            -ScriptBlock {

            $params = $args[0]
            $currentValues = $args[1]

            $centralAdminSite = Get-SPWebApplication -IncludeCentralAdministration `
                                | Where-Object -FilterScript { 
                $_.IsAdministrationWebApplication -eq $true 
            }
            $session = Get-SPTaxonomySession -Site $centralAdminSite.Url
            $termStore = $session.TermStores[$params.ProxyName]

            $changesToMake = Compare-Object -ReferenceObject $currentValues.Languages `
                                            -DifferenceObject $params.Languages
            
            $changesToMake | ForEach-Object -Process {
                $change = $_
                switch($change.SideIndicator)
                {
                    "<=" {
                        # delete a working language 
                        $termStore.DeleteLanguage($change.InputObject)                        
                    }
                    "=>" {
                        # add a working language
                        $termStore.AddLanguage($change.InputObject)
                    }
                    default {
                        throw "An unknown side indicator was found."
                    }
                }
            }

            $termStore.CommitAll();
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] 
        [System.String] 
        $ProxyName,

        [parameter(Mandatory = $false)] 
        [System.UInt32] 
        $DefaultLanguage,

        [parameter(Mandatory = $false)] 
        [System.UInt32[]] 
        $Languages,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing language settings for managed metadata service application proxy $ProxyName"
   
    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("DefaultLanguage", "Languages") 
}
Export-ModuleMember -Function *-TargetResource
