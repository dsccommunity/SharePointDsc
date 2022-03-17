function Get-TargetResource
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
        [ValidateSet("Boolean", "String", "Int32")]
        [System.String]
        $ParameterType = 'String',

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Getting SPFarm property '$Key'"

    if ($ParameterType -eq 'Boolean' -and $Value -notin @('True', 'False'))
    {
        $message = ("Value can only be True or False when ParameterType is Boolean. Current value: $Value")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $int = 0
    if ($ParameterType -eq 'Int32' -and [Int32]::TryParse($Value, [ref]$int) -eq $false)
    {
        $message = ("Value has to be a number when ParameterType is Int32. Current value: $Value")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        try
        {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue -Verbose:$false
        }
        catch
        {
            Write-Verbose -Message ('No local SharePoint farm was detected.')
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
                    $value = $spFarm.Properties[$params.Key]
                    switch ($value.GetType().Name)
                    {
                        'Boolean'
                        {
                            $currentType = 'Boolean'
                            if ($value)
                            {
                                $currentValue = 'true'
                            }
                            else
                            {
                                $currentValue = 'false'
                            }
                        }
                        'String'
                        {
                            $currentType = 'String'
                            $currentValue = $spFarm.Properties[$params.Key]
                        }
                        'Int32'
                        {
                            $currentType = 'Int32'
                            $currentValue = $spFarm.Properties[$params.Key].ToString()
                        }
                    }
                }
                else
                {
                    $currentValue = $null
                    $currentType = ""
                    $localEnsure = "Absent"
                }
            }
        }
        else
        {
            $currentValue = $null
            $currentType = ""
            $localEnsure = 'Absent'
        }

        return @{
            Key           = $params.Key
            Value         = $currentValue
            ParameterType = $currentType
            Ensure        = $localEnsure
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
        [ValidateSet("Boolean", "String", "Int32")]
        [System.String]
        $ParameterType = 'String',

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Setting SPFarm property '$Key'"

    if ($ParameterType -eq 'Boolean' -and $Value -notin @('True', 'False'))
    {
        $message = ("Value can only be True or False when ParameterType is Boolean. Current value: $Value")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    $int = 0
    if ($ParameterType -eq 'Int32' -and [Int32]::TryParse($Value, [ref]$int) -eq $false)
    {
        $message = ("Value has to be a number when ParameterType is Int32. Current value: $Value")
        Add-SPDscEvent -Message $message `
            -EntryType 'Error' `
            -EventID 100 `
            -Source $MyInvocation.MyCommand.Source
        throw $message
    }

    Invoke-SPDscCommand -Arguments @($PSBoundParameters, $MyInvocation.MyCommand.Source) `
        -ScriptBlock {
        $params = $args[0]
        $eventSource = $args[1]

        try
        {
            $spFarm = Get-SPFarm -ErrorAction SilentlyContinue -Verbose:$false
        }
        catch
        {
            $message = 'No local SharePoint farm was detected.'
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
                switch ($params.ParameterType)
                {
                    'Boolean'
                    {
                        $spFarm.Properties[$params.Key] = [System.Convert]::ToBoolean($params.Value)
                    }
                    'String'
                    {
                        $spFarm.Properties[$params.Key] = $params.Value
                    }
                    'Int32'
                    {
                        $spFarm.Properties[$params.Key] = [Int32]::Parse($params.Value)
                    }
                }
                $spFarm.Update()
            }
            else
            {
                Write-Warning -Message 'Ensure = Present, parameter Value cannot be null'
            }
        }
        else
        {
            Write-Verbose -Message "Removing property '$($params.Key)' from SPFarm.properties"

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
        [ValidateSet("Boolean", "String", "Int32")]
        [System.String]
        $ParameterType = 'String',

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message "Testing SPFarm property '$Key'"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @('Ensure', 'Key', 'Value', 'ParameterType')

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

function Export-TargetResource
{
    $VerbosePreference = "SilentlyContinue"
    $ParentModuleBase = Get-Module "SharePointDsc" -ListAvailable | Select-Object -ExpandProperty Modulebase
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
