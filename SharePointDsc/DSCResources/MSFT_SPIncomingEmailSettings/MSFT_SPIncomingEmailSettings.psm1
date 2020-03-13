$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseAutomaticSettings,

        [Parameter()]
        [ValidateSet("Yes", "No", "Remote")]
        [System.String]
        $UseDirectoryManagementService,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteDirectoryManagementURL,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerAddress,

        [Parameter()]
        [System.Boolean]
        $DLsRequireAuthenticatedSenders,

        [Parameter()]
        [System.Boolean]
        $DistributionGroupsEnabled,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerDisplayAddress,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DropFolder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting SharePoint Incoming Email Settings"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -ScriptBlock {
        $spEmailServiceInstance = (Get-SPServiceInstance | Where-Object { $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPIncomingEmailServiceInstance" }) | Select-Object -First 1
        $spEmailService = $spEmailServiceInstance.service

        # some simple error checking, just incase we didn't capture the service for some reason
        if ($null -eq $spEmailService)
        {
            Write-Verbose "Error getting the SharePoint Incoming Email Service"
            return @{
                IsSingleInstance               = "Yes"
                Ensure                         = $null
                UseAutomaticSettings           = $null
                UseDirectoryManagementService  = $null
                RemoteDirectoryManagementURL   = $null
                ServerAddress                  = $null
                DLsRequireAuthenticatedSenders = $null
                DistributionGroupsEnabled      = $null
                ServerDisplayAddress           = $null
                DropFolder                     = $null
            }
        }

        # determine if incoming email is enabled
        if ($spEmailService.Enabled -eq $true)
        {
            $ensure = "Present"
        }
        else
        {
            return @{
                IsSingleInstance               = "Yes"
                Ensure                         = "Absent"
                UseAutomaticSettings           = $null
                UseDirectoryManagementService  = $null
                RemoteDirectoryManagementURL   = $null
                ServerAddress                  = $null
                DLsRequireAuthenticatedSenders = $null
                DistributionGroupsEnabled      = $null
                ServerDisplayAddress           = $null
                DropFolder                     = $null
            }
        }

        #determine directory service integration mode
        if ($spEmailService.UseDirectoryManagementService -eq $false)
        {
            $useDirectoryManagementService = "No"
        }
        elseif ($spEmailService.UseDirectoryManagementService -eq $true -and $spEmailService.RemoteDirectoryManagementService -eq $false)
        {
            $useDirectoryManagementService = "Yes"
            $remoteDirectoryManagementURL = $null
        }
        elseif ($spEmailService.UseDirectoryManagementService -eq $true -and $spEmailService.RemoteDirectoryManagementService -eq $true)
        {
            $useDirectoryManagementService = "Remote"
            $remoteDirectoryManagementURL = $spEmailService.DirectoryManagementServiceUrl
        }

        return @{
            IsSingleInstance               = "Yes"
            Ensure                         = $ensure
            UseAutomaticSettings           = $spEmailService.UseAutomaticSettings
            UseDirectoryManagementService  = $useDirectoryManagementService
            RemoteDirectoryManagementURL   = $remoteDirectoryManagementURL
            ServerAddress                  = $spEmailService.ServerAddress
            DLsRequireAuthenticatedSenders = $spEmailService.DLsRequireAuthenticatedSenders
            DistributionGroupsEnabled      = $spEmailService.DistributionGroupsEnabled
            ServerDisplayAddress           = $spEmailService.ServerDisplayAddress
            DropFolder                     = $spEmailService.DropFolder
        }

    }

    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseAutomaticSettings,

        [Parameter()]
        [ValidateSet("Yes", "No", "Remote")]
        [System.String]
        $UseDirectoryManagementService,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteDirectoryManagementURL,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerAddress,

        [Parameter()]
        [System.Boolean]
        $DLsRequireAuthenticatedSenders,

        [Parameter()]
        [System.Boolean]
        $DistributionGroupsEnabled,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerDisplayAddress,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DropFolder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SharePoint Incoming Email Settings"

    if ($Ensure -eq 'Present')
    {
        if (-not $PSBoundParameters.containskey("UseAutomaticSettings"))
        {
            throw "UseAutomaticSettings parameter must be specified when enabling incoming email."
        }

        if (-not $PSBoundParameters.containskey("ServerDisplayAddress"))
        {
            throw "ServerDisplayAddress parameter must be specified when enabling incoming email"
        }

        if (($PSBoundParameters.UseDirectoryManagementService -eq 'Remote' -and $null -eq $PSBoundParameters.RemoteDirectoryManagementURL) `
                -or ($PSBoundParameters.containskey('RemoteDirectoryManagementURL') -and $PSBoundParameters.UseDirectoryManagementService -ne 'Remote'))
        {
            throw "RemoteDirectoryManagementURL must be specified only when UseDirectoryManagementService is set to 'Remote'"
        }

        if ($PSBoundParameters.UseAutomaticSettings -eq $true -and $PSBoundParameters.containskey("DropFolder"))
        {
            throw "DropFolder parameter is not valid when using Automatic Mode"
        }

        if ($PSBoundParameters.UseAutomaticSettings -eq $false -and (-not $PSBoundParameters.containskey("DropFolder")))
        {
            throw "DropFolder parameter must be specified when not using Automatic Mode"
        }
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $spEmailServiceInstance = (Get-SPServiceInstance | Where-Object { $_.GetType().FullName -eq "Microsoft.SharePoint.Administration.SPIncomingEmailServiceInstance" }) | Select-Object -First 1
        $spEmailService = $spEmailServiceInstance.service

        #some simple error checking, just incase we didn't capture the service for some reason
        if ($null -eq $spEmailService)
        {
            throw "Error getting the SharePoint Incoming Email Service"
        }

        if ($params.Ensure -eq "Absent")
        {
            Write-Verbose -Message "Disabling SharePoint Incoming Email"
            $spEmailService.Enabled = $false

        }
        else #Present
        {
            Write-Verbose -Message "Enabling SharePoint Incoming Email"



            $spEmailService.Enabled = $true
            $spEmailService.ServerDisplayAddress = $params.ServerDisplayAddress

            if ($params.UseAutomaticSettings -eq $true)
            {
                Write-Verbose -Message "Setting Incoming Email Service to use Automatic Settings"
                $spEmailService.UseAutomaticSettings = $true
            }
            else
            {
                Write-Verbose -Message "Setting Incoming Email Service to use Advanced Settings"
                $spEmailService.UseAutomaticSettings = $false
                $spEmailService.DropFolder = $params.DropFolder
            }

            #Configure Directory Management modes
            if ($params.UseDirectoryManagementService -eq "Yes")
            {
                $spEmailService.UseDirectoryManagementService = $true
                $spEmailService.RemoteDirectoryManagementService = $false
            }
            elseif ($params.UseDirectoryManagementService -eq "Remote")
            {
                $spEmailService.UseDirectoryManagementService = $true
                $spEmailService.RemoteDirectoryManagementService = $true
                $spEmailService.DirectoryManagementServiceURL = $params.RemoteDirectoryManagementURL
            }
            else
            {
                $spEmailService.UseDirectoryManagementService = $false
                $spEmailService.RemoteDirectoryManagementService = $false
                $spEmailService.DirectoryManagementServiceURL = $null
            }

            #Optional settings for Directory Management
            if ($params.UseDirectoryManagementService -eq "Yes" -or $params.UseDirectoryManagementService -eq "Remote")
            {
                if ($params.containskey('DLsRequireAuthenticatedSenders'))
                {
                    $spEmailService.DLsRequireAuthenticatedSenders = $params.DLsRequireAuthenticatedSenders
                }

                if ($params.containskey('DistributionGroupsEnabled'))
                {
                    $spEmailService.DistributionGroupsEnabled = $params.DistributionGroupsEnabled
                }

                if ($params.containskey('ServerAddress'))
                {
                    $spEmailService.ServerAddress = $params.ServerAddress
                }
            }
        }

        $spEmailService.Update()

    }

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure,

        [Parameter()]
        [System.Boolean]
        $UseAutomaticSettings,

        [Parameter()]
        [ValidateSet("Yes", "No", "Remote")]
        [System.String]
        $UseDirectoryManagementService,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RemoteDirectoryManagementURL,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerAddress,

        [Parameter()]
        [System.Boolean]
        $DLsRequireAuthenticatedSenders,

        [Parameter()]
        [System.Boolean]
        $DistributionGroupsEnabled,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerDisplayAddress,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DropFolder,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SharePoint Incoming Email Settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
