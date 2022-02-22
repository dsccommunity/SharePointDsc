#Requires -Version 5.1
[CmdletBinding()]
param ()

#region Supporting functions
function WriteLog
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message
    )

    $date = Get-Date -f "yyyy-MM-dd hh:mm:ss"
    Write-Verbose "$date - $Message"
}

function WriteError
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message
    )

    $date = Get-Date -f "yyyy-MM-dd hh:mm:ss"
    Write-Output "$date - [ERROR] $Message"
    $script:validConfig = $false
}


function Confirm-ProductKey
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProductKey
    )

    $regex = '^([A-Za-z0-9]{5}-){4}[A-Za-z0-9]{5}$'
    return ($ProductKey -match $regex)
}

function Confirm-EmailAddress
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $EmailAddress
    )

    $regex = "^[a-zA-Z0-9.!£#$%&'^_`{}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$"
    return ($EmailAddress -match $regex)
}

function Confirm-Path
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $regex = '^[a-z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*$'
    return ($Path -match $regex)
}

function Confirm-CertificateThumbPrint
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ThumbPrint
    )

    $regex = '^[0-9a-f]{40}$'
    return ($ThumbPrint -match $regex)
}

function Confirm-IPAddress
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $IPAddress
    )

    $regex = '\b(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b'
    return ($IPAddress -match $regex)
}

function Confirm-DomainName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainName
    )

    $regex = '^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$'
    return ($DomainName -match $regex)
}

function Confirm-URL
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $URL
    )

    $regex = '(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})'
    return ($URL -match $regex)
}

function Confirm-OUName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $OUName
    )

    $regex = '^(?<ou>(?:(?:OU|CN).+?(?<!\\),)+(?<dc>DC.+?))$'
    return ($OUName -match $regex)
}

function Confirm-DomainUserName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DomainUserName
    )

    $regex = '^[a-zA-Z][a-zA-Z0-9\-\.]{0,61}[a-zA-Z]\\\w[\w\.\- ]+$'
    return ($DomainUserName -match $regex)
}
#endregion

##### GENERIC VARIABLES #####
$buildingBlockVersion = [System.Version]'1.0.0'
$validConfig = $true
$defaultFolder = $PSScriptRoot

##### START SCRIPT #####
WriteLog -Message "Running as $(&whoami)"

# Dialog for selecting PSD input file
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = $defaultFolder
$dialog.Title = "Please select the DSC data file"
$dialog.Filter = "DSC Config (*.psd1) | *.psd1"
$result = $dialog.ShowDialog()

if ($result -eq "OK")
{
    $DataFile = Import-PowerShellDataFile $dialog.FileName
}

Write-Host 'Checking Building Block versions:' -ForegroundColor DarkGray
$dataFileVersion = [System.Version]$DataFile.NonNodeData.BuildingBlock.Version
Write-Host "  - Data file version : $($dataFileVersion.ToString())" -ForegroundColor DarkGray
Write-Host "  - Script version    : $($buildingBlockVersion.ToString())" -ForegroundColor DarkGray
if ($dataFileVersion -eq $buildingBlockVersion)
{
    Write-Host 'Versions equal, proceeding...' -ForegroundColor DarkGray
}
else
{
    Write-Host 'Versions do not match, please check the building block versions. Quiting!' -ForegroundColor Red
    return 'Versions do not match, please check the building block versions.'
}

#region AllNodes
$spfePresent = $false
$spbePresent = $false
$searchfePresent = $false
$searchbePresent = $false

WriteLog -Message "Validating Roles and Subroles"
foreach ($node in $DataFile.AllNodes)
{
    WriteLog -Message "  Validating $($node.NodeName)"

    # Validating valid roles
    if ($node.ContainsKey("Role"))
    {
        if ($node.Role -notin @("ActiveDirectory", "CAMApps", "SharePoint", "SQLServer"))
        {
            WriteError -Message "Role of $($node.NodeName) is not valid: $($node.Role)"
        }

        # Validating valid subroles
        if ($node.ContainsKey("Subrole"))
        {
            if ($node.Role -eq "SharePoint")
            {
                if ($node.Subrole -is [System.Array])
                {
                    foreach ($role in $node.Subrole)
                    {
                        # Validating if valid SharePoint subroles are used
                        if ($role -notin @("SPBE", "SPFE", "SearchBE", "SearchFE"))
                        {
                            WriteError -Message "Subrole of $($node.NodeName) is not valid: $role"
                        }
                    }
                }
                else
                {
                    # Validating if valid SharePoint subroles are used
                    if ($node.Subrole -notin @("SPBE", "SPFE", "SearchBE", "SearchFE"))
                    {
                        WriteError -Message "Subrole of $($node.NodeName) is not valid: $($node.Subrole)"
                    }
                }

                # Register if a specific role is specified
                switch ($node.Subrole)
                {
                    "SPFE"
                    {
                        $spfePresent = $true
                        if ($node.ContainsKey("IPAddress") -eq $true)
                        {
                            if ($node.IPAddress.ContainsKey("Content") -eq $true)
                            {
                                if ((Confirm-IPAddress -IPAddress $node.IPAddress.Content) -eq $false)
                                {
                                    WriteError -Message "Specified Content IPAddress '$($node.IPAddress.Content)' for server $($node.NodeName) is invalid."
                                }
                            }
                            else
                            {
                                WriteError -Message "The section IPAddress for server $($node.NodeName) is missing a Content parameter"
                            }

                            if ($node.IPAddress.ContainsKey("Apps") -eq $true)
                            {
                                if ((Confirm-IPAddress -IPAddress $node.IPAddress.Apps) -eq $false)
                                {
                                    WriteError -Message "Specified Apps IPAddress '$($node.IPAddress.Apps)' for server $($node.NodeName) is invalid."
                                }
                            }
                            else
                            {
                                WriteError -Message "The section IPAddress for server $($node.NodeName) is missing a Apps parameter"
                            }
                        }
                        else
                        {
                            if ($DataFile.NonNodeData.SharePoint.ProvisionApps -eq $true)
                            {
                                WriteError -Message "Server $($node.NodeName) with SPFE subrole does not contain a parameter IPAddress"
                            }
                        }
                    }
                    "SPBE"
                    {
                        $spbePresent = $true
                        if ($node.Subrole -isnot [System.Array] -or $node.Subrole -notcontains "SPFE")
                        {
                            if ($node.ContainsKey("IPAddress") -eq $true)
                            {
                                WriteError -Message "Server $($node.NodeName) with SPBE subrole should not contain a parameter IPAddress"
                            }
                        }
                    }
                    "SearchFE"
                    {
                        $searchfePresent = $true
                        if ($node.Subrole -isnot [System.Array] -or $node.Subrole -notcontains "SPFE")
                        {
                            if ($node.ContainsKey("IPAddress") -eq $true)
                            {
                                WriteError -Message "Server $($node.NodeName) with SearchFE subrole should not contain a parameter IPAddress"
                            }
                        }
                    }
                    "SearchBE"
                    {
                        $searchbePresent = $true
                        if ($node.Subrole -isnot [System.Array] -or $node.Subrole -notcontains "SPFE")
                        {
                            if ($node.ContainsKey("IPAddress") -eq $true)
                            {
                                WriteError -Message "Server $($node.NodeName) with SearchBE subrole should not contain a parameter IPAddress"
                            }
                        }
                    }
                }
            }
            else
            {
                WriteError -Message "$($node.NodeName) has subrole specified, but role is not SharePoint"
            }
        }
        else
        {
            if ($node.Role -eq "SharePoint")
            {
                WriteError -Message "$($node.NodeName) has role SharePoint, but doesn't have a subrole specified"
            }
        }
    }
    else
    {
        if ($node.NodeName -ne "*")
        {
            WriteError -Message "$($node.NodeName) doesn't have a role specified"
        }
    }

    if ($node.ContainsKey("Thumbprint"))
    {
        WriteLog -Message "  Validating Thumbprint"
        if ($node.Thumbprint -ne "<THUMBPRINT>" -and
            (Confirm-CertificateThumbPrint -ThumbPrint $node.Thumbprint) -eq $false)
        {
            WriteError -Message "Specified Thumbprint $($node.Thumbprint) is invalid. Make sure it is correct!"
        }
    }
    else
    {
        if ($node.NodeName -ne "*")
        {
            WriteError -Message "$($node.NodeName) doesn't have a Thumbprint specified"
        }
    }

    if ($node.ContainsKey("CertificateFile"))
    {
        WriteLog -Message "  Validating CertificateFile"
        if ($node.CertificateFile -ne "<CERTFILE>" -and
            (Test-Path -Path $node.CertificateFile) -eq $false)
        {
            WriteError -Message "Specified CertificateFile $($node.CertificateFile) does not exist. Make sure that it does!"
        }
    }
    else
    {
        if ($node.NodeName -ne "*")
        {
            WriteError -Message "$($node.NodeName) doesn't have a CertificateFile specified"
        }
    }
}

