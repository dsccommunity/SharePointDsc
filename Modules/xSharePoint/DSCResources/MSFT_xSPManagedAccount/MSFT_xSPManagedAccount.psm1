function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Account,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,
    
        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    Write-Verbose -Message "Checking for managed account $AccountName"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $ma = Get-SPManagedAccount $params.AccountName -ErrorAction SilentlyContinue
            if ($null -eq $ma) { return @{ } }
            return @{
                AccountName = $ma.Userame
                AutomaticChange = $ma.AutomaticChange
                DaysBeforeChangeToEmail = $ma.DaysBeforeChangeToEmail
                DaysBeforeExpiryToChange = $ma.DaysBeforeExpiryToChange
                PasswordLastChanged = $ma.PasswordLastChanged
                PasswordExpiration = $ma.PasswordExpiration
                ChangeSchedule = $ma.ChangeSchedule
            }
        } catch {
            return @{ }
        }
    }
    $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Account,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [System.UInt32]
        $EmailNotification = 5,

        [System.UInt32]
        $PreExpireDays = 2,

        [System.String]
        $Schedule = [System.String]::Empty,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )
    
    Write-Verbose -Message "Setting managed account $AccountName"

    $session = Get-xSharePointAuthenticatedPSSession -Credential $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $ma = Get-SPManagedAccount $params.Account.UserName -ErrorAction SilentlyContinue
        if ($null -eq $ma) {
            $ma = New-SPManagedAccount $params.Account
        }
        $params.Add("Identity", $params.Account.UserName)
        $params.Remove("Account") | Out-Null
        $params.Remove("AccountName") | Out-Null
        $params.Remove("InstallAccount") | Out-Null

        Set-SPManagedAccount @params
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $Account,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [System.UInt32]
        $EmailNotification = 5,

        [System.UInt32]
        $PreExpireDays = 2,

        [System.String]
        $Schedule = [System.String]::Empty,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    $result = Get-TargetResource -Account $Account -InstallAccount $InstallAccount -AccountName $AccountName
    Write-Verbose -Message "Testing managed account $AccountName"
    if ($result.Count -eq 0) { return $false }
    else {
        if($result.AutomaticChange -eq $true) {
            if($result.ChangeSchedule -ne $Schedule) { return $false }
            if($result.DaysBeforeExpiryToChange -ne $PreExpireDays) { return $false }
            if($result.DaysBeforeChangeToEmail -ne $EmailNotification) { return $false }
        }
    }
    return $true
}


Export-ModuleMember -Function *-TargetResource

