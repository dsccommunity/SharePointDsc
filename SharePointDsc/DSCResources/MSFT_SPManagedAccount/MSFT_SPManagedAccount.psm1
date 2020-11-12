$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Account,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.UInt32]
        $EmailNotification,

        [Parameter()]
        [System.UInt32]
        $PreExpireDays,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    Write-Verbose -Message "Getting managed account $AccountName"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $ma = Get-SPManagedAccount -Identity $params.AccountName `
            -ErrorAction SilentlyContinue
        if ($null -eq $ma)
        {
            return @{
                AccountName = $params.AccountName
                Account     = $params.Account
                Ensure      = "Absent"
            }
        }
        $schedule = $null
        if ($null -ne $ma.ChangeSchedule)
        {
            $schedule = $ma.ChangeSchedule.ToString()
        }
        return @{
            AccountName       = $ma.Username
            EmailNotification = $ma.DaysBeforeChangeToEmail
            PreExpireDays     = $ma.DaysBeforeExpiryToChange
            Schedule          = $schedule
            Account           = $params.Account
            Ensure            = "Present"
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Account,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.UInt32]
        $EmailNotification,

        [Parameter()]
        [System.UInt32]
        $PreExpireDays,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    Write-Verbose -Message "Setting managed account $AccountName"

    if ($Ensure -eq "Present" -and $null -eq $Account)
    {
        $message = ("You must specify the 'Account' property as a PSCredential to create a " + `
                "managed account")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $currentValues = Get-TargetResource @PSBoundParameters
    if ($currentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message ("Managed account does not exist but should, creating " + `
                "the managed account")
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            New-SPManagedAccount -Credential $params.Account
        }
    }

    if ($Ensure -eq "Present")
    {
        Write-Verbose -Message "Updating settings for managed account"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]

            $updateParams = @{
                Identity = $params.Account.UserName
            }
            if ($params.ContainsKey("EmailNotification"))
            {
                $updateParams.Add("EmailNotification", $params.EmailNotification)
            }
            if ($params.ContainsKey("PreExpireDays"))
            {
                $updateParams.Add("PreExpireDays", $params.PreExpireDays)
            }
            if ($params.ContainsKey("Schedule"))
            {
                $updateParams.Add("Schedule", $params.Schedule)
            }
            Set-SPManagedAccount @updateParams
        }
    }
    else
    {
        Write-Verbose -Message "Removing managed account"
        Invoke-SPDscCommand -Credential $InstallAccount `
            -Arguments $PSBoundParameters `
            -ScriptBlock {
            $params = $args[0]
            Remove-SPManagedAccount -Identity $params.AccountName -Confirm:$false
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Account,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount,

        [Parameter()]
        [System.UInt32]
        $EmailNotification,

        [Parameter()]
        [System.UInt32]
        $PreExpireDays,

        [Parameter()]
        [System.String]
        $Schedule,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AccountName
    )

    Write-Verbose -Message "Testing managed account $AccountName"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("AccountName",
        "Schedule",
        "PreExpireDays",
        "EmailNotification",
        "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath "\DSCResources\MSFT_SPManagedAccount\MSFT_SPManagedAccount.psm1" -Resolve
    $managedAccounts = Get-SPManagedAccount

    $i = 1
    $total = $managedAccounts.Length
    foreach ($managedAccount in $managedAccounts)
    {
        try
        {
            $mAccountName = $managedAccount.UserName
            Write-Host "Scanning SPManagedAccount [$i/$total] {$mAccountName}"

            $PartialContent = "        SPManagedAccount " + [System.Guid]::NewGuid().toString() + "`r`n"
            $PartialContent += "        {`r`n"
            <# WA - 1.6.0.0 has a bug where the Get-TargetResource returns an array of all ManagedAccount (see Issue #533) #>
            $schedule = $null
            if ($null -ne $managedAccount.ChangeSchedule)
            {
                $schedule = $managedAccount.ChangeSchedule.ToString()
            }
            $results = @{
                AccountName       = $managedAccount.UserName
                EmailNotification = $managedAccount.DaysBeforeChangeToEmail
                PreExpireDays     = $managedAccount.DaysBeforeExpiryToChange
                Schedule          = $schedule
                Ensure            = "Present"
                Account           = (Resolve-Credentials -UserName $managedAccount.UserName)
            }

            $results = Repair-Credentials -results $results

            $accountName = Get-Credentials -UserName $managedAccount.UserName
            if (!$accountName)
            {
                Save-Credentials -UserName $managedAccount.UserName
            }
            $results.AccountName = $results["Account"] + ".UserName"

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "Account"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "AccountName"
            $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
            $PartialContent += $currentBlock
            $PartialContent += "        }`r`n"
            $i++
        }
        catch
        {
            $Global:ErrorLog += "[Managed Account]" + $managedAccount.UserName + "`r`n"
            $Global:ErrorLog += "$_`r`n`r`n"
        }
        $Content += $PartialContent
    }
    return $Content
}

Export-ModuleMember -Function *-TargetResource
