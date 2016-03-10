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
        
        $ma = Get-SPManagedAccount -Identity $params.Account.UserName -ErrorAction SilentlyContinue
        if ($null -eq $ma) { return $null }
        $schedule = $null
        if ($ma.ChangeSchedule -ne $null) { $schedule = $ma.ChangeSchedule.ToString() }
        return @{
            AccountName = $ma.Username
            EmailNotification = $ma.DaysBeforeChangeToEmail
            PreExpireDays = $ma.DaysBeforeExpiryToChange
            Schedule = $schedule
            Account = $params.Account
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
        [parameter(Mandatory = $true)]  [System.Management.Automation.PSCredential] $Account,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount,
        [parameter(Mandatory = $false)] [System.UInt32] $EmailNotification,
        [parameter(Mandatory = $false)] [System.UInt32] $PreExpireDays,
        [parameter(Mandatory = $false)] [System.String] $Schedule,
        [parameter(Mandatory = $true)]  [System.String] $AccountName
    )

    if ($null -eq (Get-TargetResource @PSBoundParameters)) {
        Write-Verbose "Creating a new managed account"
        Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            New-SPManagedAccount -Credential $params.Account
        }
    }

    Write-Verbose -Message "Updating settings for managed account"
    Invoke-xSharePointCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]
        
        $updateParams = @{ 
            Identity = $params.Account.UserName 
        }
        if ($params.ContainsKey("EmailNotification")) { $updateParams.Add("EmailNotification", $params.EmailNotification) }
        if ($params.ContainsKey("PreExpireDays")) { $updateParams.Add("PreExpireDays", $params.PreExpireDays) }
        if ($params.ContainsKey("Schedule")) { $updateParams.Add("Schedule", $params.Schedule) }

        Set-SPManagedAccount @updateParams
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
    if ($null -eq $CurrentValues) { return $false }
    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("AccountName", "Schedule","PreExpireDays","EmailNotification") 
}


Export-ModuleMember -Function *-TargetResource

