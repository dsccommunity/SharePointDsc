function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $LiteralPath,
        [parameter(Mandatory = $false)] [String[]] $WebApplications = @(),
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $Version = "1.0.0.0",
        [parameter(Mandatory = $false)] [Boolean]  $Deployed = $true,
        [parameter(Mandatory = $false)] [ValidateSet("14","15","All")]  
                                        [String]   $SolutionLevel,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting farm solution '$Name'..."

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
        $params = $args[0]

        $solution = Get-SPSolution -Identity $params.Name -ErrorAction SilentlyContinue -Verbose:$false

        if ($null -ne $solution) { 
            $currentState = "Present" 
            $deployed = $solution.Deployed
            $version = $Solution.Properties["Version"]
            $deployedWebApplications = @($solution.DeployedWebApplications | Select-Object -ExpandProperty Url)
            $ContainsGlobalAssembly = $solution.ContainsGlobalAssembly
        } else { 
            $currentState = "Absent" 
            $deployed = $false
            $version = "0.0.0.0"
            $deployedWebApplications = @()
            $ContainsGlobalAssembly = $false
        }

        return @{
            Name            = $params.Name
            LiteralPath     = $LiteralPath
            Deployed        = $deployed
            Ensure          = $currentState
            Version         = $version
            WebApplications = $deployedWebApplications
            SolutionLevel   = $params.SolutionLevel
            ContainsGlobalAssembly = $ContainsGlobalAssembly
        }
    }

    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $LiteralPath,
        [parameter(Mandatory = $false)] [String[]] $WebApplications = @(),
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $Version = "1.0.0.0",
        [parameter(Mandatory = $false)] [Boolean]  $Deployed = $true,
        [parameter(Mandatory = $false)] [ValidateSet("14","15","All")]  
                                        [String]   $SolutionLevel,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters

    $PSBoundParameters.Ensure = $Ensure
    $PSBoundParameters.Version = $Version
    $PSBoundParameters.Deployed = $Deployed
    $PSBoundParameters.ContainsGlobalAssembly = $CurrentValues.ContainsGlobalAssembly

    if ($Ensure -eq "Present") 
    {
        if ($CurrentValues.Ensure -eq "Absent")
        {
            Write-Verbose "Upload solution to the farm."

            $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                $runParams = @{}
                $runParams.Add("LiteralPath", $params.LiteralPath)
                $runParams.Add("Verbose", $false)

                $solution = Add-SPSolution @runParams

                $solution.Properties["Version"] = $params.Version 
                $solution.Update()

                return $solution
            }

            $CurrentValues.Version = $result.Properties["Version"]
            $CurrentValues.ContainsGlobalAssembly = $result.ContainsGlobalAssembly
        }
    
        if ($CurrentValues.Version -ne $Version)
        {
            # If the solution is not deployed and the versions do not match we have to remove the current solution and add the new one
            if (-not $CurrentValues.Deployed)
            {
                Write-Verbose "Remove current version ('$($CurrentValues.Version)') of solution..."

                $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                    $params = $args[0]
        
                    $runParams = @{}
                    $runParams.Add("Identity", $params.Name)
                    $runParams.Add("Confirm", $false) 
                    $runParams.Add("Verbose", $false)

                    Remove-SPSolution $runParams

                    $runParams = @{}
                    $runParams.Add("LiteralPath", $params.LiteralPath)

                    $solution = Add-SPSolution @runParams

                    $solution.Properties["Version"] = $params.Version 
                    $solution.Update()

                    return $solution
                }

                $CurrentValues.Version = $result.Properties["Version"]
                $CurrentValues.ContainsGlobalAssembly = $result.ContainsGlobalAssembly
            }
            else
            {
                Write-Verbose "Update solution from '$($CurrentValues.Version)' to $Version..."

                $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                    $params = $args[0]
        
                    $runParams = @{}
                    $runParams.Add("Identity", $params.Name)
                    $runParams.Add("LiteralPath", $params.LiteralPath)
                    $runParams.Add("GACDeployment", $params.ContainsGlobalAssembly)
                    $runParams.Add("Confirm", $false) 
                    $runParams.Add("Local", $false) 
                    $runParams.Add("Verbose", $false)

                    Update-SPSolution @runParams

                    $Solution = Get-SPSolution $params.Name -Verbose:$false
                    $solution.Properties["Version"] = $params.Version 
                    $solution.Update()

                    # Install new features...
                    Install-SPFeature -AllExistingFeatures -Confirm:$false
                }
            }
        }

    }
    else
    {
        #If ensure is absent we should also retract the solution first
        $Deployed = $false 
    }

    if ($Deployed -ne $CurrentValues.Deployed) 
    { 
        Write-Verbose "The deploy state of $Name is '$($CurrentValues.Deployed)' but should be '$Deployed'." 
        if ($CurrentValues.Deployed) 
        { 
            # Retract Solution globally 
            $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
        
                $runParams = @{}
                $runParams.Add("Identity", $params.Name)
                $runParams.Add("Confirm", $false)
                $runParams.Add("Verbose", $false)

                if ($solution.ContainsWebApplicationResource) 
                {
                    if ($null -eq $webApps -or $webApps.Length -eq 0) 
                    {
                        $runParams.Add("AllWebApplications", $true)

                        Uninstall-SPSolution @runParams
                    }
                    else
                    {
                        foreach ($webApp in $webApps)
                        {
                            $runParams["WebApplication"] = $webApp

                            Uninstall-SPSolution @runParams
                        }
                    }
                }
                else 
                {
                    Uninstall-SPSolution @runParams
                }
            }
        } 
        else 
        { 
            # Deploy solution 
            $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
                $params = $args[0]
       
                $solution = Get-SPSolution -Identity $params.Name -Verbose:$false

                $runParams = @{ 
                    Identity = $solution
                    GACDeployment = $solution.ContainsGlobalAssembly
                    Local = $false
                    Verbose = $false
                }
                if ($params.ContainsKey("SolutionLevel") -eq $true) 
                {
                    $runParams.Add("CompatibilityLevel", $params.SolutionLevel)
                }

                if (!$solution.ContainsWebApplicationResource) 
                {
                    Install-SPSolution @runParams
                }
                else
                {
                    if ($null -eq $webApps -or $webApps.Length -eq 0) 
                    {
                        $runParams.Add("AllWebApplications", $true)

                        Install-SPSolution @runParams
                    }
                    else
                    {
                        foreach ($webApp in $webApps)
                        {
                            $runParams["WebApplication"] = $webApp 

                            Install-SPSolution @runParams
                        }
                    }
                }

            }
        }
       
     } 

     Wait-SPDSCSolutionJob -SolutionName $Name -InstallAccount $InstallAccount

    if ($Ensure -eq "Absent")
    {
        $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $PSBoundParameters -ScriptBlock {
            $params = $args[0]
        
            $runParams = @{ 
                Identity = $params.Name
                Confirm = $false
                Verbose = $false
            }

            Remove-SPSolution @runParams

        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]  [String]   $Name,
        [parameter(Mandatory = $true)]  [String]   $LiteralPath,
        [parameter(Mandatory = $false)] [String[]] $WebApplications = @(),
        [parameter(Mandatory = $false)] [ValidateSet("Present","Absent")] 
                                        [String]   $Ensure = "Present",
        [parameter(Mandatory = $false)] [String]   $Version = "1.0.0.0",
        [parameter(Mandatory = $false)] [Boolean]  $Deployed = $true,
        [parameter(Mandatory = $false)] [ValidateSet("14","15","All")]  
                                        [String]   $SolutionLevel,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Testing solution $Name"

    $PSBoundParameters.Ensure = $Ensure

    if ($WebApplications.Count -gt 0){
        $valuesToCheck = @("Ensure", "Version", "Deployed", "WebApplications")
    }else{
        $valuesToCheck = @("Ensure", "Version", "Deployed")
    }

    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck $valuesToCheck
}

