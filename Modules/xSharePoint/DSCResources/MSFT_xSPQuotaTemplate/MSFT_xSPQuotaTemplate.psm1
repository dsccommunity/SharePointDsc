function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageMaxInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageWarningInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUsagePointsSolutions,
        [parameter(Mandatory = $false)] [System.UInt32]  $WarningUsagePointsSolutions,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )
    
    Write-Verbose -Message "Getting Quota Template settings"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        try {
            $spFarm = Get-SPFarm
        } catch {
            Write-Verbose -Verbose "No local SharePoint farm was detected. Antivirus settings will not be applied"
            return $null
        }

        # Get a reference to the Administration WebService
        $admService = Get-xSharePointContentService

        $template = $admService.QuotaTemplates[$Name]
        if ($null -eq $template) { return $null }
        
        return @{
            Name = $params.Name
            StorageMaxInMB = ($template.StorageMaximumLevel/1048576) # Convert from bytes to megabytes
            StorageWarningInMB = ($template.StorageWarningLevel/1048576) # Convert from bytes to megabytes
            MaximumUsagePointsSolutions = $template.UserCodeMaximumLevel
            WarningUsagePointsSolutions = $template.UserCodeWarningLevel
            Ensure = "Present"
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
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageMaxInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageWarningInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUsagePointsSolutions,
        [parameter(Mandatory = $false)] [System.UInt32]  $WarningUsagePointsSolutions,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Setting quota template settings"

    switch ($Ensure) {
        "Present" {
            Write-Verbose "Ensure is set to Present - Add or update template"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                try {
                    $spFarm = Get-SPFarm
                } catch {
                    Write-Verbose -Verbose "No local SharePoint farm was detected. Antivirus settings will not be applied"
                    return $null
                }

                Write-Verbose -Message "Start update"
                # Get a reference to the Administration WebService
                $admService = Get-xSharePointContentService

                $template = $admService.QuotaTemplates[$Name]

                if ($null -eq $template) { 
                    #Template does not exist, create new template
                    $newTemplate = New-Object Microsoft.SharePoint.Administration.SPQuotaTemplate
                    $newTemplate.Name = $Name
                    $newTemplate.StorageMaximumLevel = ($StorageMaxInMB * 1048576) # Convert from megabytes to bytes
                    $newTemplate.StorageWarningLevel = ($StorageWarningInMB * 1048576) # Convert from megabytes to bytes
                    $newTemplate.UserCodeMaximumLevel = $MaximumUsagePointsSolutions
                    $newTemplate.UserCodeWarningLevel = $WarningUsagePointsSolutions
                    $admService.QuotaTemplates.Add($newTemplate)
                    $admService.Update()
                } else {
                    #Template exists, update settings
                    $template.StorageMaximumLevel = ($StorageMaxInMB * 1048576) # Convert from megabytes to bytes
                    $template.StorageWarningLevel = ($StorageWarningInMB * 1048576) # Convert from megabytes to bytes
                    $template.UserCodeMaximumLevel = $MaximumUsagePointsSolutions
                    $template.UserCodeWarningLevel = $WarningUsagePointsSolutions
                    $admService.Update()
                }
            }
        }
        "Absent" {
            Write-Verbose "Ensure is set to Absent - Removing template"
            Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                try {
                    $spFarm = Get-SPFarm
                } catch {
                    Write-Verbose -Verbose "No local SharePoint farm was detected. Antivirus settings will not be applied"
                    return $null
                }

                Write-Verbose -Message "Start update"
                # Get a reference to the Administration WebService
                $admService = Get-xSharePointContentService

                # Delete template, function does not throw an error when the template does not exist. So safe to call without error handling.
                $admService.QuotaTemplates.Delete($name)
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
        [parameter(Mandatory = $true)]  [System.String]  $Name,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageMaxInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $StorageWarningInMB,
        [parameter(Mandatory = $false)] [System.UInt32]  $MaximumUsagePointsSolutions,
        [parameter(Mandatory = $false)] [System.UInt32]  $WarningUsagePointsSolutions,
        [parameter(Mandatory = $true)]  [ValidateSet("Present","Absent")] [System.String] $Ensure
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Testing quota template settings"
    # CHECK if Ensure equals Absent, then return false if exists
    # CHECK if Ensure equals Present, then return false if not exists and if parameters match return true

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}


Export-ModuleMember -Function *-TargetResource
