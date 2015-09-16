function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $Account,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $EmailNotification,
        [parameter(Mandatory = $false)] [System.UInt32] $PreExpireDays,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $true)]  [System.String] $AccountName
    )

    Write-Verbose -Message "Checking for managed account $AccountName"

    $result = Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        try {
            $ma = Invoke-xSharePointSPCmdlet -CmdletName "Get-SPManagedAccount" -Arguments @{ Identity = $params.Account.UserName } -ErrorAction SilentlyContinue
            if ($null -eq $ma) { return @{ } }
            return @{
                AccountName = $ma.Username
                EmailNotification = $ma.DaysBeforeChangeToEmail
                PreExpireDays = $ma.DaysBeforeExpiryToChange
                Schedule = $ma.ChangeSchedule
                Account = $params.Account
                InstallAccount = $params.InstallAccount
            }
        } catch {
            return @{ }
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $Account,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $EmailNotification,
        [parameter(Mandatory = $false)] [System.UInt32] $PreExpireDays,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $true)]  [System.String] $AccountName
    )
    
    Write-Verbose -Message "Setting managed account $AccountName"

    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $current = Get-TargetResource @params
        if ($current.Count -eq 0) {
            Invoke-xSharePointSPCmdlet -CmdletName "New-SPManagedAccount" -Arguments @{ Credential = $params.Account } 
        }

        $updateParams = @{ 
            Identity = $params.Account.UserName 
        }
        if ($params.ContainsKey("EmailNotification")) { $updateParams.Add("EmailNotification", $params.EmailNotification) }
        if ($params.ContainsKey("PreExpireDays")) { $updateParams.Add("PreExpireDays", $params.PreExpireDays) }
        if ($params.ContainsKey("Schedule")) { $updateParams.Add("Schedule", $params.Schedule) }

        Invoke-xSharePointSPCmdlet -CmdletName "Set-SPManagedAccount" -Arguments $updateParams
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $Account,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $EmailNotification,
        [parameter(Mandatory = $false)] [System.UInt32] $PreExpireDays,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $true)]  [System.String] $AccountName
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing managed account $AccountName"
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AccountName", "Schedule","PreExpireDays","EmailNotification") 
}


Export-ModuleMember -Function *-TargetResource

