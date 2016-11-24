function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  
        [System.String] 
        $FileType,
        
        [parameter(Mandatory = $true)]  
        [System.String] 
        $ServiceAppName,
        
        [parameter(Mandatory = $false)] 
        [System.String] 
        $Description,

        [parameter(Mandatory = $false)]  
        [System.String] 
        $MimeType,
        
        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $Enabled,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Getting Search File Type '$FileType'"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $serviceApps = Get-SPServiceApplication -Name $params.ServiceAppName `
                                                -ErrorAction SilentlyContinue
        
        $nullReturn = @{
            FileType = $params.FileType
            ServiceAppName = $params.ServiceAppName
            Ensure = "Absent"
            InstallAccount = $params.InstallAccount
        }
         
        if ($null -eq $serviceApps) 
        {
            Write-Verbose -Message "Service Application $($params.ServiceAppName) not found"
            return $nullReturn 
        }
        
        $serviceApp = $serviceApps | Where-Object -FilterScript { 
            $_.GetType().FullName -eq "Microsoft.Office.Server.Search.Administration.SearchServiceApplication" 
        }

        if ($null -eq $serviceApp) 
        { 
            Write-Verbose -Message "Service Application $($params.ServiceAppName) not found"
            return $nullReturn
        } 
        else 
        {
            $fileType = Get-SPEnterpriseSearchFileFormat `
                          -SearchApplication $params.ServiceAppName | Where-Object -FilterScript { 
                              $_.Identity -eq $params.FileType
                          }

            if ($null -eq $fileType) 
            {
                Write-Verbose -Message "File Type $($params.FileType) not found"
                return $nullReturn
            } 
            else 
            {
                $returnVal = @{
                    FileType = $params.FileType
                    ServiceAppName = $params.ServiceAppName
                    Description = $fileType.Name
                    MimeType = $fileType.MimeType
                    Enabled = $fileType.Enabled
                    Ensure = "Present"
                    InstallAccount = $params.InstallAccount
                } 

                return $returnVal
            }
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
        $FileType,
        
        [parameter(Mandatory = $true)]  
        [System.String] 
        $ServiceAppName,
        
        [parameter(Mandatory = $false)] 
        [System.String] 
        $Description,
        
        [parameter(Mandatory = $false)]  
        [System.String] 
        $MimeType,
        
        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $Enabled,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Setting Search File Type '$FileType'"
    
    $result = Get-TargetResource @PSBoundParameters

    if ($result.Ensure -eq "Absent" -and $Ensure -eq "Present") 
    {
        Write-Verbose -Message "Creating File Type $FileType"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            $newParams = @{
                FormatId = $params.FileType
                SearchApplication = $params.ServiceAppName
            }
            if ($params.ContainsKey("Description") -eq $true) 
            {
                $newParams.Add("FormatName", $params.Description) 
            }
            if ($params.ContainsKey("MimeType") -eq $true) 
            {
                $newParams.Add("MimeType", $params.MimeType) 
            }
            
            New-SPEnterpriseSearchFileFormat @newParams

            if ($params.ContainsKey("Enabled") -eq $true) 
            {
                $stateParams = @{
                    Identity = $params.FileType
                    SearchApplication = $params.ServiceAppName
                    Enable = $params.Enabled
                }
                Set-SPEnterpriseSearchFileFormatState @stateParams
            }
        }
    }

    if ($result.Ensure -eq "Present" -and $Ensure -eq "Present") 
    {
        Write-Verbose -Message "Updating File Type $FileType"
        Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
            
            $fileType = Get-SPEnterpriseSearchFileFormat `
                          -SearchApplication $params.ServiceAppName | Where-Object -FilterScript { 
                              $_.Identity -eq $params.FileType
                          }

            if ($null -ne $fileType) 
            {
                if (($fileType.MimeType -ne $params.MimeType) -or
                    ($fileType.Name -ne $params.Description))
                {
                    Remove-SPEnterpriseSearchFileFormat -Identity $params.FileType `
                                                        -SearchApplication $params.ServiceAppName `
                                                        -Confirm:$false

                    $newParams = @{
                        FormatId = $params.FileType
                        SearchApplication = $params.ServiceAppName
                    }
                    if ($params.ContainsKey("Description") -eq $true) 
                    { 
                        $newParams.Add("FormatName", $params.Description) 
                    }
                    if ($params.ContainsKey("MimeType") -eq $true) 
                    { 
                        $newParams.Add("MimeType", $params.MimeType) 
                    }
                    
                    New-SPEnterpriseSearchFileFormat @newParams
                }

                if ($params.ContainsKey("Enabled") -eq $true)
                {
                    if ($fileType.Enabled -ne $params.Enabled)
                    {
                        $stateParams = @{
                            Identity = $params.FileType
                            SearchApplication = $params.ServiceAppName
                            Enable            = $params.Enabled
                        }

                        Set-SPEnterpriseSearchFileFormatState @stateParams
                    }
                }
            }
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message "Removing Crawl Rule $Path"
        Invoke-SPDSCCommand -Credential $InstallAccount `
                            -Arguments $PSBoundParameters `
                            -ScriptBlock {
            $params = $args[0]
            
            Remove-SPEnterpriseSearchFileFormat -Identity $params.FileType `
                                                -SearchApplication $params.ServiceAppName `
                                                -Confirm:$false
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
        $FileType,
        
        [parameter(Mandatory = $true)]  
        [System.String] 
        $ServiceAppName,
        
        [parameter(Mandatory = $false)] 
        [System.String] 
        $Description,
        
        [parameter(Mandatory = $false)]  
        [System.String] 
        $MimeType,
        
        [parameter(Mandatory = $true)]  
        [System.Boolean] 
        $Enabled,
        
        [parameter(Mandatory = $false)] 
        [ValidateSet("Present","Absent")] 
        [System.String] 
        $Ensure = "Present",
        
        [parameter(Mandatory = $false)] 
        [System.Management.Automation.PSCredential] 
        $InstallAccount
    )

    Write-Verbose -Message "Testing Search File Type '$FileType'"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters
        
    if ($Ensure -eq "Present") 
    {
        if ($PSBoundParameters.ContainsKey("Enabled") -eq $true) 
        {
            if ($Enabled -ne $CurrentValues.Enabled)
            {
                return $false
            }
        }

        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure", 
                                                         "Description", 
                                                         "MimeType")    
    }
    else
    {
        return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                        -DesiredValues $PSBoundParameters `
                                        -ValuesToCheck @("Ensure")
    }
}

Export-ModuleMember -Function *-TargetResource
