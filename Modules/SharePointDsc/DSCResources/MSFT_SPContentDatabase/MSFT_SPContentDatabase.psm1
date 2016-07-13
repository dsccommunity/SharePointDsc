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

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $cdb = Get-SPDatabase | Where-Object -FilterScript `
                                { $_.Type -eq "Content Database" -and $_.Name -eq $params.Name }

        if ($null -eq $cdb)
        {
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
        }
        else
        {
            # Database exists
            if ($cdb.Status -eq "Online")
            {
                $cdbenabled = $true
            }
            else
            {
                $cdbenabled = $false
            }

            $returnVal = @{
                Name = $params.Name
                DatabaseServer = $cdb.Server
                WebAppUrl = $cdb.WebApplication.Url.Trim("/")
                Enabled = $cdbenabled
                WarningSiteCount = $cdb.WarningSiteCount
                MaximumSiteCount = $cdb.MaximumSiteCount
                Ensure = "Present"
                InstallAccount = $params.InstallAccount
            }
            return $returnVal
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

    Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        function MountContentDatabase()
        {
            param
            (
                $params,
                $enabled
            )

            if ($params.ContainsKey("Enabled"))
            {
                $params.Remove("Enabled")
            }
            
            if ($params.ContainsKey("Ensure"))
            {
                $params.Remove("Ensure")
            }
            
            if ($params.ContainsKey("InstallAccount"))
            {
                $params.Remove("InstallAccount")
            }
            
            if ($params.ContainsKey("MaximumSiteCount"))
            {
                $params.MaxSiteCount = $params.MaximumSiteCount
                $params.Remove("MaximumSiteCount")
            }
            if ($params.ContainsKey("WebAppUrl"))
            {
                $params.WebApplication = $params.WebAppUrl
                $params.Remove("WebAppUrl")
            }

            try
            {
                $cdb = Mount-SPContentDatabase @params
            }
            catch
            {
                throw "Error occurred while mounting content database. Content database is not mounted. Error details: $($_.Exception.Message)"
            }

            if ($cdb.Status -eq "Online")
            {
                $cdbenabled = $true
            }
            else
            {
                $cdbenabled = $false
            }

            if ($enabled -ne $cdbenabled)
            {
                switch ($params.Enabled)
                {
                    $true
                    { 
                        $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online
                    }
                    $false
                    {
                        $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled
                    }
                }
            }

            return $cdb
        }

        # Use Get-SPDatabase instead of Get-SPContentDatabase because the Get-SPContentDatabase does not return disabled databases.
        $cdb = Get-SPDatabase | Where-Object -FilterScript `
                                    { $_.Type -eq "Content Database" -and $_.Name -eq $params.Name }

        if ($params.Ensure -eq "Present") {
            # Check if specified web application exists and throw exception when this is not the case
            $webapp = Get-SPWebApplication | Where-Object -FilterScript `
                                    { $_.Url.Trim("/") -eq $params.WebAppUrl.Trim("/") }

            if ($null -eq $webapp) {
                throw "Specified web application does not exist."
            }

            # Check if database exists
            if ($null -ne $cdb) {
                if ($cdb.Server -ne $params.DatabaseServer) {
                    throw "Specified database server does not match the actual database server." + `
                          " This resource cannot move the database to a different SQL instance."
                }

                # Check and change attached web application. Dismount and mount to correct web application
                if ($params.WebAppUrl.Trim("/") -ne $cdb.WebApplication.Url.Trim("/")) {
                    Dismount-SPContentDatabase $params.Name -Confirm:$false

                    if ($params.ContainsKey("Enabled"))
                    {
                        $enabled = $params.Enabled
                    }
                    else
                    {
                        $enabled = $true
                    }
                    
                    $parameters = @{} + $params
                    $cdb = MountContentDatabase $parameters $enabled
                }

                # Check and change database status
                if ($cdb.Status -eq "Online")
                {
                    $cdbenabled = $true
                }
                else
                {
                    $cdbenabled = $false
                }
                
                if ($params.ContainsKey("Enabled") -and $params.Enabled -ne $cdbenabled)
                {
                    switch ($params.Enabled)
                    {
                        $true
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Online
                        }
                        $false
                        {
                            $cdb.Status = [Microsoft.SharePoint.Administration.SPObjectStatus]::Disabled
                        }
                    }
                 }
                 
                 # Check and change site count settings
                if ($params.WarningSiteCount -and $params.WarningSiteCount -ne $cdb.WarningSiteCount)
                {
                    $cdb.WarningSiteCount = $params.WarningSiteCount
                }
                
                if ($params.MaximumSiteCount -and $params.MaximumSiteCount -ne $cdb.MaximumSiteCount)
                {
                    $cdb.MaximumSiteCount = $params.MaximumSiteCount
                }
            }
            else
            {
                # Database does not exist, but should. Create/mount database
                if ($params.ContainsKey("Enabled"))
                {
                    $enabled = $params.Enabled
                }
                else
                {
                    $enabled = $true
                }
                
                $parameters = @{} + $params
                $cdb = MountContentDatabase $parameters $enabled
            }
            $cdb.Update()
        }
        else
        {
            if ($null -ne $cdb)
            {
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

    if ($CurrentValues.DatabaseServer -ne $DatabaseServer)
    {
        Write-Verbose "Specified database server does not match the actual database server. " + `
                      "This resource cannot move the database to a different SQL instance."
        return $false
    }

    $PSBoundParameters.Ensure = $Ensure
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters
}

Export-ModuleMember -Function *-TargetResource
