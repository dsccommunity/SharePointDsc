function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    Write-Verbose -Message "Getting service instance '$Name'"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        

        $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
        if ($null -eq $si) { return @{
            Name = $params.Name
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        } }
        if ($si.Status -eq "Online") { $localEnsure = "Present" } else { $localEnsure = "Absent" }
        
        return @{
            Name = $params.Name
            Ensure = $localEnsure
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
        [parameter(Mandatory = $true)]  [System.String] $Name,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    if ($Ensure -eq "Present") {
        Write-Verbose -Message "Provisioning service instance '$Name'"

        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            

            $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) { 
                throw [Exception] "Unable to locate service application '$($params.Name)'"
            }
            Start-SPServiceInstance -Identity $si 
        }
    } else {
        Write-Verbose -Message "Deprovioning service instance '$Name'"

        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            

            $si = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object { $_.TypeName -eq $params.Name }
            if ($null -eq $si) {
                throw [Exception] "Unable to locate service application '$($params.Name)'"
            }
            Stop-SPServiceInstance -Identity $si
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
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] [System.String] $Ensure = "Present"
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Getting service instance '$Name'"
    $PSBoundParameters.Ensure = $Ensure
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Name", "Ensure")
}


Export-ModuleMember -Function *-TargetResource

