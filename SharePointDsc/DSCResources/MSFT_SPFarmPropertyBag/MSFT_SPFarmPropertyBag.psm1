$script:resourceModulePath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$script:modulesFolderPath = Join-Path -Path $script:resourceModulePath -ChildPath 'Modules'
$script:resourceHelperModulePath = Join-Path -Path $script:modulesFolderPath -ChildPath 'SharePointDsc.Util'
Import-Module -Name (Join-Path -Path $script:resourceHelperModulePath -ChildPath 'SharePointDsc.Util.psm1')

function Get-TargetResource()
{
    [CmdletBinding()]
    [OutputType([System.Collections.HashTable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Looking for SPFarm property '$Name'"

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
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
                Key    = $params.Key
                Value  = $null
                Ensure = 'Absent'
            }
        }

        if ($null -ne $spFarm)
        {
            if ($spFarm.Properties)
            {
                if ($spFarm.Properties.Contains($params.Key) -eq $true)
                {
                    $localEnsure = "Present"
                    $currentValue = $spFarm.Properties[$params.Key]
                }
                else
                {
                    $localEnsure = "Absent"
                    $currentValue = $null
                }
            }
        }
        else
        {
            $currentValue = $null
            $localEnsure = 'Absent'
        }

        return @{
            Key    = $params.Key
            Value  = $currentValue
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

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting SPFarm property '$Name'"

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue
        }
        catch
        {
            $message = "No local SharePoint farm was detected."
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $eventSource
            throw $message
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

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing SPFarm property '$Name'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Ensure', 'Key', 'Value')

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}


function Export-TargetResource
{
    if (!(Get-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction 0
    }
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDSC" | Select-Object -ExpandProperty Modulebase
    $module = Join-Path -Path $ParentModuleBase -ChildPath  "\DSCResources\MSFT_SPFarmPropertyBag\MSFT_SPFarmPropertyBag.psm1" -Resolve
    $Content = ''
    $params = Get-DSCFakeParameters -ModulePath $module
    $farm = Get-SPFarm
    foreach ($key in $farm.Properties.Keys)
    {
        $params.Key = $key
        $PartialContent = "        SPFarmPropertyBag " + [System.Guid]::NewGuid().ToString() + "`r`n"
        $PartialContent += "        {`r`n"
        $results = Get-TargetResource @params

        $results = Repair-Credentials -results $results
        $currentBlock = ""
        if ($results.Key -eq "SystemAccountName")
        {
            $accountName = Get-Credentials -UserName $results.Value
            if ($accountName)
            {
                $results.Value = (Resolve-Credentials -UserName $results.Value) + ".UserName"
            }

            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
            if ($accountName)
            {
                $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "Value"
            }
        }
        else
        {
            $currentBlock = Get-DSCBlock -Params $results -ModulePath $module
        }
        $currentBlock = Convert-DSCStringParamToVariable -DSCBlock $currentBlock -ParameterName "PsDscRunAsCredential"
        $PartialContent += $currentBlock
        $PartialContent += "        }`r`n"
        $Content += $PartialContent
    }
    return $Content
}


Export-ModuleMember -Function *-TargetResource

