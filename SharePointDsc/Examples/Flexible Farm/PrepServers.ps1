#region ##### FUNCTIONS #####
function WriteLog
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message
    )

    $date = Get-Date -f 'yyy-MM-dd HH:mm:ss'
    Write-Output "$date - $Message"
}
#endregion FUNCTIONS

#region INITIALIZE VARIABLES
$buildingBlockVersion = [System.Version]'1.0.0'
$ResSourceLocation = 'D:\SPSources\2019\Resources'
$certLocation = 'D:\SPCertificates'
$defaultFolder = $PSScriptRoot
$serverThumbprints = @{}
#endregion INITIALIZE VARIABLES

#region SCRIPT BODY
WriteLog -Message 'Starting PrepServers script'
WriteLog -Message "Running as $(&whoami)"

Set-Location $defaultFolder

#region Check Prerequisites
WriteLog -Message 'Checking prerequisites'
WriteLog -Message '  Checking Datafile variable'

WriteLog -Message '    Checking Building Block versions:'
$dataFileVersion = [System.Version]$DataFile.NonNodeData.BuildingBlock.Version
WriteLog -Message "    - Data file version : $($dataFileVersion.ToString())"
WriteLog -Message "    - Script version    : $($buildingBlockVersion.ToString())"
if ($dataFileVersion -eq $buildingBlockVersion)
{
    WriteLog -Message '    Versions equal, proceeding...'
}
else
{
    WriteLog -Message '    Versions do not match, please check the building block versions. Quiting!'
    Exit 10
}

if ($null -eq $Datafile)
{
    WriteLog -Message '    [ERROR] Datafile variable not specified. Have you ran the PrepVariables script?'
    Exit 50
}

WriteLog -Message '  Checking specified ResSourceLocation path'
if ((Test-Path -Path $ResSourceLocation) -eq $false)
{
    WriteLog -Message "    [ERROR] Specified Resource path does not exist: $ResSourceLocation"
    Exit 100
}
#endregion Check Prerequisites

#region Deploy DSC Encryption certificates
WriteLog -Message 'Starting Check/Deploy DSC Encryption Certificates to all servers'

$servers = $DataFile.AllNodes.NodeName | Where-Object { $_ -ne '*' }

