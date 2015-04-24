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

    Write-Verbose "Checking for managed account $AccountName"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $ma = Get-SPManagedAccount $params.AccountName -ErrorAction SilentlyContinue
            if ($ma -eq $null) { return @{ } }
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
        $EmailNotification,

        [System.UInt32]
        $PreExpireDays,

        [System.String]
        $Schedule,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    Write-Verbose "Setting managed account $AccountName"

    $session = Get-xSharePointAuthenticatedPSSession $InstallAccount

    $result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $ma = Get-SPManagedAccount $params.Account.UserName -ErrorAction SilentlyContinue
        if ($ma -eq $null) {
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
        $EmailNotification,

        [System.UInt32]
        $PreExpireDays,

        [System.String]
        $Schedule,

        [parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    $result = Get-TargetResource -Account $Account -InstallAccount $InstallAccount -AccountName $AccountName
    Write-Verbose "Testing managed account $AccountName"
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