function Wait-SPDSCSolutionJob
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]  [string]$SolutionName,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $InstallAccount
    )

    start-sleep -s 5

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments @{ Name = $SolutionName } -ScriptBlock {
        $params = $args[0]

        $gc = Start-SPAssignment -Verbose:$false
    
        $solution = Get-SPSolution -Identity $params.Name -Verbose:$false -AssignmentCollection $gc

        if ($solution.JobExists){
            Write-Verbose "Waiting for solution '$($params.Name)'..."

            while ($solution.JobExists){
                Write-Verbose "$([DateTime]::Now.ToShortTimeString()) - Waiting for a job for solution '$($params.Name)' to complete"
                start-sleep -s 5
            }

            Write-Verbose "Result: $($solution.LastOperationResult)"
            Write-Verbose "Details: $($solution.LastOperationDetails)"

        }else{ 
            Write-Verbose "Solution '$($params.Name)' has no job pending."
            return @{ 
                LastOperationResult = "DeploymentSucceeded"
                LastOperationDetails = "Solution '$($params.Name)' has no job pending."
            }
        }

        Stop-SPAssignment $gc -Verbose:$false

        return @{ 
            LastOperationResult = $solution.LastOperationResult
            LastOperationDetails = $solution.LastOperationDetails
        }
    }
}

Export-ModuleMember -Function *-TargetResource