foreach ($server in $servers)
{
    WriteLog -Message "  Processing server $server"
    $serverThumbprints.$server = @{}

    $session = New-PSSession -ComputerName $server

    $lcm = Invoke-Command -Session $session -ScriptBlock {
        return (Get-DscLocalConfigurationManager)
    }

    $foundError = $false
    $serverThumbprint = ''

    if ($null -eq $lcm.CertificateID)
    {
        WriteLog -Message '    No certificate configured. Generating new certificate.'
        $certificate = Invoke-Command -Session $session -ScriptBlock {
            $cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp `
                -DnsName 'DSCNode Document Encryption' `
                -HashAlgorithm SHA256 `
                -KeyExportPolicy NonExportable `
                -NotAfter (Get-Date).AddYears(10)
            return $cert
        }
        $serverThumbprint = $certificate.Thumbprint
        WriteLog -Message "    Certificate created with thumbprint $($certificate.Thumbprint)"
    }
    else
    {
        WriteLog -Message "    Certificate configured: $($lcm.CertificateID)"
        WriteLog -Message '    Checking presence of certificate.'

        $certificate = Invoke-Command -Session $session -ArgumentList $lcm.CertificateID -ScriptBlock {
            $thumbprint = $args[0]
            if (Test-Path -Path "Cert:\LocalMachine\My\$thumbprint")
            {
                # Checking cert
                $cert = Get-ChildItem "Cert:\LocalMachine\My\$thumbprint"
            }
            else
            {
                return $cert = $null
            }
            return $cert
        }

        if ($null -ne $certificate)
        {
            WriteLog -Message '    Certificate exists, checking validity.'
            $certValidity = $certificate.NotAfter - (Get-Date)
            if ($certValidity.TotalDays -le 1826)
            {
                Add-Type -AssemblyName System.Windows.Forms
                $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
                $choice = [System.Windows.Forms.MessageBox]::Show("Configured DSC certificate valid for less than five years.`n`nCertificate valid until: $($certificate.NotAfter)`n`nDo you want to use this certificate?", "  WARNING", $buttons)
                if ($choice -eq 'Yes')
                {
                    WriteLog -Message '    Approved. Using certificate.'
                }
                else
                {
                    WriteLog -Message '    Denied! Not using specified certificate. Skipping to next server!'
                    continue
                }
            }

            if ($null -eq ($certificate.Extensions | Where-Object { $_.KeyUsages -match 'DataEncipherment' -or $_.KeyUsages -match 'KeyEncipherment' }))
            {
                Write-Host 'ERROR: Configured DSC certificate does not have DataEncipherment or KeyEncipherment extensions configured!' -ForegroundColor Red
                $foundError = $true
            }

            if ($null -ne ($certificate.Extensions | Where-Object { $_.KeyUsages -match 'Digital Signature' }))
            {
                Write-Host 'ERROR: Configured DSC certificate should not have Digital Signature extensions configured!' -ForegroundColor Red
                $foundError = $true
            }

            if ($null -eq ($certificate.EnhancedKeyUsageList | Where-Object { $_.FriendlyName -match 'Document Encryption' }))
            {
                Write-Host 'ERROR: Configured DSC certificate does not have "Document Encryption" Enhanced Key Usage configured!' -ForegroundColor Red
                $foundError = $true
            }

            if ($null -ne ($certificate.EnhancedKeyUsageList | Where-Object { $_.FriendlyName -match 'Client Authentication' -or $_.FriendlyName -match 'Server Authentication' }))
            {
                Write-Host 'ERROR: Configured DSC certificate should not have "Client Authentication" or "Server Authentication" Enhanced Key Usage configured!' -ForegroundColor Red
                $foundError = $true
            }

            $serverThumbprint = $lcm.CertificateID
        }
        else
        {
            WriteLog -Message "    Configured DSC certificate with ID $($lcm.CertificateID) not found"
            $foundError = $true
        }
    }

    if ($foundError -eq $false)
    {
        $filename = "$server.cer"
        Invoke-Command -Session $session -ScriptBlock {
            $null = $cert | Export-Certificate -FilePath "C:\$($env:COMPUTERNAME).cer" -Force
        }
        WriteLog -Message '    Public certificate exported'

        Copy-Item -FromSession $session -Path "C:\$filename" -Destination $certLocation
        Remove-Item "\\$server\c$\$filename"

        $serverThumbprints.$server.Thumbprint = $serverThumbprint
        $serverThumbprints.$server.CertificateFile = $filename
    }
    else
    {
        Write-Host 'Encountered error in certificate check, skipping certificate.'
        $serverThumbprints.$server = 'ERROR'
    }

    Invoke-Command -Session $session -ScriptBlock { if ( [int](Get-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb).Value -lt 1024 ) { Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb 1024 } }

    Remove-PSSession -Session $session
}

WriteLog -Message '  Reloading updated PSD1 file'
$global:DataFile = Import-PowerShellDataFile $ConfigPathFull

WriteLog -Message 'Completed Check/Deploy DSC Encryption Certificates to all servers'
#endregion Deploy DSC Encryption certificates

#region Update CertificateFiles and Thumbprints psd1 file
WriteLog -Message 'Updating PSD1 file with DSC Encryption Certificates information'
$content = Get-Content -Path $ConfigPathFull

$tempFile = Join-Path -Path $env:TEMP -ChildPath 'SharePoint.psd1'

if ((Test-Path -Path $tempFile) -eq $true)
{
    Remove-Item -Path $tempFile -Force
}

$server = ''
foreach ($line in $content)
{
    $newline = $line
    if ($line -match 'NodeName\s*=\s*"(\w*)"')
    {
        $newServer = $false
        $server = $Matches[1]
    }

    if ($line -match 'NonNodeData')
    {
        $newServer = $true
        $server = ''
    }

    if ($server -ne '')
    {
        if ($line -match 'Thumbprint\s*=\s*["''][A-z0-9<>]*["'']')
        {
            if ($serverThumbprints.ContainsKey($server) -and
                $serverThumbprints.$server.ContainsKey('Thumbprint') -and
                $serverThumbprints.$server.Thumbprint -ne '')
            {
                $thumbprint = $serverThumbprints.$server.Thumbprint
                $newline = $line -replace '["''][A-z0-9<>]*["'']', "'$thumbprint'"
                WriteLog "  Replacing thumbprint for server $server to $($serverThumbprints.$server.Thumbprint)!"
            }
            else
            {
                WriteLog "  [ERROR] Cannot replace thumbprint for server $server!"
            }
        }

        if ($line -match 'CertificateFile\s*=\s*')
        {
            if ($serverThumbprints.ContainsKey($server) -and
                $serverThumbprints.$server.ContainsKey('CertificateFile') -and
                $serverThumbprints.$server.Thumbprint -ne '')
            {
                $certificateFile = (Join-Path -Path 'C:\SPCertificates' -ChildPath $serverThumbprints.$server.CertificateFile)
                $regex = '["''][A-z09<>:\._]*["'']'
                $newline = $line -replace $regex, "'$certificateFile'"
                WriteLog "  Replacing CertificateFile for server $server to $certificateFile!"
            }
            else
            {
                WriteLog "  [ERROR] Cannot replace CertificateFile for server $server!"
            }
        }
    }

    if ($line -match '@{')
    {
        $newServer = $true
    }
    Add-Content -Value $newline -Path $tempFile
}
Copy-Item -Path $tempFile -Destination $ConfigPathFull -Force

