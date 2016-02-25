function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]    [System.String]  $Url,
        [ValidateSet("Present","Absent")] [System.String]  $Ensure = "Present",
        [parameter(Mandatory = $false)]   [System.String]  $Description,
        [parameter(Mandatory = $false)]   [System.String]  $Name,
        [parameter(Mandatory = $false)]   [System.UInt32]  $Language,
        [parameter(Mandatory = $false)]   [System.String]  $Template,
        [parameter(Mandatory = $false)]   [System.Boolean] $UniquePermissions,
        [parameter(Mandatory = $false)]   [System.Boolean] $UseParentTopNav,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToQuickLaunch,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToTopNav,
        [parameter(Mandatory = $false)]   [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting SPWeb '$Url'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $web = Get-SPWeb -Identity $params.Url -ErrorAction SilentlyContinue

        if ($web) { 
        
            $ensureResult   = "Present" 
            $templateResult = "$($web.WebTemplate)#$($web.WebTemplateId)"
            $parentTopNav   = $web.Navigation.UseShared

        } else { 
        
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
        [parameter(Mandatory = $true)]    [System.String]  $Url,
        [ValidateSet("Present","Absent")] [System.String]  $Ensure = "Present",
        [parameter(Mandatory = $false)]   [System.String]  $Description,
        [parameter(Mandatory = $false)]   [System.String]  $Name,
        [parameter(Mandatory = $false)]   [System.UInt32]  $Language,
        [parameter(Mandatory = $false)]   [System.String]  $Template,
        [parameter(Mandatory = $false)]   [System.Boolean] $UniquePermissions,
        [parameter(Mandatory = $false)]   [System.Boolean] $UseParentTopNav,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToQuickLaunch,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToTopNav,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Creating SPWeb '$Url'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $web = Get-SPWeb -Identity $params.Url -ErrorAction SilentlyContinue

        if ($null -eq $web) 
        {
            $params.Remove("InstallAccount") | Out-Null
            $params.Remove("Ensure") | Out-Null

            New-SPWeb @params -Confirm:$false  | Out-Null
        }
        else
        {
            if ($params.Ensure -eq "Absent") {
                Remove-SPweb $params.Url -confirm:$false
            }else{
                
                if ($web.Title -ne $params.Name) {
                    $web.Title = $params.Name
                    $web.Update()
                }

                if ($web.Description -ne $params.Description) {
                    $web.Description = $params.Description
                    $web.Update()
                }

                if ($web.Navigation.UseShared -ne $params.UseParentTopNav) {
                    $web.Navigation.UseShared = $params.UseParentTopNav
                    $web.Update()
                }

                if ($web.HasUniquePerm -ne $params.UniquePermissions) {
                    $web.HasUniquePerm = $params.UniquePermissions
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
        [parameter(Mandatory = $true)]    [System.String]  $Url,
        [ValidateSet("Present","Absent")] [System.String]  $Ensure = "Present",
        [parameter(Mandatory = $false)]   [System.String]  $Description,
        [parameter(Mandatory = $false)]   [System.String]  $Name,
        [parameter(Mandatory = $false)]   [System.UInt32]  $Language,
        [parameter(Mandatory = $false)]   [System.String]  $Template,
        [parameter(Mandatory = $false)]   [System.Boolean] $UniquePermissions,
        [parameter(Mandatory = $false)]   [System.Boolean] $UseParentTopNav,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToQuickLaunch,
        [parameter(Mandatory = $false)]   [System.Boolean] $AddToTopNav,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Testing SPWeb '$Url'"

    $valuesToCheck = @("Url", "Name", "Description", "UniquePermissions", "UseParentTopNav")

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck $valuesToCheck
}


Export-ModuleMember -Function *-TargetResource