WriteLog -Message "Confirm that all SharePoint roles are specified at least once"
if ($spfePresent -eq $false -or $spbePresent -eq $false -or $searchfePresent -eq $false -or $searchbePresent -eq $false)
{
    WriteError -Message "Not all SharePoint roles are specified:"
    WriteError -Message "SPFE     : $(if ($spfePresent -eq $true) { "Present" } else { "NotPresent" })"
    WriteError -Message "SPBE     : $(if ($spbePresent -eq $true) { "Present" } else { "NotPresent" })"
    WriteError -Message "SearchFE : $(if ($searchfePresent -eq $true) { "Present" } else { "NotPresent" })"
    WriteError -Message "SearchBE : $(if ($searchbePresent -eq $true) { "Present" } else { "NotPresent" })"
}
#endregion

#region InstallPaths
WriteLog -Message "Validating InstallPaths section"
if ($DataFile.NonNodeData.ContainsKey("InstallPaths"))
{
    if ($DataFile.NonNodeData.InstallPaths.ContainsKey("InstallFolder") -eq $false)
    {
        WriteError -Message "InstallFolder setting is missing in the InstallPaths section"
    }

    if ($DataFile.NonNodeData.InstallPaths.ContainsKey("CertificatesFolder") -eq $false)
    {
        WriteError -Message "CertificatesFolder setting is missing in the InstallPaths section"
    }
}
else
{
    WriteError -Message "InstallPaths section is missing in the NonNodeData section"
}
#endregion

