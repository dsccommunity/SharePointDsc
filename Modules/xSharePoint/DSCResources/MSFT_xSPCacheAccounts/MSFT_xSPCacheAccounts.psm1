function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)] [System.String] $SuperUserAlias,
        [parameter(Mandatory = $true)] [System.String] $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return $null }
        
        $returnVal = @{}
        $returnVal.Add("WebAppUrl", $params.WebAppUrl)
        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) { 
            $returnVal.Add("SuperUserAlias", $wa.Properties["portalsuperuseraccount"])
        } else {
            $returnVal.Add("SuperUserAlias", "")
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) { 
            $returnVal.Add("SuperReaderAlias", $wa.Properties["portalsuperreaderaccount"])
        } else {
            $returnVal.Add("SuperReaderAlias", "")
        }
        $returnVal.Add("InstallAccount", $params.InstallAccount)
        return $returnVal
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)]  [System.String] $SuperUserAlias,
        [parameter(Mandatory = $true)]  [System.String] $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $wa = Get-SPWebApplication -Identity $params.WebAppUrl -ErrorAction SilentlyContinue
        if ($null -eq $wa) { 
            throw [Exception] "The web applications $($params.WebAppUrl) can not be found to set cache accounts"
        }
        
        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) { 
            $wa.Properties["portalsuperuseraccount"] = $params.SuperUserAlias
        } else {
            $wa.Properties.Add("portalsuperuseraccount", $params.SuperUserAlias)
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) { 
            $wa.Properties["portalsuperreaderaccount"] = $params.SuperReaderAlias
        } else {
            $wa.Properties.Add("portalsuperreaderaccount", $params.SuperReaderAlias)
        }
        
        Set-xSharePointCacheReaderPolicy -WebApplication $wa -UserName $params.SuperReaderAlias
        Set-xSharePointCacheOwnerPolicy -WebApplication $wa -UserName $params.SuperUserAlias

        Update-xSharePointObject -InputObject $wa
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $WebAppUrl,
        [parameter(Mandatory = $true)] [System.String] $SuperUserAlias,
        [parameter(Mandatory = $true)] [System.String] $SuperReaderAlias,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing cache accounts for $WebAppUrl"
    if ($null -eq $CurrentValues) {return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("SuperUserAlias", "SuperReaderAlias")
}

Export-ModuleMember -Function *-TargetResource
