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
        [parameter(Mandatory = $true)] [Microsoft.Management.Infrastructure.CimInstance] $Settings
    )
    
    if ((Test-xSharePointObjectHasProperty $Settings "Blocked") -eq $true -and ((Test-xSharePointObjectHasProperty $Settings "EnsureBlocked") -eq $true -or (Test-xSharePointObjectHasProperty $Settings "EnsureAllowed") -eq $true)) {
        throw "Blocked file types must use either the 'blocked' property or the 'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both."
    }

    if ((Test-xSharePointObjectHasProperty $Settings "Blocked") -eq $false -and (Test-xSharePointObjectHasProperty $Settings "EnsureBlocked") -eq $false -and (Test-xSharePointObjectHasProperty $Settings "EnsureAllowed") -eq $false) {
        throw "Blocked file types must specify at least one property (either 'Blocked, 'EnsureBlocked' or 'EnsureAllowed')"
    }

    if((Test-xSharePointObjectHasProperty $Settings "Blocked") -eq $true) {
        $WebApplication.BlockedFileExtensions.Clear(); 
        $Settings.Blocked | ForEach-Object {
            $WebApplication.BlockedFileExtensions.Add($_.ToLower());
        }
    }

    if((Test-xSharePointObjectHasProperty $Settings "EnsureBlocked") -eq $true) {
        $Settings.EnsureBlocked | ForEach-Object {
            if(!$WebApplication.BlockedFileExtensions.Contains($_.ToLower())){
                $WebApplication.BlockedFileExtensions.Add($_.ToLower());
            }
        }
    }

    if((Test-xSharePointObjectHasProperty $Settings "EnsureAllowed") -eq $true) {
        $Settings.EnsureAllowed | ForEach-Object {
            if($WebApplication.BlockedFileExtensions.Contains($_.ToLower())){
                $WebApplication.BlockedFileExtensions.Remove($_.ToLower());
            }
        }
    }
}

function Test-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] [Microsoft.Management.Infrastructure.CimInstance] $DesiredSettings
    )
    Import-Module (Join-Path $PSScriptRoot "..\..\Modules\xSharePoint.Util\xSharePoint.Util.psm1" -Resolve)
    if ((Test-xSharePointObjectHasProperty $DesiredSettings "Blocked") -eq $true -and ((Test-xSharePointObjectHasProperty $DesiredSettings "EnsureBlocked") -eq $true -or (Test-xSharePointObjectHasProperty $DesiredSettings "EnsureAllowed") -eq $true)) {
        throw "Blocked file types must use either the 'blocked' property or the 'EnsureBlocked' and/or 'EnsureAllowed' properties, but not both."
    }

    if ((Test-xSharePointObjectHasProperty $DesiredSettings "Blocked") -eq $false -and (Test-xSharePointObjectHasProperty $DesiredSettings "EnsureBlocked") -eq $false -and (Test-xSharePointObjectHasProperty $DesiredSettings "EnsureAllowed") -eq $false) {
        throw "Blocked file types must specify at least one property (either 'Blocked, 'EnsureBlocked' or 'EnsureAllowed')"
    }

    if((Test-xSharePointObjectHasProperty $DesiredSettings "Blocked") -eq $true) {
        $compareResult = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.Blocked
        if ($compareResult -eq $null) { return $true } else { return $false }
    }
    
    if((Test-xSharePointObjectHasProperty $DesiredSettings "EnsureBlocked") -eq $true) {
        $itemsToRemove = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.EnsureBlocked -ExcludeDifferent
        if ($itemsToRemove -ne $null) { return $false }
    }

    if((Test-xSharePointObjectHasProperty $DesiredSettings "EnsureAllowed") -eq $true) {
        $itemsToAdd = Compare-Object -ReferenceObject $CurrentSettings.Blocked -DifferenceObject $DesiredSettings.EnsureAllowed | Where-Object { $_.SideIndicator -eq "=>"}
        if ($itemsToAdd -ne $null) {
            $compareResult = Compare-Object -ReferenceObject $DesiredSettings.EnsureAllowed -DifferenceObject $itemsToAdd.InputObject
            if ($compareResult -ne $null) { return $false }
        } else {
            return $false
        }   
    }

    return $true
}