#region Certificates
WriteLog -Message "Validating Certificates section"
if ($DataFile.NonNodeData.ContainsKey("Certificates"))
{
    if ($DataFile.NonNodeData.Certificates.ContainsKey("Portal") -eq $false)
    {
        WriteError -Message "Portal setting is missing in the Certificates section"
    }
    else
    {
        if ($DataFile.NonNodeData.Certificates.Portal.ContainsKey("File") -eq $false)
        {
            WriteError -Message "File setting is missing in the Certificates\Portal section"
        }

        if ($DataFile.NonNodeData.Certificates.Portal.ContainsKey("Thumbprint") -eq $false)
        {
            WriteError -Message "Thumbprint setting is missing in the Certificates\Portal section"
        }
        else
        {
            if ((Confirm-CertificateThumbPrint -ThumbPrint $DataFile.NonNodeData.Certificates.Portal.Thumbprint) -eq $false)
            {
                WriteError -Message "Specified Thumbprint '$($DataFile.NonNodeData.Certificates.Portal.Thumbprint)' in Certificates\Portal section is invalid."
            }
        }

        if ($DataFile.NonNodeData.Certificates.Portal.ContainsKey("FriendlyName") -eq $false)
        {
            WriteError -Message "FriendlyName setting is missing in the Certificates\Portal section"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ProvisionApps -eq $true)
    {
        if ($DataFile.NonNodeData.Certificates.ContainsKey("PortalApps") -eq $false)
        {
            WriteError -Message "PortalApps setting is missing in the Certificates section"
        }
        else
        {
            if ($DataFile.NonNodeData.Certificates.PortalApps.ContainsKey("File") -eq $false)
            {
                WriteError -Message "File setting is missing in the Certificates\PortalApps section"
            }

            if ($DataFile.NonNodeData.Certificates.PortalApps.ContainsKey("Thumbprint") -eq $false)
            {
                WriteError -Message "Thumbprint setting is missing in the Certificates\PortalApps section"
            }
            else
            {
                if ((Confirm-CertificateThumbPrint -ThumbPrint $DataFile.NonNodeData.Certificates.PortalApps.Thumbprint) -eq $false)
                {
                    WriteError -Message "Specified Thumbprint '$($DataFile.NonNodeData.Certificates.PortalApps.Thumbprint)' in Certificates\PortalApps section is invalid."
                }
            }

            if ($DataFile.NonNodeData.Certificates.PortalApps.ContainsKey("FriendlyName") -eq $false)
            {
                WriteError -Message "FriendlyName setting is missing in the Certificates\PortalApps section"
            }
        }

        if ($DataFile.NonNodeData.Certificates.ContainsKey("ProviderApps") -eq $false)
        {
            WriteError -Message "ProviderApps setting is missing in the Certificates section"
        }
        else
        {
            if ($DataFile.NonNodeData.Certificates.ProviderApps.ContainsKey("File") -eq $false)
            {
                WriteError -Message "File setting is missing in the Certificates\ProviderApps section"
            }

            if ($DataFile.NonNodeData.Certificates.ProviderApps.ContainsKey("Thumbprint") -eq $false)
            {
                WriteError -Message "Thumbprint setting is missing in the Certificates\ProviderApps section"
            }
            else
            {
                if ((Confirm-CertificateThumbPrint -ThumbPrint $DataFile.NonNodeData.Certificates.ProviderApps.Thumbprint) -eq $false)
                {
                    WriteError -Message "Specified Thumbprint '$($DataFile.NonNodeData.Certificates.ProviderApps.Thumbprint)' in Certificates\ProviderApps section is invalid."
                }
            }

            if ($DataFile.NonNodeData.Certificates.ProviderApps.ContainsKey("FriendlyName") -eq $false)
            {
                WriteError -Message "FriendlyName setting is missing in the Certificates\ProviderApps section"
            }
        }
    }
}
else
{
    WriteError -Message "Certificates section is missing in the NonNodeData section"
}
#endregion

#region DomainDetails
WriteLog -Message "Validating DomainDetails section"
if ($DataFile.NonNodeData.ContainsKey("DomainDetails"))
{
    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("DomainName") -eq $false)
    {
        WriteError -Message "DomainName setting is missing in the DomainDetails section"
    }

    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("NetbiosName") -eq $false)
    {
        WriteError -Message "NetbiosName setting is missing in the DomainDetails section"
    }

    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("DBServerCont") -eq $false)
    {
        WriteError -Message "DBServerCont setting is missing in the DomainDetails section"
    }

    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("DBServerInfr") -eq $false)
    {
        WriteError -Message "DBServerInfr setting is missing in the DomainDetails section"
    }

    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("DBServerSear") -eq $false)
    {
        WriteError -Message "DBServerSear setting is missing in the DomainDetails section"
    }

    if ($DataFile.NonNodeData.DomainDetails.ContainsKey("DBSAUserName") -eq $false)
    {
        WriteError -Message "DBSAUserName setting is missing in the DomainDetails section"
    }
}
else
{
    WriteError -Message "DomainDetails section is missing in the NonNodeData section"
}
#endregion

