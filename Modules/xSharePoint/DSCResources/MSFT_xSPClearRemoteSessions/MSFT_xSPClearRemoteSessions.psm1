function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ClearRemoteSessions
    )

    return Get-PSSession -ComputerName "localhost"
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ClearRemoteSessions
    )

    Get-PSSession -ComputerName "localhost" | Remove-PSSession
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Boolean]
        $ClearRemoteSessions
    )
    return !$ClearRemoteSessions
}


Export-ModuleMember -Function *-TargetResource

