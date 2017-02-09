function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] 
        [Microsoft.Management.Infrastructure.CimInstance[]] 
        $LogLevels,

        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )


    foreach ($LogLevelItem in $LogLevels)
        {
        if ((($LogLevelItem.Category) | Measure-Object).Count -ne 1 -or ($LogLevelItem.Category).contains(",") ) 
        {
            Write-Verbose -Message "Exactly one log category, or the wildcard character '*' must be provided for each log item"
            return $null
        }

        if ((($LogLevelItem.SubCategory) | Measure-Object).Count -ne 1 -or ($LogLevelItem.SubCategory).contains(",") ) 
        {
            Write-Verbose -Message "Exactly one log subcategory, or the wildcard character '*' must be provided for each log item"
            return $null
        }

    }

    Write-Verbose "Getting SP Log Level Settings for $($LogLevels.Category) : $($LogLevels.SubCategory)"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                                    
            $params = $args[0]              

            $LogLevelSettings = @()
            foreach ($LogLevelItem in $params.SPLogLevelSetting)
            {
                Write-Verbose "Getting SP Log Level Settings for $($LogLevelItem.Category) : $($LogLevelItem.SubCategory)"

                $CategoryString = "$($LogLevelItem.Category):$($LogLevelItem.SubCategory)"
                $MyCategories = Get-SPLogLevel -Identity $CategoryString

                if ($null -eq $MyCategories) {
                    Write-Verbose "No matching log categories matching $CategoryString found"
                    return $null 
                }

                #TraceLevels
                #if we desire defaults, we will check for default and return as such
                if (($LogLevelItem.TraceLevel -eq "Default") -and ($null -eq (Compare-Object $MyCategories.traceseverity $MyCategories.defaulttraceseverity)))
                {
                    $TraceLevel = "Default"
                }
                else 
                {
                    $Tracelevel = [System.String]::Join(",",(($MyCategories.traceseverity) | Select-Object -Unique))  
                }

                #EventLevels
                #if we desire defaults, we will check for default and return as such
                if (($LogLevelItem.EventLevel -eq "Default") -and ($null -eq (Compare-Object $MyCategories.eventseverity $MyCategories.defaulteventseverity)))
                {
                    $EventLevel = "Default"
                }
                else 
                {
                    $Eventlevel = [System.String]::Join(",",(($MyCategories.eventseverity) | Select-Object -Unique))  
                }   
                
                $LogLevelSetting = @{
                    Category = $LogLevelItem.Category
                    SubCategory = $LogLevelItem.SubCategory
                    TraceLevel = $TraceLevel
                    EventLevel = $EventLevel 
                }

                $LogLevelSettings += $LogLevelSetting
            }
            
            return @{
                SPLogLevelSetting = $LogLevelSettings
                InstallAccount = $params.InstallAccount
            } 
        }
                            
    return $result                     
                    
                
            
}