Remove-Item -Path $tempFile -Force

WriteLog -Message '  Reloading updated PSD1 file'
$global:DataFile = Import-PowerShellDataFile $ConfigPathFull

WriteLog -Message 'Completed updating PSD1 file with DSC Encryption Certificates information'
#endregion Update CertificateFiles and Thumbprints psd1 file

#region Deploy DSC Modules
WriteLog -Message 'Deploying required DSC modules to all servers'

# Get server collections based on Role property
$camServers = ($DataFile.AllNodes | Where-Object { $_.Role -eq 'CAMApps' }).NodeName
$spServers = ($DataFile.AllNodes | Where-Object { $_.Role -eq 'SharePoint' }).NodeName

# Deployment Server (First SharePoint Backend server)
WriteLog '  Copying resources to deployment server'
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\ActiveDirectoryDsc') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\PsDscResources') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\xCredSSP') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\xWebAdministration') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\CertificateDsc') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\ComputerManagementDsc') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SharePointDsc') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SQLServerDsc') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force
Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SQLServer') -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse -Container -Force

WriteLog '  Unblock resource folders on deployment server'
Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\Modules' -Recurse | Unblock-File

# SharePoint Server
WriteLog '  Copying resources to SharePoint servers'
foreach ($sp in $spServers)
{
    WriteLog "    Copying resources to SharePoint server: $sp"
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\xCredSSP') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\xWebAdministration') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\CertificateDsc') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\ComputerManagementDsc') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SharePointDsc') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SQLServerDsc') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\SQLServer') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\ActiveDirectoryDsc') -Destination (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force

    WriteLog "    Unblock resource folders on SharePoint server: $sp"
    Get-ChildItem -Path (Join-Path -Path "\\$sp" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse | Unblock-File
}

# CAM Server
WriteLog '  Copying resources to CAM servers'
foreach ($cam in $camServers)
{
    WriteLog "    Copying resources to CAM server: $cam"
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\xWebAdministration') -Destination (Join-Path -Path "\\$cam" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\CertificateDsc') -Destination (Join-Path -Path "\\$cam" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\ComputerManagementDsc') -Destination (Join-Path -Path "\\$cam" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force
    Copy-Item -Path (Join-Path -Path $ResSourceLocation -ChildPath '\PsDscResources') -Destination (Join-Path -Path "\\$cam" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse -Container -Force

    WriteLog "    Unblock resource folders on CAM server: $cam"
    Get-ChildItem -Path (Join-Path -Path "\\$cam" -ChildPath 'C$\Program Files\WindowsPowerShell\Modules') -Recurse | Unblock-File
}
WriteLog -Message 'Completed deploying required DSC modules to all servers'
#endregion Deploy DSC Modules

#region Compile and deploy LCM configuration MOF file
WriteLog -Message 'Configure LCM on all servers'

. .\PrepServersConfig.ps1

foreach ($node in $DataFile.AllNodes)
{
    if ($node.CertificateFile -eq '<CERTFILE>')
    {
        WriteLog "  [ERROR] Node $($node.NodeName) does not have a valid Certificate File populated, cancelling compilation!"
        exit
    }

    if ($node.Thumbprint -eq '<THUMBPRINT>')
    {
        WriteLog "  [ERROR] Node $($node.NodeName) does not have a valid Thumbprint populated, cancelling compilation!"
        exit
    }
}

if ($null -ne $ConfigPathFull -and (Test-Path $ConfigPathFull) -eq $true)
{
    $outputPath = Join-Path -Path $ConfigPathFolder -ChildPath 'Deploy_PrepServers'
    Deploy_PrepServers -ConfigurationData $ConfigPathFull `
        -OutputPath $outputPath | Out-Null

    Set-DscLocalConfigurationManager -Path $outputPath -Verbose -Force
}
else
{
    Write-Output 'Configuration Data file unknown, did you run PrepVariables.ps1?'
    Exit 1000
}
WriteLog -Message 'Completed configuring LCM on all servers'
#endregion Compile and deploy LCM configuration MOF file

WriteLog -Message 'Completed PrepServers script'
#endregion SCRIPT BODY
