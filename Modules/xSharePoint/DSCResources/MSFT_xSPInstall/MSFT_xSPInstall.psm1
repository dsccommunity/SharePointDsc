function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir
    )

    Write-Verbose "Getting install status of SP binaries"

    $spInstall = Get-WmiObject -Class Win32_Product | ? {$_.Name -like "Microsoft SharePoint Server*" }
    $result = ($spInstall -ne $null)
    $returnValue = @{
        SharePointInstalled = $result
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [System.String]
        $ProductKey
    )

    Write-Verbose "Writing install config file"

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
</Configuration>" | Out-File $configPath

    Write-Verbose "Begining installation of SharePoint"
    
    $setupExe = Join-Path -Path $BinaryDir -ChildPath "setup.exe"
    
    $process = Start-Process -FilePath $setupExe -ArgumentList "/config `"$configPath`"" -Wait

    Write-Verbose "SharePoint binary installation complete"
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $BinaryDir,

        [System.String]
        $ProductKey
    )

    $result = Get-TargetResource -BinaryDir $BinaryDir
    Write-Verbose "Testing for installation of SharePoint"
    $result.SharePointInstalled
}
Export-ModuleMember -Function *-TargetResource
