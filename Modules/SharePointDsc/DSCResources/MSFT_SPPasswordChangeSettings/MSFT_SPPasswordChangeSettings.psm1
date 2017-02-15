function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $MailAddress,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,
        
        [parameter(Mandatory = $false)] 
        [ValidateRange(0,99)]
        [System.UInt32]
        $NumberOfRetries,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting farm wide automatic password change settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $farm = Get-SPFarm
        if ($null -eq $farm ) 
        { 
            return $null 
        }
        return @{
            MailAddress = $farm.PasswordChangeEmailAddress
            PasswordChangeWaitTimeSeconds= $farm.PasswordChangeGuardTime
            NumberOfRetries= $farm.PasswordChangeMaximumTries
            DaysBeforeExpiry = $farm.DaysBeforePasswordExpirationToSendEmail 
        }
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $MailAddress,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,
        
        [parameter(Mandatory = $false)] 
        [ValidateRange(0,99)]
        [System.UInt32]
        $NumberOfRetries,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting farm wide automatic password change settings"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]
        $farm = Get-SPFarm -ErrorAction Continue 

        if ($null -eq $farm ) 
        { 
            return $null 
        }
        
        $farm.PasswordChangeEmailAddress = $params.MailAddress
        if ($null -ne $params.PasswordChangeWaitTimeSeconds) 
        {
            $farm.PasswordChangeGuardTime = $params.PasswordChangeWaitTimeSeconds
        }
        if ($null -ne $params.NumberOfRetries) 
        {
            $farm.PasswordChangeMaximumTries = $params.NumberOfRetries
        }
        if ($null -ne $params.DaysBeforeExpiry) 
        {
            $farm.DaysBeforePasswordExpirationToSendEmail = $params.DaysBeforeExpiry
        }
        $farm.Update();
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String]
        $MailAddress,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,356)]
        [System.UInt32]
        $DaysBeforeExpiry,

        [parameter(Mandatory = $false)]
        [ValidateRange(0,36000)]
        [System.UInt32]
        $PasswordChangeWaitTimeSeconds,
        
        [parameter(Mandatory = $false)] 
        [ValidateRange(0,99)]
        [System.UInt32]
        $NumberOfRetries,
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing farm wide automatic password change settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if ($null -eq $CurrentValues)
    {
        return $false
    }
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("MailAddress", 
                                                     "DaysBeforeExpiry",
                                                     "PasswordChangeWaitTimeSeconds",
                                                     "NumberOfRetries") 
}

Export-ModuleMember -Function *-TargetResource
