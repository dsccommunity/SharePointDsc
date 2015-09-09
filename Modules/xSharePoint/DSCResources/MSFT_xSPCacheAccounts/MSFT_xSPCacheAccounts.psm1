function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $WebAppUrl,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        $wa = Invoke-xSharePointSPCmdlet "Get-SPWebApplication" -Arguments @{ Identity = $params.WebAppUrl }  -ErrorAction SilentlyContinue

        if ($null -eq $wa) { return @{} }
        
        $returnVal = @{}
        $returnVal.Add("WebAppUrl", $params.WebAppUrl)
        if ($wa.Properties.ContainsKey("portalsuperuseraccount")) { 
            $returnVal.Add("portalsuperuseraccount", $wa.Properties["portalsuperuseraccount"])
        } else {
            $returnVal.Add("portalsuperuseraccount", "")
        }
        if ($wa.Properties.ContainsKey("portalsuperreaderaccount")) { 
            $returnVal.Add("portalsuperreaderaccount", $wa.Properties["portalsuperreaderaccount"])
        } else {
            $returnVal.Add("portalsuperreaderaccount", "")
        }

        return $returnVal
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
        $WebAppUrl,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting cache accounts for $WebAppUrl"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $wa = Invoke-xSharePointSPCmdlet "Get-SPWebApplication" -Arguments @{ Identity = $params.WebAppUrl }
        
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

        $wa.Update() 
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
        $WebAppUrl,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperUserAlias,

        [parameter(Mandatory = $true)]
        [System.String]
        $SuperReaderAlias,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    $result = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing cache accounts for $WebAppUrl"

    if ($result.Count -eq 0) { return $false }
    else {
        if ($SuperUserAlias -ne $result.portalsuperuseraccount) { return $false }
        if ($SuperReaderAlias -ne $result.portalsuperreaderaccount) { return $false }
    }
    return $true
}

Export-ModuleMember -Function *-TargetResource
