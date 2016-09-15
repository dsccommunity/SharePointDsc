function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]    
        [System.String]
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.String]
        $Description,

        [parameter(Mandatory = $false)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $Language,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UniquePermissions,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UseParentTopNav,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AddToQuickLaunch,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $AddToTopNav,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting SPWeb '$Url'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $web = Get-SPWeb -Identity $params.Url -ErrorAction SilentlyContinue

        if ($web) 
        { 
            $ensureResult   = "Present" 
            $templateResult = "$($web.WebTemplate)#$($web.WebTemplateId)"
            $parentTopNav   = $web.Navigation.UseShared
        } 
        else 
        { 
            $ensureResult = "Absent" 
        }
        
        return @{
            Url               = $web.Url
            Ensure            = $ensureResult
            Description       = $web.Description
            Name              = $web.Title
            Language          = $web.Language
            Template          = $templateResult
            UniquePermissions = $web.HasUniquePerm
            UseParentTopNav   = $parentTopNav
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
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.String]
        $Description,

        [parameter(Mandatory = $false)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $Language,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UniquePermissions,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UseParentTopNav,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AddToQuickLaunch,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $AddToTopNav,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPWeb '$Url'"
    
    $PSBoundParameters.Ensure = $Ensure

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        
        if ($null -eq $params.InstallAccount) 
        {    
            $currentUserName = "$env:USERDOMAIN\$env:USERNAME"
        } 
        else
        {    
            $currentUserName = $params.InstallAccount.UserName
        }
        
        Write-Verbose "Grant user '$currentUserName' Access To Process Identity for '$($params.Url)'..."
        $site = New-Object -Type Microsoft.SharePoint.SPSite -ArgumentList $params.Url  
        $site.WebApplication.GrantAccessToProcessIdentity($currentUserName) 
        
        $web = Get-SPWeb -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $web) 
        {
            $params.Remove("InstallAccount") | Out-Null
            $params.Remove("Ensure") | Out-Null

            New-SPWeb @params | Out-Null
        }
        else
        {
            if ($params.Ensure -eq "Absent") 
            {
                Remove-SPweb $params.Url -confirm:$false
            }
            else
            {    
                $changedWeb = $false
                
                if ($web.Title -ne $params.Name) 
                {
                    $web.Title = $params.Name
                    $changedWeb = $true
                }

                if ($web.Description -ne $params.Description) 
                {
                    $web.Description = $params.Description
                    $changedWeb = $true
                }

                if ($web.Navigation.UseShared -ne $params.UseParentTopNav) 
                {
                    $web.Navigation.UseShared = $params.UseParentTopNav
                    $changedWeb = $true
                }

                if ($web.HasUniquePerm -ne $params.UniquePermissions) 
                {
                    $web.HasUniquePerm = $params.UniquePermissions
                    $changedWeb = $true
                }
                
                if ($changedWeb) 
                {
                    $web.Update()
                }
            }
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
        $Url,

        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")] 
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory = $false)]
        [System.String]
        $Description,

        [parameter(Mandatory = $false)]
        [System.String]
        $Name,

        [parameter(Mandatory = $false)] 
        [System.UInt32]
        $Language,

        [parameter(Mandatory = $false)]
        [System.String]
        $Template,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UniquePermissions,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $UseParentTopNav,

        [parameter(Mandatory = $false)] 
        [System.Boolean] 
        $AddToQuickLaunch,

        [parameter(Mandatory = $false)]
        [System.Boolean] 
        $AddToTopNav,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPWeb '$Url'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $valuesToCheck = @("Url", 
                       "Name", 
                       "Description", 
                       "UniquePermissions", 
                       "UseParentTopNav", 
                       "Ensure")

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck $valuesToCheck
}

Export-ModuleMember -Function *-TargetResource
