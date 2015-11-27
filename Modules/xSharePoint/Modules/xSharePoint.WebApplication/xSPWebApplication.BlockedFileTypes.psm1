function Get-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)] $WebApplication
    )
    return @{
       Blocked = @()
    }
}

function Set-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] $WebApplication,
        [parameter(Mandatory = $true)] $Settings
    )
    
}

function Test-xSPWebApplicationBlockedFileTypes {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)] $CurrentSettings,
        [parameter(Mandatory = $true)] $DesiredSettings
    )

    $testReturn = Test-xSharePointSpecificParameters -CurrentValues $CurrentSettings `
                                                     -DesiredValues $DesiredSettings
    return $testReturn
}

