function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $BinaryDir,
        [parameter(Mandatory = $true)] [System.String] $ProductKey,
        [parameter(Mandatory = $true)] [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    Write-Verbose -Message "Getting install status of SP binaries"

    $spInstall = Get-CimInstance -ClassName Win32_Product -Filter "Name like 'Microsoft SharePoint Server%'"
    if ($spInstall) {
        return @{
            BinaryDir = $BinaryDir
            ProductKey = $ProductKey
            Ensure = "Present"
        }
    } else {
        return @{
            BinaryDir = $BinaryDir
            ProductKey = $ProductKey
            Ensure = "Absent"
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $BinaryDir,
        [parameter(Mandatory = $true)] [System.String] $ProductKey,
        [parameter(Mandatory = $true)] [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    if ($Ensure -eq "Absent") {
        throw [Exception] "xSharePoint does not support uninstalling SharePoint or its prerequisites. Please remove this manually."
        return
    }
    
    $InstallerPath = Join-Path $BinaryDir "setup.exe"
    $majorVersion = (Get-xSharePointAssemblyVersion -PathToAssembly $InstallerPath)
    if ($majorVersion -eq 15) {
        $dotNet46Check = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?!S)\p{L}' -and $_.Version -like "4.6.*"}
        if ($dotNet46Check -ne $null -and $dotNet46Check.Length -gt 0) {
            throw [Exception] "A known issue prevents installation of SharePoint 2013 on servers that have .NET 4.6 already installed. See details at https://support.microsoft.com/en-us/kb/3087184"
            return
        }    
    }

    Write-Verbose -Message "Writing install config file"

    $configPath = "$env:temp\SPInstallConfig.xml" 

"<Configuration>
    <Package Id=`"sts`">
        <Setting Id=`"LAUNCHEDFROMSETUPSTS`" Value=`"Yes`"/>
    </Package>

    <Package Id=`"spswfe`">
        <Setting Id=`"SETUPCALLED`" Value=`"1`"/>
    </Package>

    <Logging Type=`"verbose`" Path=`"%temp%`" Template=`"SharePoint Server Setup(*).log`"/>
    <PIDKEY Value=`"$ProductKey`" />
    <Display Level=`"none`" CompletionNotice=`"no`" />
    <Setting Id=`"SERVERROLE`" Value=`"APPLICATION`"/>
    <Setting Id=`"USINGUIINSTALLMODE`" Value=`"0`"/>
    <Setting Id=`"SETUP_REBOOT`" Value=`"Never`" />
    <Setting Id=`"SETUPTYPE`" Value=`"CLEAN_INSTALL`"/>
</Configuration>" | Out-File -FilePath $configPath

    Write-Verbose -Message "Beginning installation of SharePoint"
    
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    
    $setup = Start-Process -FilePath $setupExe -ArgumentList "/config `"$configPath`"" -Wait -PassThru

    if ($setup.ExitCode -eq 0) {
        Write-Verbose -Message "SharePoint binary installation complete"
        $global:DSCMachineStatus = 1
    }
    else
    {
        throw "SharePoint install failed, exit code was $($setup.ExitCode)"
    }
    
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)] [System.String] $BinaryDir,
        [parameter(Mandatory = $true)] [System.String] $ProductKey,
        [parameter(Mandatory = $true)] [ValidateSet("Present","Absent")] [System.String] $Ensure
    )

    if ($Ensure -eq "Absent") {
        throw [Exception] "xSharePoint does not support uninstalling SharePoint or its prerequisites. Please remove this manually."
        return
    }

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Testing for installation of SharePoint"

    return Test-xSharePointSpecificParameters -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
