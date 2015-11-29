function Get-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] $WebApplication
    )
    $result = @()
    $WebApplication.BlockedFileExtensions | ForEach-Object { $result += $_ }
    return @{
       Blocked = $result
    }
}

function Set-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )
    
    if ($Settings.Blocked -ne $null -and (($Settings.EnsureBlocked -ne $null) -or ($Settings.EnsureAllowed -ne $null))) {
        throw "Blocked file types must use either the 'blocked' property or the 'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both."
    }

    if ($Settings.Blocked -eq $null -and $Settings.EnsureBlocked -eq $null -and $Settings.EnsureAllowed -eq $null) {
        throw "Blocked file types must specify at least one property (either 'Blocked, 'EnsureBlocked' or 'EnsureAllowed')"
    }

    if($Settings.Blocked -ne $null ){
        $WebApplication.BlockedFileExtensions.Clear(); 
        $blockedFiles.Blocked | ForEach-Object {
            $WebApplication.BlockedFileExtensions.Add($_);
        }
    }

    if($Settings.EnsureBlocked -ne $null){
        $blockedFiles.EnsureBlocked | ForEach-Object {
            if(!$WebApplication.BlockedFileExtensions.ContainExtension($_)){
                $WebApplication.BlockedFileExtensions.Add($_);
            }
        }
    }

    if($Settings.EnsureAllowed -ne $null){
        $blockedFiles.EnsureAllowed | ForEach-Object {
            if($WebApplication.BlockedFileExtensions.ContainExtension($_)){
                $WebApplication.BlockedFileExtensions.Remove($_);
            }
        }
    }
}

function Test-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )

    if ($DesiredSettings.Blocked -ne $null -and (($DesiredSettings.EnsureBlocked -ne $null) -or ($DesiredSettings.EnsureAllowed -ne $null))) {
        throw "Blocked file types must use either the 'blocked' property or the 'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both."
    }

    if ($DesiredSettings.Blocked -eq $null -and $DesiredSettings.EnsureBlocked -eq $null -and $DesiredSettings.EnsureAllowed -eq $null) {
        throw "Blocked file types must specify at least one property (either 'Blocked, 'EnsureBlocked' or 'EnsureAllowed')"
    }

    if ($DesiredSettings.Blocked -ne $null) {
        $compareResult = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.Blocked
        if ($compareResult -eq $null) { return $true } else { return $false }
    }
    
    if($DesiredSettings.EnsureBlocked -ne $null){
        $itemsToRemove = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.EnsureBlocked -IncludeEqual -ExcludeDifferent
        if ($itemsToRemove -ne $null) { return $false }
    }

    if($DesiredSettings.EnsureAllowed -ne $null){
        $itemsToAdd = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.EnsureAllowed | Where-Object { $_.SideIndicator -eq "=>"}
        if ($itemsToAdd -ne $null) { return $false }
    }

    return $true
}

