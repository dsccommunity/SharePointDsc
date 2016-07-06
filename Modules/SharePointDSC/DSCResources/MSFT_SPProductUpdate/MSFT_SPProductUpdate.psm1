function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SetupFile,
        
        [parameter(Mandatory = $false)]
        [System.Boolean] $ShutdownServices,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]] $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String] $BinaryInstallTime,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $InstallAccount
    )

    Write-Verbose -Message "Getting install status of SP binaries"

#### CHECKEN VOOR INSTALLATIE UPDATE MAAR NOG NIET CONFIG WIZARD, ANDERS BLIJFT HIJ IN EEN LOOP

    $languagepack = $false
    $servicepack  = $false
    $language     = ""

    # Get file information from setup file
    if (-not(Test-Path $SetupFile))
    {
        throw "Setup file cannot be found."
    }
    $setupFileInfo = Get-ItemProperty $SetupFile
    $fileVersion = $setupFileInfo.VersionInfo.FileVersion
    Write-Verbose "Update has version $fileVersion"

    $products = Invoke-SPDSCCommand -Credential $InstallAccount -ScriptBlock {
        $farm = Get-SPFarm
        $productVersions = [Microsoft.SharePoint.Administration.SPProductVersions]::GetProductVersions($farm)
        $server = Get-SPServer $env:COMPUTERNAME

        $serverProductInfo = $productVersions.GetServerProductInfo($server.id)
        return $serverProductInfo.Products
    }

    if ($setupFileInfo.VersionInfo.FileDescription -match "Language Pack")
    {
        Write-Verbose "Update is a Language Pack Service Pack."
        # Retrieve language from file and check version for that language pack.
        $languagepack = $true

        # Extract language from filename
        if ($setupFileInfo.Name -match "\w*-(\w{2}-\w{2}).exe")
        {
            $language = $matches[1]
        }
        else
        {
            throw "Update does not contain the language code in the correct format."
        }

        try
        {
            $cultureInfo = New-Object system.globalization.cultureinfo($language)
        }
        catch
        {
            throw "Error while converting language information: $language"
        }

        # Extract English name of the language code
        if ($cultureInfo.EnglishName -match "(\w*) \(\w*\)")
        {
            $languageEnglish = $matches[1]
        }

        # Extract Native name of the language code
        if ($cultureInfo.NativeName -match "(\w*) \(\w*\)")
        {
            $languageNative = $matches[1]
        }

        # Build language string used in Language Pack names
        $languageString = "$languageEnglish/$languageNative"
        Write-Verbose "Update is for the $languageEnglish language"

        # Find the product name for the specific language pack
        $productName = ""
        foreach ($product in $products)
        {
            if ($product -match $languageString)
            {
                $productName = $product
            }
        }

        if ($productName -eq "")
        {
            throw "Error: Product for language $language is not found."
        }
        else
        {
            Write-Verbose "Product found: $productName"
        }
        $versionInfo = Get-SPFarmVersionInfo $productName
    }
    elseif ($setupFileInfo.VersionInfo.FileDescription -match "Service Pack")
    {
        Write-Verbose "Update is a Service Pack for SharePoint."
        # Check SharePoint version information.
        $servicepack = $true
        $versionInfo = Get-SPFarmVersionInfo "Microsoft SharePoint Server 2013"
    }
    else
    {
        Write-Verbose "Update is a Cumulative Update."
        # Cumulative Update is multi-lingual. Check version information of all products.
        $versionInfo = Get-SPFarmVersionInfo
    }

    Write-Verbose "The lowest version of any SharePoint component is $($versionInfo.Lowest)"
    if ($versionInfo.Lowest -lt $fileVersion)
    {
        # Version of SharePoint is lower than the patch version. Patch is not installed.
        return @{
            SetupFile         = $SetupFile
            ShutdownServices  = $ShutdownServices
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Absent"
        }
    }
    else
    {
        # Version of SharePoint is equal or greater than the patch version. Patch is installed.
        return @{
            SetupFile         = $SetupFile
            ShutdownServices  = $ShutdownServices
            BinaryInstallDays = $BinaryInstallDays
            BinaryInstallTime = $BinaryInstallTime
            Ensure            = "Present"
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SetupFile,
        
        [parameter(Mandatory = $false)]
        [System.Boolean] $ShutdownServices,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]] $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String] $BinaryInstallTime,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Ensure -eq "Absent") {
        throw [Exception] "SharePoint does not support uninstalling updates."
        return
    }
    
    if ($ShutdownServices)
    {
        Write-Verbose "Stopping services to speed up installation process"

        $searchPaused = $false
        $osearchStopped = $false
        $hostControllerStopped = $false

        $osearchSvc        = Get-Service "OSearch15" 
        $hostControllerSvc = Get-Service "SPSearchHostController" 

        $searchPaused = $true
        $searchSAs = Get-SPEnterpriseSearchServiceApplication
        foreach ($searchSA in $searchSAs)
        {
            $searchSA.Pause()
        }

        if($osearchSvc.Status -eq "Running") 
        { 
            $osearchStopped = $true
            Set-Service -Name "OSearch15" -StartupType Disabled
            $osearchSvc.Stop() 
        } 

        if($hostControllerSvc.Status -eq "Running") 
        {
            $hostControllerStopped = $true
            Set-Service "SPSearchHostController" -StartupType Disabled 
            $hostControllerSvc.Stop() 
        } 

        $hostControllerSvc.WaitForStatus('Stopped','00:01:00')

        Write-Verbose "Search Services are stopped"

        Write-Verbose "Stopping other services"

        Set-Service -Name "IISADMIN" -StartupType Disabled
        Set-Service -Name "SPTimerV4" -StartupType Disabled

        iisreset -stop -noforce 

        $timerSvc = Get-Service "SPTimerV4"
        if($timerSvc.Status -eq "Running")
        {
            $timerSvc.Stop()
        }
    }

    Write-Verbose -Message "Beginning installation of the SharePoint update"
    
    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $$SetupFile -ScriptBlock {
        $setupFile = $args[0]

        $setup = Start-Process -FilePath $setupFile -ArgumentList "/quiet /passive" -Wait -PassThru

        switch ($setup.ExitCode) {
            0 {  
                Write-Verbose -Message "SharePoint update binary installation complete"
            }
            Default {
                throw "SharePoint update install failed, exit code was $($setup.ExitCode)"
            }
        }
    }

    if ($ShutdownServices)
    {
        Write-Verbose "Restart stopped services"
        Set-Service -Name "SPTimerV4" -StartupType Automatic 
        Set-Service -Name "IISADMIN" -StartupType Automatic 

        $timerSvc = Get-Service "SPTimerV4"
        $timerSvc.Start()

        iisreset -start

        $osearchSvc        = Get-Service "OSearch15" 
        $hostControllerSvc = Get-Service "SPSearchHostController" 

        ###Ensuring Search Services were stopped by script before Starting" 
        if($osearchStopped -eq $true) 
        {
            Set-Service -Name "OSearch15" -StartupType Automatic
            $osearchSvc.Start()
        }

        if($hostControllerStopped -eq $true)
        { 
            Set-Service "SPSearchHostController" -StartupType Automatic 
            $hostControllerSvc.Start() 
        } 

        ###Resuming Search Service Application if paused### 
        if($searchPaused -eq $true)
        {
            $searchSAs = Get-SPEnterpriseSearchServiceApplication
            foreach ($searchSA in $searchSAs)
            {
                $searchSA.Resume()
            }
        }

        Write-Verbose "Services restarted."
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SetupFile,
        
        [parameter(Mandatory = $false)]
        [System.Boolean] $ShutdownServices,

        [parameter(Mandatory = $false)]
        [ValidateSet("mon","tue","wed","thu","fri","sat","sun")]
        [System.String[]] $BinaryInstallDays,
        
        [parameter(Mandatory = $false)]
        [System.String] $BinaryInstallTime,
        
        [parameter(Mandatory = $false)]
        [ValidateSet("Present","Absent")]
        [System.String] $Ensure = "Present",
        
        [parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential] $InstallAccount
    )

    if ($Ensure -eq "Absent") {
        throw [Exception] "SharePoint does not support uninstalling updates."
        return
    }

    $PSBoundParameters.Ensure = $Ensure
    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Testing for installation of the SharePoint Update"

    return Test-SPDSCSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource

