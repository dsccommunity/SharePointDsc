function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.UInt16] $WarningSiteCount,
        [parameter(Mandatory = $false)] [System.UInt16] $MaximumSiteCount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting content database configuration settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $cdb = Get-SPContentDatabase | Where-Object { $_.Name -eq $params.Name}

        if ($cdb -eq $null) {
            # Database does not exist
            return @{
                Name = $params.Name
                DatabaseServer = $params.DatabaseServer
                WebAppUrl = $params.WebAppUrl
                Enabled = $params.Enabled
                WarningSiteCount = $params.WarningSiteCount
                MaximumSiteCount = $params.MaximumSiteCount
                Ensure = "Absent"
                InstallAccount = $params.InstallAccount
            }
        } else {
            # Database exists
            if ($cdb.Status -eq "Online") { $cdbenabled = $true } else { $cdbenabled = $false }

            return @{
                Name = $params.Name
                DatabaseServer = $cdb.Server
                WebAppUrl = $cdb.WebApplication.Url
                Enabled = $cdbenabled
                WarningSiteCount = $cdb.WarningSiteCount
                MaximumSiteCount = $cdb.MaximumSiteCount
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.UInt16] $WarningSiteCount,
        [parameter(Mandatory = $false)] [System.UInt16] $MaximumSiteCount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting content database configuration settings"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        # Use Get-SPDatabase instead of Get-SPContentDatabase because the Get-SPContentDatabase does not return disabled databases.
        $cdb = Get-SPDatabase | Where-Object { $_.Type -eq "Content Database" -and $_.Name -eq $params.Name }

        if ($params.Ensure -eq "Present") {
            # Check if specified web application exists and throw exception when this is not the case
            $webapp = Get-SPWebApplication | Where-Object { $_.Url -eq $params.WebAppUrl + "/"}
            if ($webapp -eq $null) {
                throw "Specified web application does not exist."
            }

            # Check if database exists
            if ($cdb -ne $null) {
                # Check and change attached web application. Dismount and mount to correct web application
                if ($params.WebAppUrl.Substring($params.WebAppUrl.Length-1,1) -ne "/") { 
                    $paramwebappurl = $params.WebAppUrl + "/"
                }
                if ($paramwebappurl -ne $cdb.WebApplication.Url) {
                    Dismount-SPContentDatabase $params.Name -Confirm:$false

                    if ($params.ContainsKey("Enabled")) { $enabled = $params.Enabled } else { $enabled = $true }
                    $cdb = MountContentDatabase $params.Clone() $enabled
                }

                # Check and change database status
                if ($cdb.Status -eq "Online") { $cdbenabled = $true } else { $cdbenabled = $false }
                if ($params.ContainsKey("Enabled") -and $params.Enabled -ne $cdbenabled) {
                    switch ($params.Enabled) {
                        $true  { $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online }
                        $false { $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled }
                    }
                 }
                 
                 # Check and change site count settings
                if ($params.WarningSiteCount -and $params.WarningSiteCount -ne $cdb.WarningSiteCount) { $cdb.WarningSiteCount = $params.WarningSiteCount }
                if ($params.MaximumSiteCount -and $params.MaximumSiteCount -ne $cdb.MaximumSiteCount) { $cdb.MaximumSiteCount = $params.MaximumSiteCount }
            } else {
                # Database does not exist, but should. Create/mount database
                if ($params.ContainsKey("Enabled")) { $enabled = $params.Enabled } else { $enabled = $true }
                $cdb = MountContentDatabase $params.Clone() $enabled
            }
            $cdb.Update()
        } else {
            if ($cdb -ne $null) {
                # Database exists, but shouldn't. Dismount database
                Dismount-SPContentDatabase $params.Name -Confirm:$false
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.String] $DatabaseServer,
        [parameter(Mandatory = $true)]  [System.String] $WebAppUrl,
        [parameter(Mandatory = $false)] [System.Boolean] $Enabled,
        [parameter(Mandatory = $false)] [System.UInt16] $WarningSiteCount,
        [parameter(Mandatory = $false)] [System.UInt16] $MaximumSiteCount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present",
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing content database configuration settings"
    $CurrentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Ensure = $Ensure

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}


function MountContentDatabase() {
    Param (
        $params,
        $enabled
    )
    if ($params.ContainsKey("Enabled")) { $params.Remove("Enabled") }
    if ($params.ContainsKey("Ensure")) { $params.Remove("Ensure") }
    if ($params.ContainsKey("MaximumSiteCount")) {
        $params.MaxSiteCount = $params.MaximumSiteCount
        $params.Remove("MaximumSiteCount")
    }
    if ($params.ContainsKey("WebAppUrl")) {
        $params.WebApplication = $params.WebAppUrl
        $params.Remove("WebAppUrl")
    }
    try {
        $cdb = Mount-SPContentDatabase @params
    } catch {
        throw "Error occurred while mounting content database. Content database is not mounted. Error details: $($_.Exception.Message)"
    }
    if ($cdb.Status -eq "Online") { $cdbenabled = $true } else { $cdbenabled = $false }
    if ($enabled -ne $cdbenabled) {
        switch ($params.Enabled) {
            $true  { $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online }
            $false { $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled }
        }
    }

    return $cdb
}

Export-ModuleMember -Function *-TargetResource