#region Logging
WriteLog -Message "Validating Logging section"
if ($DataFile.NonNodeData.ContainsKey("Logging"))
{
    if ($DataFile.NonNodeData.Logging.ContainsKey("ULSLogPath") -eq $false)
    {
        WriteError -Message "ULSLogPath setting is missing in the Logging section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.Logging.ULSLogPath) -eq $false)
        {
            WriteError -Message "ULSLogPath in section Logging is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("ULSMaxSizeInGB") -eq $false)
    {
        WriteError -Message "ULSMaxSizeInGB setting is missing in the Logging section"
    }
    else
    {
        if ($DataFile.NonNodeData.Logging.ULSMaxSizeInGB -lt 1 -or $DataFile.NonNodeData.Logging.ULSMaxSizeInGB -gt 1000)
        {
            WriteError -Message "ULSMaxSizeInGB setting in the Logging section supports values between 1 and 1000"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("ULSDaysToKeep") -eq $false)
    {
        WriteError -Message "ULSDaysToKeep setting is missing in the Logging section"
    }
    else
    {
        if ($DataFile.NonNodeData.Logging.ULSDaysToKeep -lt 1 -or $DataFile.NonNodeData.Logging.ULSDaysToKeep -gt 366)
        {
            WriteError -Message "ULSDaysToKeep setting in the Logging section supports values between 1 and 366"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("IISLogPath") -eq $false)
    {
        WriteError -Message "IISLogPath setting is missing in the Logging section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.Logging.IISLogPath) -eq $false)
        {
            WriteError -Message "IISLogPath in section Logging is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("UsageLogPath") -eq $false)
    {
        WriteError -Message "UsageLogPath setting is missing in the Logging section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.Logging.UsageLogPath) -eq $false)
        {
            WriteError -Message "UsageLogPath in section Logging is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("UsagePerLogInMinutes") -eq $false)
    {
        WriteError -Message "UsagePerLogInMinutes setting is missing in the Logging section"
    }
    else
    {
        if ($DataFile.NonNodeData.Logging.UsagePerLogInMinutes -lt 1 -or $DataFile.NonNodeData.Logging.UsagePerLogInMinutes -gt 1440)
        {
            WriteError -Message "UsagePerLogInMinutes setting in the Logging section supports values between 1 and 1440"
        }
    }

    if ($DataFile.NonNodeData.Logging.ContainsKey("UsageMaxLogSizeInMB") -eq $false)
    {
        WriteError -Message "UsageMaxLogSizeInMB setting is missing in the Logging section"
    }
    else
    {
        if ($DataFile.NonNodeData.Logging.UsageMaxLogSizeInMB -lt 1 -or $DataFile.NonNodeData.Logging.UsageMaxLogSizeInMB -gt 64)
        {
            WriteError -Message "UsageMaxLogSizeInMB setting in the Logging section supports values between 1 and 64"
        }
    }
}
else
{
    WriteError -Message "Logging section is missing in the NonNodeData section"
}
#endregion

#region SharePoint
WriteLog -Message "Validating SharePoint section"
if ($DataFile.NonNodeData.ContainsKey("SharePoint"))
{
    if ($DataFile.NonNodeData.SharePoint.ContainsKey("ProductKey") -eq $false)
    {
        WriteError -Message "ProductKey setting is missing in the SharePoint section"
    }
    else
    {
        if ((Confirm-ProductKey -ProductKey $DataFile.NonNodeData.SharePoint.ProductKey) -eq $false)
        {
            WriteError -Message "Specified ProductKey is not in the correct format"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ContainsKey("InstallPath") -eq $false)
    {
        WriteError -Message "InstallPath setting is missing in the SharePoint section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.SharePoint.InstallPath) -eq $false)
        {
            WriteError -Message "InstallPath in section SharePoint is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ContainsKey("DataPath") -eq $false)
    {
        WriteError -Message "DataPath setting is missing in the SharePoint section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.SharePoint.DataPath) -eq $false)
        {
            WriteError -Message "DataPath in section SharePoint is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ContainsKey("CUFileName") -eq $false)
    {
        WriteError -Message "CUFileName setting is missing in the SharePoint section"
    }
    else
    {
        if ($DataFile.NonNodeData.SharePoint.CUFileName -isnot [System.String])
        {
            WriteError -Message "CUFileName in section SharePoint is not a string"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ContainsKey("CULangFileName") -eq $false)
    {
        WriteError -Message "CULangFileName setting is missing in the SharePoint section"
    }
    else
    {
        if ($DataFile.NonNodeData.SharePoint.CULangFileName -isnot [System.String])
        {
            WriteError -Message "CULangFileName in section SharePoint is not a string"
        }
    }

    if ($DataFile.NonNodeData.SharePoint.ContainsKey("ProvisionApps") -eq $false)
    {
        WriteError -Message "ProvisionApps setting is missing in the SharePoint section"
    }
    else
    {
        if ($DataFile.NonNodeData.SharePoint.ProvisionApps -isnot [System.Boolean])
        {
            WriteError -Message "ProvisionApps in section SharePoint is not a boolean"
        }
    }
}
else
{
    WriteError -Message "SharePoint section is missing in the NonNodeData section"
}
#endregion

#region FarmConfig
WriteLog -Message "Validating FarmConfig section"
if ($DataFile.NonNodeData.ContainsKey("FarmConfig"))
{
    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("ConfigDBName") -eq $false)
    {
        WriteError -Message "ConfigDBName setting is missing in the FarmConfig section"
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("AdminContentDBName") -eq $false)
    {
        WriteError -Message "AdminContentDBName setting is missing in the FarmConfig section"
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("SuperReader") -eq $false)
    {
        WriteError -Message "SuperReader setting is missing in the FarmConfig section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.FarmConfig.SuperReader) -eq $false)
        {
            WriteError -Message "SuperReader parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("SuperUser") -eq $false)
    {
        WriteError -Message "SuperUser setting is missing in the FarmConfig section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.FarmConfig.SuperUser) -eq $false)
        {
            WriteError -Message "SuperUser parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("OutgoingEmail") -eq $false)
    {
        WriteError -Message "OutgoingEmail setting is missing in the FarmConfig section"
    }
    else
    {
        if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail -isnot [System.Collections.Hashtable])
        {
            WriteError -Message "OutgoingEmail setting is not a hashtable"
        }
        else
        {
            if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.ContainsKey("SMTPServer") -eq $false)
            {
                WriteError -Message "SMTPServer setting is missing in the OutgoingEmail section"
            }

            if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.ContainsKey("From") -eq $false)
            {
                WriteError -Message "From setting is missing in the OutgoingEmail section"
            }
            else
            {
                if ((Confirm-EmailAddress -EmailAddress $DataFile.NonNodeData.FarmConfig.OutgoingEmail.From) -eq $false)
                {
                    WriteError -Message "Specified field From is not a valid e-mail address"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.ContainsKey("ReplyTo") -eq $false)
            {
                WriteError -Message "ReplyTo setting is missing in the OutgoingEmail section"
            }
            else
            {
                if ((Confirm-EmailAddress -EmailAddress $DataFile.NonNodeData.FarmConfig.OutgoingEmail.ReplyTo) -eq $false)
                {
                    WriteError -Message "Specified field ReplyTo is not a valid e-mail address"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.ContainsKey("UseTLS") -eq $false)
            {
                WriteError -Message "UseTLS setting is missing in the OutgoingEmail section"
            }
            else
            {
                if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.UseTLS -isnot [System.Boolean])
                {
                    WriteError -Message "UseTLS setting is not a boolean (true/false)"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.ContainsKey("Port") -eq $false)
            {
                WriteError -Message "Port setting is missing in the OutgoingEmail section"
            }
            else
            {
                if ($DataFile.NonNodeData.FarmConfig.OutgoingEmail.Port -isnot [System.Int32])
                {
                    WriteError -Message "Port setting is not an integer (number)"
                }
            }
        }
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("SearchSettings") -eq $false)
    {
        WriteError -Message "SearchSettings setting is missing in the FarmConfig section"
    }
    else
    {
        if ($DataFile.NonNodeData.FarmConfig.SearchSettings -isnot [System.Collections.Hashtable])
        {
            WriteError -Message "SearchSettings setting is not a hashtable"
        }
        else
        {
            if ($DataFile.NonNodeData.FarmConfig.SearchSettings.ContainsKey("PerformanceLevel") -eq $false)
            {
                WriteError -Message "PerformanceLevel setting is missing in the SearchSettings section"
            }

            if ($DataFile.NonNodeData.FarmConfig.SearchSettings.ContainsKey("ContactEmail") -eq $false)
            {
                WriteError -Message "ContactEmail setting is missing in the SearchSettings section"
            }
            else
            {
                if ((Confirm-EmailAddress -EmailAddress $DataFile.NonNodeData.FarmConfig.SearchSettings.ContactEmail) -eq $false)
                {
                    WriteError -Message "Specified ContactEmail is not a valid e-mail address"
                }
            }
        }
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("AppsSettings") -eq $false)
    {
        WriteError -Message "AppsSettings setting is missing in the FarmConfig section"
    }
    else
    {
        if ($DataFile.NonNodeData.FarmConfig.AppsSettings -isnot [System.Collections.Hashtable])
        {
            WriteError -Message "AppsSettings setting is not a hashtable"
        }
        else
        {
            if ($DataFile.NonNodeData.FarmConfig.AppsSettings.ContainsKey("AppDomain") -eq $false)
            {
                WriteError -Message "AppDomain setting is missing in the AppsSettings section"
            }
            else
            {
                if ((Confirm-DomainName -DomainName $DataFile.NonNodeData.FarmConfig.AppsSettings.AppDomain) -eq $false)
                {
                    WriteError -Message "AppDomain in section AppsSettings is not a valid domain name"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.AppsSettings.ContainsKey("Prefix") -eq $false)
            {
                WriteError -Message "Prefix setting is missing in the AppsSettings section"
            }

            if ($DataFile.NonNodeData.FarmConfig.AppsSettings.ContainsKey("AllowAppPurchases") -eq $false)
            {
                WriteError -Message "AllowAppPurchases setting is missing in the AppsSettings section"
            }
            else
            {
                if ($DataFile.NonNodeData.FarmConfig.AppsSettings.AllowAppPurchases -isnot [System.Boolean])
                {
                    WriteError -Message "AllowAppPurchases setting in section AppsSettings is not a boolean (true/false)"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.AppsSettings.ContainsKey("AllowAppsForOffice") -eq $false)
            {
                WriteError -Message "AllowAppsForOffice setting is missing in the AppsSettings section"
            }
            else
            {
                if ($DataFile.NonNodeData.FarmConfig.AppsSettings.AllowAppsForOffice -isnot [System.Boolean])
                {
                    WriteError -Message "AllowAppsForOffice setting in section AppsSettings is not a boolean (true/false)"
                }
            }
        }
    }

    if ($DataFile.NonNodeData.FarmConfig.ContainsKey("PasswordChangeSchedule") -eq $false)
    {
        WriteError -Message "PasswordChangeSchedule setting is missing in the FarmConfig section"
    }
    else
    {
        if ($DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule -isnot [System.Collections.Hashtable])
        {
            WriteError -Message "PasswordChangeSchedule setting is not a hashtable"
        }
        else
        {
            if ($DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule.ContainsKey("Day") -eq $false)
            {
                WriteError -Message "Day setting is missing in the PasswordChangeSchedule section"
            }
            else
            {
                if ($DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule.Day -notin @("mon", "tue", "wed", "thu", "fri", "sat", "sun"))
                {
                    WriteError -Message "Day in section PasswordChangeSchedule is not a valid day abbreviation"
                }
            }

            if ($DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule.ContainsKey("Hour") -eq $false)
            {
                WriteError -Message "Hour setting is missing in the PasswordChangeSchedule section"
            }
            else
            {
                $hour = $DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule.Hour
                if ($DataFile.NonNodeData.FarmConfig.PasswordChangeSchedule.Hour -isnot [System.Int32] -or `
                        $hour -lt 0 -or `
                        $hour -gt 23)
                {
                    WriteError -Message "Hour setting in section PasswordChangeSchedule is not an integer between 0 and 23"
                }
            }
        }
    }
}
else
{
    WriteError -Message "FarmConfig section is missing in the NonNodeData section"
}
#endregion

#region CentralAdminSite
WriteLog -Message "Validating CentralAdminSite section"
if ($DataFile.NonNodeData.ContainsKey("CentralAdminSite"))
{
    if ($DataFile.NonNodeData.CentralAdminSite.ContainsKey("WebAppName") -eq $false)
    {
        WriteError -Message "WebAppName setting is missing in the CentralAdminSite section"
    }

    if ($DataFile.NonNodeData.CentralAdminSite.ContainsKey("PhysicalPath") -eq $false)
    {
        WriteError -Message "PhysicalPath setting is missing in the CentralAdminSite section"
    }
    else
    {
        if ((Confirm-Path -Path $DataFile.NonNodeData.CentralAdminSite.PhysicalPath) -eq $false)
        {
            WriteError -Message "PhysicalPath is not a valid path"
        }
    }

    if ($DataFile.NonNodeData.CentralAdminSite.ContainsKey("AppPool") -eq $false)
    {
        WriteError -Message "AppPool setting is missing in the CentralAdminSite section"
    }

    if ($DataFile.NonNodeData.CentralAdminSite.ContainsKey("SiteURL") -eq $false)
    {
        WriteError -Message "SiteURL setting is missing in the CentralAdminSite section"
    }
    else
    {
        if ((Confirm-DomainName -DomainName $DataFile.NonNodeData.CentralAdminSite.SiteURL) -eq $false)
        {
            WriteError -Message "SiteURL is not a valid domain name"
        }
    }

    if ($DataFile.NonNodeData.CentralAdminSite.ContainsKey("Certificate") -eq $false)
    {
        WriteError -Message "Certificate setting is missing in the CentralAdminSite section"
    }
}
else
{
    WriteError -Message "CentralAdminSite section is missing in the NonNodeData section"
}
#endregion

#region ActiveDirectory
WriteLog -Message "Validating ActiveDirectory section"
if ($DataFile.NonNodeData.ContainsKey("ActiveDirectory"))
{
    if ($DataFile.NonNodeData.ActiveDirectory.ContainsKey("UserOU") -eq $false)
    {
        WriteError -Message "UserOU setting is missing in the ActiveDirectory section"
    }
    else
    {
        if ((Confirm-OUName -OUName $DataFile.NonNodeData.ActiveDirectory.UserOU) -eq $false)
        {
            WriteError -Message "UserOU is not a valid OU name"
        }
    }
}
else
{
    WriteError -Message "ActiveDirectory section is missing in the NonNodeData section"
}
#endregion

#region ManagedAccounts
WriteLog -Message "Validating ManagedAccounts section"
if ($DataFile.NonNodeData.ContainsKey("ManagedAccounts"))
{
    if ($DataFile.NonNodeData.ManagedAccounts.ContainsKey("Farm") -eq $false)
    {
        WriteError -Message "Farm setting is missing in the ManagedAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ManagedAccounts.Farm) -eq $false)
        {
            WriteError -Message "Farm parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ManagedAccounts.ContainsKey("Services") -eq $false)
    {
        WriteError -Message "Services setting is missing in the ManagedAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ManagedAccounts.Services) -eq $false)
        {
            WriteError -Message "Services parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ManagedAccounts.ContainsKey("Search") -eq $false)
    {
        WriteError -Message "Search setting is missing in the ManagedAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ManagedAccounts.Search) -eq $false)
        {
            WriteError -Message "Search parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ManagedAccounts.ContainsKey("UpsSync") -eq $false)
    {
        WriteError -Message "UpsSync setting is missing in the ManagedAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ManagedAccounts.UpsSync) -eq $false)
        {
            WriteError -Message "UpsSync parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ManagedAccounts.ContainsKey("AppPool") -eq $false)
    {
        WriteError -Message "AppPool setting is missing in the ManagedAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ManagedAccounts.AppPool) -eq $false)
        {
            WriteError -Message "AppPool parameter is not in the valid domain\user format"
        }
    }
}
else
{
    WriteError -Message "ManagedAccounts section is missing in the NonNodeData section"
}
#endregion

#region ServiceAccounts
WriteLog -Message "Validating ServiceAccounts section"
if ($DataFile.NonNodeData.ContainsKey("ServiceAccounts"))
{
    if ($DataFile.NonNodeData.ServiceAccounts.ContainsKey("SuperReader") -eq $false)
    {
        WriteError -Message "SuperReader setting is missing in the ServiceAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ServiceAccounts.SuperReader) -eq $false)
        {
            WriteError -Message "SuperReader parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ServiceAccounts.ContainsKey("SuperUser") -eq $false)
    {
        WriteError -Message "SuperUser setting is missing in the ServiceAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ServiceAccounts.SuperUser) -eq $false)
        {
            WriteError -Message "SuperUser parameter is not in the valid domain\user format"
        }
    }

    if ($DataFile.NonNodeData.ServiceAccounts.ContainsKey("ContentAccess") -eq $false)
    {
        WriteError -Message "ContentAccess setting is missing in the ServiceAccounts section"
    }
    else
    {
        if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ServiceAccounts.ContentAccess) -eq $false)
        {
            WriteError -Message "ContentAccess parameter is not in the valid domain\user format"
        }
    }
}
else
{
    WriteError -Message "ServiceAccounts section is missing in the NonNodeData section"
}
#endregion

#region ApplicationPools
WriteLog -Message "Validating ApplicationPools section"
if ($DataFile.NonNodeData.ContainsKey("ApplicationPools"))
{
    if ($DataFile.NonNodeData.ApplicationPools.ContainsKey("ServiceApplicationPools") -eq $false)
    {
        WriteError -Message "ServiceApplicationPools setting is missing in the ApplicationPools section"
    }
    else
    {
        if ($DataFile.NonNodeData.ApplicationPools.ServiceApplicationPools.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ApplicationPools\ServiceApplicationPools section"
        }
    }
}
else
{
    WriteError -Message "ApplicationPools section is missing in the NonNodeData section"
}
#endregion

#region ServiceApplications
WriteLog -Message "Validating ServiceApplications section"
if ($DataFile.NonNodeData.ContainsKey("ServiceApplications"))
{
    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("AppManagement") -eq $false)
    {
        WriteError -Message "AppManagement setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.AppManagement.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\AppManagement section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.AppManagement.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\AppManagement section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("BCSService") -eq $false)
    {
        WriteError -Message "BCSService setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.BCSService.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\BCSService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.BCSService.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\BCSService section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("ManagedMetaDataService") -eq $false)
    {
        WriteError -Message "ManagedMetaDataService setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.ManagedMetaDataService.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\ManagedMetaDataService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.ManagedMetaDataService.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\ManagedMetaDataService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.ManagedMetaDataService.ContainsKey("TermStoreAdministrators") -eq $false)
        {
            WriteError -Message "TermStoreAdministrators setting is missing in the ServiceApplications\ManagedMetaDataService section"
        }
        else
        {
            if ($DataFile.NonNodeData.ServiceApplications.ManagedMetaDataService.TermStoreAdministrators -isnot [System.Array])
            {
                WriteError -Message "TermStoreAdministrators setting is not an array"
            }
            else
            {
                foreach ($admin in $DataFile.NonNodeData.ServiceApplications.ManagedMetaDataService.TermStoreAdministrators)
                {
                    if ((Confirm-DomainUserName -DomainUserName $admin) -eq $false)
                    {
                        WriteError -Message "Specified user $admin in TermStoreAdministrators parameter is not in the valid domain\user format"
                    }
                }
            }
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("SearchService") -eq $false)
    {
        WriteError -Message "SearchService setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.SearchService.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\SearchService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.SearchService.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\SearchService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.SearchService.ContainsKey("DefaultContentAccessAccount") -eq $false)
        {
            WriteError -Message "DefaultContentAccessAccount setting is missing in the ServiceApplications\SearchService section"
        }
        else
        {
            if ((Confirm-DomainUserName -DomainUserName $DataFile.NonNodeData.ServiceApplications.SearchService.DefaultContentAccessAccount) -eq $false)
            {
                WriteError -Message "DefaultContentAccessAccount parameter is not in the valid domain\user format"
            }
        }

        if ($DataFile.NonNodeData.ServiceApplications.SearchService.ContainsKey("IndexPartitionRootDirectory") -eq $false)
        {
            WriteError -Message "IndexPartitionRootDirectory setting is missing in the ServiceApplications\SearchService section"
        }
        else
        {
            if ((Confirm-Path -Path $DataFile.NonNodeData.ServiceApplications.SearchService.IndexPartitionRootDirectory) -eq $false)
            {
                WriteError -Message "IndexPartitionRootDirectory parameter in ServiceApplications\SearchService section is not a valid path"
            }
        }

        if ($DataFile.NonNodeData.ServiceApplications.SearchService.ContainsKey("SearchCenterUrl") -eq $false)
        {
            WriteError -Message "SearchCenterUrl setting is missing in the ServiceApplications\SearchService section"
        }
        else
        {
            if ((Confirm-Url -URL $DataFile.NonNodeData.ServiceApplications.SearchService.SearchCenterUrl) -eq $false)
            {
                WriteError -Message "SearchCenterUrl parameter in ServiceApplications\SearchService section is not a valid URL"
            }
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("SecureStore") -eq $false)
    {
        WriteError -Message "SecureStore setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.SecureStore.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\SecureStore section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.SecureStore.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\SecureStore section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("StateService") -eq $false)
    {
        WriteError -Message "StateService setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.StateService.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\StateService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.StateService.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\StateService section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("SubscriptionSettings") -eq $false)
    {
        WriteError -Message "SubscriptionSettings setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.SubscriptionSettings.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\SubscriptionSettings section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.SubscriptionSettings.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\SubscriptionSettings section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("UsageAndHealth") -eq $false)
    {
        WriteError -Message "UsageAndHealth setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.UsageAndHealth.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\UsageAndHealth section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.UsageAndHealth.ContainsKey("DBName") -eq $false)
        {
            WriteError -Message "DBName setting is missing in the ServiceApplications\UsageAndHealth section"
        }
    }

    if ($DataFile.NonNodeData.ServiceApplications.ContainsKey("UserProfileService") -eq $false)
    {
        WriteError -Message "UserProfileService setting is missing in the ServiceApplications section"
    }
    else
    {
        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the ServiceApplications\UserProfileService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("MySiteHostLocation") -eq $false)
        {
            WriteError -Message "MySiteHostLocation setting is missing in the ServiceApplications\UserProfileService section"
        }
        else
        {
            if ((Confirm-Url -URL $DataFile.NonNodeData.ServiceApplications.UserProfileService.MySiteHostLocation) -eq $false)
            {
                WriteError -Message "MySiteHostLocation parameter in ServiceApplications\UserProfileService section is not a valid URL"
            }
        }

        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("ProfileDBName") -eq $false)
        {
            WriteError -Message "ProfileDBName setting is missing in the ServiceApplications\UserProfileService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("SocialDBName") -eq $false)
        {
            WriteError -Message "SocialDBName setting is missing in the ServiceApplications\UserProfileService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("SyncDBName") -eq $false)
        {
            WriteError -Message "SyncDBName setting is missing in the ServiceApplications\UserProfileService section"
        }

        if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.ContainsKey("UserProfileSyncConnection") -eq $false)
        {
            WriteError -Message "UserProfileSyncConnection setting is missing in the ServiceApplications\UserProfileService section"
        }
        else
        {
            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("Name") -eq $false)
            {
                WriteError -Message "Name setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }

            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("Forest") -eq $false)
            {
                WriteError -Message "Forest setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }
            else
            {
                if ((Confirm-DomainName -DomainName $DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Forest) -eq $false)
                {
                    WriteError -Message "Forest parameter in section UserProfileSyncConnection is not a valid domain name"
                }
            }

            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("UseSSL") -eq $false)
            {
                WriteError -Message "UseSSL setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }
            else
            {
                if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.UseSSL -isnot [System.Boolean])
                {
                    WriteError -Message 'UseSSL setting in section UserProfileSyncConnection must be $true or $false'
                }
            }

            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("Port") -eq $false)
            {
                WriteError -Message "Port setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }
            else
            {
                if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Port -isnot [System.Int32])
                {
                    WriteError -Message "Port setting in section UserProfileSyncConnection is not a number"
                }
                else
                {
                    if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Port -lt 1 -or
                        $DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.Port -gt 65534)
                    {
                        WriteError -Message "Port setting in section UserProfileSyncConnection must be between 0 and 65535"
                    }
                }
            }

            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("IncludedOUs") -eq $false)
            {
                WriteError -Message "IncludedOUs setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }
            else
            {
                if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.IncludedOUs -isnot [System.Array])
                {
                    WriteError -Message "IncludedOUs setting in section UserProfileSyncConnection is not an array"
                }
                else
                {
                    foreach ($ou in $DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.IncludedOUs)
                    {
                        if ((Confirm-OUName -OUName $ou) -eq $false)
                        {
                            WriteError -Message "IncludedOUs in section UserProfileSyncConnection contains invalid OU's"
                        }
                    }
                }
            }

            if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ContainsKey("ExcludedOUs") -eq $false)
            {
                WriteError -Message "ExcludedOUs setting is missing in the ServiceApplications\UserProfileService\UserProfileSyncConnection section"
            }
            else
            {
                if ($DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ExcludedOUs -isnot [System.Array])
                {
                    WriteError -Message "ExcludedOUs setting in section UserProfileSyncConnection is not an array"
                }
                else
                {
                    foreach ($ou in $DataFile.NonNodeData.ServiceApplications.UserProfileService.UserProfileSyncConnection.ExcludedOUs)
                    {
                        if ((Confirm-OUName -OUName $ou) -eq $false)
                        {
                            WriteError -Message "ExcludedOUs in section UserProfileSyncConnection contains invalid OU's"
                        }
                    }
                }
            }
        }
    }
}
else
{
    WriteError -Message "ServiceApplications section is missing in the NonNodeData section"
}
#endregion

#region TrustedIdentityTokenIssuer
WriteLog -Message "Validating TrustedIdentityTokenIssuer section"
if ($DataFile.NonNodeData.ContainsKey("TrustedIdentityTokenIssuer"))
{
    if ($DataFile.NonNodeData.TrustedIdentityTokenIssuer.ContainsKey("Realm") -eq $false)
    {
        WriteError -Message "Realm setting is missing in the TrustedIdentityTokenIssuer section"
    }
    else
    {
    }
}
#endregion

#region WebApplications
WriteLog -Message "Validating WebApplications section"
if ($DataFile.NonNodeData.ContainsKey("WebApplications"))
{
    foreach ($webapp in $DataFile.NonNodeData.WebApplications.GetEnumerator())
    {
        if ($DataFile.NonNodeData.SharePoint.ProvisionApps -eq $false -and
            $webAppEnum.Key -eq 'Apps')
        {
            continue
        }

        $webappData = $webapp.Value
        if ($webappData.ContainsKey("Name") -eq $false)
        {
            WriteError -Message "Name setting is missing in the WebApplications $($webapp.Name) section"
        }

        if ($webappData.ContainsKey("ApplicationPool") -eq $false)
        {
            WriteError -Message "ApplicationPool setting is missing in WebApplication $($webapp.Name) section"
        }

        if ($webappData.ContainsKey("ApplicationPoolAccount") -eq $false)
        {
            WriteError -Message "ApplicationPoolAccount setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ((Confirm-DomainUserName -DomainUserName $webappData.ApplicationPoolAccount) -eq $false)
            {
                WriteError -Message "Specified ApplicationPoolAccount $($webappData.ApplicationPoolAccount) in WebApplication $($webapp.Name) section is not in the valid domain\user format"
            }

        }

        if ($webappData.ContainsKey("DatabaseName") -eq $false)
        {
            WriteError -Message "DatabaseName setting is missing in WebApplication $($webapp.Name) section"
        }

        if ($webappData.ContainsKey("URL") -eq $false)
        {
            WriteError -Message "URL setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ((Confirm-URL -URL $webappData.URL) -eq $false)
            {
                WriteError -Message "Specified URL $($webappData.URL) in WebApplication $($webapp.Name) section is not a valid URL"
            }
        }

        if ($webappData.ContainsKey("Port") -eq $false)
        {
            WriteError -Message "Port setting is missing in WebApplication $($webapp.Name) section"
        }

        if ($webappData.ContainsKey("Protocol") -eq $false)
        {
            WriteError -Message "Protocol setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ($webappData.Protocol -notin @("HTTP", "HTTPS"))
            {
                WriteError -Message "Protocol '$($webappData.Protocol)' in WebApplication $($webapp.Name) section is invalid. It can only be HTTP or HTTPS"
            }
        }

        if ($webappData.ContainsKey("Certificate") -eq $false)
        {
            WriteError -Message "Certificate setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ($webappData.Certificate -isnot [System.String])
            {
                WriteError -Message "Certificate in WebApplication $($webapp.Name) section is not a string."
            }
        }

        if ($webappData.ContainsKey("CertificateStoreName") -eq $false)
        {
            WriteError -Message "CertificateStoreName setting is missing in WebApplication $($webapp.Name) section"
        }

        if ($webappData.ContainsKey("BlobCacheFolder") -eq $false)
        {
            WriteError -Message "BlobCacheFolder setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ((Confirm-Path -Path $webappData.BlobCacheFolder) -eq $false)
            {
                WriteError -Message "Specified BlobCacheFolder $($webappData.BlobCacheFolder) in WebApplication $($webapp.Name) section is not a valid path"
            }
        }

        if ($webappData.ContainsKey("BlobCacheSize") -eq $false)
        {
            WriteError -Message "BlobCacheSize setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ($webappData.BlobCacheSize -isnot [System.Int32])
            {
                WriteError -Message "Specified BlobCacheSize $($webappData.BlobCacheSize) in WebApplication $($webapp.Name) section is not a valid number"
            }
        }

        if ($webappData.ContainsKey("BlobCacheFileTypes") -eq $false)
        {
            WriteError -Message "BlobCacheFileTypes setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ($webappData.BlobCacheFileTypes -isnot [System.String])
            {
                WriteError -Message "Specified BlobCacheFileTypes $($webappData.BlobCacheFileTypes) in WebApplication $($webapp.Name) section is not a valid string"
            }
        }

        if ($webappData.ContainsKey("OwnerAlias") -eq $false)
        {
            WriteError -Message "OwnerAlias setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ((Confirm-DomainUserName -DomainUserName $webappData.OwnerAlias) -eq $false)
            {
                WriteError -Message "Specified ApplicationPoolAccount $($webappData.OwnerAlias) in WebApplication $($webapp.Name) section is not in the valid domain\user format"
            }
        }

        if ($webappData.ContainsKey("PathBasedRootSiteCollection") -eq $false)
        {
            WriteError -Message "PathBasedRootSiteCollection setting is missing in WebApplication $($webapp.Name) section"
        }
        else
        {
            if ($webappData.PathBasedRootSiteCollection.ContainsKey("URL") -eq $false)
            {
                WriteError -Message "URL setting is missing in PathBasedRootSiteCollection section of WebApplication $($webapp.Name)"
            }
            else
            {
                if ((Confirm-URL -URL $webappData.PathBasedRootSiteCollection.URL) -eq $false)
                {
                    WriteError -Message "Specified URL $($webappData.URL) in PathBasedRootSiteCollection section of web application  $($webapp.Name) is not a valid URL"
                }
            }

            if ($webappData.PathBasedRootSiteCollection.ContainsKey("Name") -eq $false)
            {
                WriteError -Message "Name setting is missing in PathBasedRootSiteCollection section of WebApplication $($webapp.Name)"
            }

            if ($webappData.PathBasedRootSiteCollection.ContainsKey("Template") -eq $false)
            {
                WriteError -Message "Template setting is missing in PathBasedRootSiteCollection section of WebApplication $($webapp.Name)"
            }

            if ($webappData.PathBasedRootSiteCollection.ContainsKey("Language") -eq $false)
            {
                WriteError -Message "Language setting is missing in PathBasedRootSiteCollection section of WebApplication $($webapp.Name)"
            }

            if ($webappData.PathBasedRootSiteCollection.ContainsKey("ContentDatabase") -eq $false)
            {
                WriteError -Message "ContentDatabase setting is missing in PathBasedRootSiteCollection section of WebApplication $($webapp.Name)"
            }
        }

        if (($webappData.ContainsKey("HostNamedSiteCollections")) -eq $true)
        {
            foreach ($hnsc in $webappData.HostNamedSiteCollections)
            {
                if ($hnsc.ContainsKey("URL") -eq $false)
                {
                    WriteError -Message "URL setting is missing in HostNamedSiteCollections section of WebApplication $($webapp.Name)"
                }
                else
                {
                    if ((Confirm-URL -URL $hnsc.URL) -eq $false)
                    {
                        WriteError -Message "Specified URL $($webappData.URL) in HostNamedSiteCollections section of web application  $($webapp.Name) is not a valid URL"
                    }
                }

                if ($hnsc.ContainsKey("Name") -eq $false)
                {
                    WriteError -Message "Name setting is missing in HostNamedSiteCollections section of WebApplication $($webapp.Name)"
                }

                if ($hnsc.ContainsKey("Template") -eq $false)
                {
                    WriteError -Message "Template setting is missing in HostNamedSiteCollections section of WebApplication $($webapp.Name)"
                }

                if ($hnsc.ContainsKey("Language") -eq $false)
                {
                    WriteError -Message "Language setting is missing in HostNamedSiteCollections section of WebApplication $($webapp.Name)"
                }

                if ($hnsc.ContainsKey("ContentDatabase") -eq $false)
                {
                    WriteError -Message "ContentDatabase setting is missing in HostNamedSiteCollections section of WebApplication $($webapp.Name)"
                }
            }
        }
    }
}
else
{
    WriteError -Message "WebApplications section is missing in the NonNodeData section"
}
#endregion

if ($validConfig -eq $false)
{
    WriteError -Message " "
    WriteError -Message "Validation failed! Configuration contains errors."
}

return $validConfig