function Get-SPFarmVersionInfo()
{
    param
    (
        [parameter(Mandatory = $false)]
        [System.String] $ProductToCheck
    )

    $result = Invoke-SPDSCCommand -Credential $InstallAccount -Arguments $ProductToCheck -ScriptBlock {
        $productToCheck = $args[0]

        $farm = Get-SPFarm
        $productVersions = [Microsoft.SharePoint.Administration.SPProductVersions]::GetProductVersions($farm)
        $server = Get-SPServer $env:COMPUTERNAME
        $versionInfo = @{}
        $versionInfo.Highest = ""
        $versionInfo.Lowest = ""

        $serverProductInfo = $productVersions.GetServerProductInfo($server.id)
        $products = $serverProductInfo.Products

        if ($productToCheck)
        {
            $products = $products | Where-Object { $_ -eq $productToCheck }
            if ($null -eq $products)
            {
                throw "Product not found: $productToCheck"
            }
        }

        # Loop through all products
        foreach ($product in $products)
        {
            Write-Output "Product: $product"
            $singleProductInfo = $serverProductInfo.GetSingleProductInfo($product)
            $patchableUnits = $singleProductInfo.PatchableUnitDisplayNames

            # Loop through all individual components within the product
            foreach ($patchableUnit in $patchableUnits)
            {
                # Check if the displayname is the Proofing tools (always mentioned in first product, generates noise)
                if (($patchableUnit -notmatch "Microsoft Server Proof") -and
                    ($patchableUnit -notmatch "SQL Express") -and
                    ($patchableUnit -notmatch "OMUI") -and
                    ($patchableUnit -notmatch "XMUI") -and
                    ($patchableUnit -notmatch "Project Server") -and
                    ($patchableUnit -notmatch "Microsoft SharePoint Server 2013"))
                {
                    Write-Output "  - $patchableUnit"
                    $patchableUnitsInfo = $singleProductInfo.GetPatchableUnitInfoByDisplayName($patchableUnit)
                    $currentVersion = ""
                    foreach ($patchableUnitInfo in $patchableUnitsInfo)
                    {
                        # Loop through version of the patchableUnit
                        $currentVersion = $patchableUnitInfo.LatestPatch.Version.ToString()

                        # Check if the version of the patchableUnit is the highest for the installed product
                        if ($currentVersion -gt $versionInfo.Highest)
                        {
                            $versionInfo.Highest = $currentVersion
                        }

                        if ($versionInfo.Lowest -eq "")
                        {
                            $versionInfo.Lowest = $version
                        }
                        else
                        {
                            if ($version -lt $versionInfo.Lowest) {
                                $versionInfo.Lowest = $version
                            }
                        }
                    }
                }
            }
        }
        return $versionInfo
    }
    return $result
}