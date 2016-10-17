function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting AAG configuration for $DatabaseName"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]
        
        $database = Get-SPDatabase | Where-Object -FilterScript { 
            $_.Name -eq $params.DatabaseName 
        }

        $Ensure = "Absent"
        $AGName = $params.AGName
        if ($null -ne $database) 
        {
            $ag = $database.AvailabilityGroup
            if ($null -ne $ag) 
            {
                $AGName = $ag.Name
                if ($ag.Name -eq $params.AGName) 
                {
                    $Ensure = "Present"
                }
            }
        }

        return @{
            DatabaseName = $params.DatabaseName
            AGName = $AGName
            FileShare = $params.FileShare
            Ensure = $Ensure
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
        [parameter(Mandatory = $true)]  
        [System.String] 
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting AAG configuration for $DatabaseName"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    # Move to a new AG
    if ($CurrentValues.AGName -ne $AGName -and $Ensure -eq "Present") 
    {
        Write-Verbose -Message "Moving $DatabaseName from previous AAG to $AGName"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments ($PSBoundParameters, $CurrentValues) `
                            -ScriptBlock {
            $params = $args[0]
            $CurrentValues = $args[1]
            
            # Remove it from the current AAG first
            Remove-DatabaseFromAvailabilityGroup -AGName $CurrentValues.AGName `
                                                 -DatabaseName $params.DatabaseName `
                                                 -Force

            # Now add it to the AAG it's meant to be in
            $addParams = @{
                AGName = $params.AGName
                DatabaseName = $params.DatabaseName
            }
            if ($params.ContainsKey("FileShare")) 
            {
                $addParams.Add("FileShare", $params.FileShare)
            }
            Add-DatabaseToAvailabilityGroup @addParams
        }
    } 
    else 
    {
        if ($Ensure -eq "Present") 
        {
            # Add to AG
            Write-Verbose -Message "Adding $DatabaseName from $AGName"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]

                $cmdParams = @{
                    AGName = $params.AGName
                    DatabaseName = $params.DatabaseName
                }
                if ($params.ContainsKey("FileShare")) 
                {
                    $cmdParams.Add("FileShare", $params.FileShare)
                }
                Add-DatabaseToAvailabilityGroup @cmdParams
            }
        } 
        else 
        {
            # Remove from the AG
            Write-Verbose -Message "Removing $DatabaseName from $AGName"
            Invoke-SPDSCCommand -Credential $InstallAccount `
                                -Arguments $PSBoundParameters `
                                -ScriptBlock {
                $params = $args[0]
                Remove-DatabaseFromAvailabilityGroup -AGName $params.AGName `
                                                     -DatabaseName $params.DatabaseName `
                                                     -Force
            }
        }
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
        $DatabaseName,

        [parameter(Mandatory = $true)]  
        [System.String] 
        $AGName,

        [parameter(Mandatory = $false)] 
        [System.String] 
        $FileShare,

        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing AAG configuration for $DatabaseName"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters
    
    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure", "AGName")
}

