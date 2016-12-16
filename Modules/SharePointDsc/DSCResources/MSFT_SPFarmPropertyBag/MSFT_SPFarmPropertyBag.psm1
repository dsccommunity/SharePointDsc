function Get-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Collections.HashTable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Value,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Looking for SPFarm property '$Name'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        try 
        {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
        } 
        catch 
        {
            Write-Verbose -Message ("No local SharePoint farm was detected.")
            return @{
                Key = $params.Key
                Value = $null
                Ensure = 'Absent'
            }
        }

        if ($null -ne $spFarm)
        {
            if ($spFarm.Properties)
            {            
                if ($spFarm.Properties.Contains($params.Key))
                {
                    $currentValue = $spFarm.Properties[$params.Key]

                    if ($currentValue -eq $params.Value)
                    {
                        $localEnsure = 'Present'
                    }
                    else 
                    {
                        $localEnsure = 'Absent'
                    }
                }
                else
                {
                    $localEnsure = 'Absent'
                }
            }
        }
        else
        {
            $null = $currentValue
            $localEnsure = 'Absent'
        }

        return @{
            Key = $params.Key
            Value = $currentValue
            Ensure = $localEnsure
        }
    }
    return $result    
}

function Set-TargetResource()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Value,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPFarm property '$Name'"

    Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
        $params = $args[0]

        try 
        {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
        } 
        catch 
        {
            throw "No local SharePoint farm was detected."
            return
        }

        if ($params.Ensure -eq 'Present')
        {
            if ($params.Value)
            {
                Write-Verbose -Message "Adding property '$params.Key'='$params.value' to SPFarm.properties"
                $spFarm.Properties[$params.Key] = $params.Value
                $spFarm.Update()
            }
            else
            {
                Write-Warning -Message 'Ensure = Present, value parameter cannot be null'
            }  
        }
        else
        {
            Write-Verbose -Message "Removing property '$params.Key' from SPFarm.properties"

            $spFarm.Properties.Remove($params.Key)
            $spFarm.Update()
        }
    }
}

function Test-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Value,

        [Parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = 'Present',

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @('Ensure','Key','Value')
}

Export-ModuleMember -Function *-TargetResource
