function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.UInt32]
        $DLTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DLTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DLTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DVSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DVSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DVSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DAFMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DAFRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DAFChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DAFCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DAFCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DAFCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DBCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DBCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DBCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DDCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DDCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DDCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSTACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSTACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSTACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DFLTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DFLTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DFLTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSWUCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSWUCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSWUCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUGCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUGCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUGCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DRTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DRTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DRTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DHSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DHSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DHSCChannelOpenTimeOut,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the Distributed Cache Client Settings"

    if ($PSBoundParameters.ContainsKey("DFLTCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DFLTCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DFLTCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSWUCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSWUCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSWUCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DUGCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DUGCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DUGCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DRTCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DRTCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DRTCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DHSCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DHSCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DHSCChannelOpenTimeOut") -eq $true)
    {
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -eq 15)
        {
            throw ("The following parameters are only supported in SharePoint 2016 and above: " + `
                    "DFLTCMaxConnectionsToServer, DFLTCRequestTimeout, DFLTCChannelOpenTimeOut, " + `
                    "DSWUCMaxConnectionsToServer, DSWUCRequestTimeout, DSWUCChannelOpenTimeOut, " + `
                    "DUGCMaxConnectionsToServer, DUGCRequestTimeout, DUGCChannelOpenTimeOut, " + `
                    "DRTCMaxConnectionsToServer, DRTCRequestTimeout, DRTCChannelOpenTimeOut, " + `
                    "DHSCMaxConnectionsToServer, DHSCRequestTimeout and DHSCChannelOpenTimeOut")
        }
    }

    $result = Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturnValue = @{
            IsSingleInstance            = "Yes"
            DLTCMaxConnectionsToServer  = $null
            DLTCRequestTimeout          = $null
            DLTCChannelOpenTimeOut      = $null
            DVSCMaxConnectionsToServer  = $null
            DVSCRequestTimeout          = $null
            DVSCChannelOpenTimeOut      = $null
            DACMaxConnectionsToServer   = $null
            DACRequestTimeout           = $null
            DACChannelOpenTimeOut       = $null
            DAFMaxConnectionsToServer   = $null
            DAFRequestTimeout           = $null
            DAFChannelOpenTimeOut       = $null
            DAFCMaxConnectionsToServer  = $null
            DAFCRequestTimeout          = $null
            DAFCChannelOpenTimeOut      = $null
            DBCMaxConnectionsToServer   = $null
            DBCRequestTimeout           = $null
            DBCChannelOpenTimeOut       = $null
            DDCMaxConnectionsToServer   = $null
            DDCRequestTimeout           = $null
            DDCChannelOpenTimeOut       = $null
            DSCMaxConnectionsToServer   = $null
            DSCRequestTimeout           = $null
            DSCChannelOpenTimeOut       = $null
            DTCMaxConnectionsToServer   = $null
            DTCRequestTimeout           = $null
            DTCChannelOpenTimeOut       = $null
            DSTACMaxConnectionsToServer = $null
            DSTACRequestTimeout         = $null
            DSTACChannelOpenTimeOut     = $null
            DFLTCMaxConnectionsToServer = $null
            DFLTCRequestTimeout         = $null
            DFLTCChannelOpenTimeOut     = $null
            DSWUCMaxConnectionsToServer = $null
            DSWUCRequestTimeout         = $null
            DSWUCChannelOpenTimeOut     = $null
            DUGCMaxConnectionsToServer  = $null
            DUGCRequestTimeout          = $null
            DUGCChannelOpenTimeOut      = $null
            DRTCMaxConnectionsToServer  = $null
            DRTCRequestTimeout          = $null
            DRTCChannelOpenTimeOut      = $null
            DHSCMaxConnectionsToServer  = $null
            DHSCRequestTimeout          = $null
            DHSCChannelOpenTimeOut      = $null
        }

        try
        {
            $DLTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedLogonTokenCache"
            $DVSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedViewStateCache"
            $DAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedAccessCache"
            $DAF = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedCache"
            $DAFC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedLMTCache"
            $DBC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedBouncerCache"
            $DDC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedDefaultCache"
            $DSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSearchCache"
            $DTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSecurityTrimmingCache"
            $DSTAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedServerToAppServerAccessTokenCache"
            $DFLTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedFileLockThrottlerCache"
            $DSWUC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSharedWithUserCache"
            $DUGC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedUnifiedGroupsCache"
            $DRTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedResourceTallyCache"
            $DHSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedHealthScoreCache"

            $returnValue = @{
                IsSingleInstance            = "Yes"
                DLTCMaxConnectionsToServer  = $DLTC.MaxConnectionsToServer
                DLTCRequestTimeout          = $DLTC.RequestTimeout
                DLTCChannelOpenTimeOut      = $DLTC.ChannelOpenTimeOut
                DVSCMaxConnectionsToServer  = $DVSC.MaxConnectionsToServer
                DVSCRequestTimeout          = $DVSC.RequestTimeout
                DVSCChannelOpenTimeOut      = $DVSC.ChannelOpenTimeOut
                DACMaxConnectionsToServer   = $DAC.MaxConnectionsToServer
                DACRequestTimeout           = $DAC.RequestTimeout
                DACChannelOpenTimeOut       = $DAC.ChannelOpenTimeOut
                DAFMaxConnectionsToServer   = $DAF.MaxConnectionsToServer
                DAFRequestTimeout           = $DAF.RequestTimeout
                DAFChannelOpenTimeOut       = $DAF.ChannelOpenTimeOut
                DAFCMaxConnectionsToServer  = $DAFC.MaxConnectionsToServer
                DAFCRequestTimeout          = $DAFC.RequestTimeout
                DAFCChannelOpenTimeOut      = $DAFC.ChannelOpenTimeOut
                DBCMaxConnectionsToServer   = $DBC.MaxConnectionsToServer
                DBCRequestTimeout           = $DBC.RequestTimeout
                DBCChannelOpenTimeOut       = $DBC.ChannelOpenTimeOut
                DDCMaxConnectionsToServer   = $DDC.MaxConnectionsToServer
                DDCRequestTimeout           = $DDC.RequestTimeout
                DDCChannelOpenTimeOut       = $DDC.ChannelOpenTimeOut
                DSCMaxConnectionsToServer   = $DSC.MaxConnectionsToServer
                DSCRequestTimeout           = $DSC.RequestTimeout
                DSCChannelOpenTimeOut       = $DSC.ChannelOpenTimeOut
                DTCMaxConnectionsToServer   = $DTC.MaxConnectionsToServer
                DTCRequestTimeout           = $DTC.RequestTimeout
                DTCChannelOpenTimeOut       = $DTC.ChannelOpenTimeOut
                DSTACMaxConnectionsToServer = $DSTAC.MaxConnectionsToServer
                DSTACRequestTimeout         = $DSTAC.RequestTimeout
                DSTACChannelOpenTimeOut     = $DSTAC.ChannelOpenTimeOut
                DFLTCMaxConnectionsToServer = $DFLTC.MaxConnectionsToServer
                DFLTCRequestTimeout         = $DFLTC.RequestTimeout
                DFLTCChannelOpenTimeOut     = $DFLTC.ChannelOpenTimeOut
                DSWUCMaxConnectionsToServer = $DSWUC.MaxConnectionsToServer
                DSWUCRequestTimeout         = $DSWUC.RequestTimeout
                DSWUCChannelOpenTimeOut     = $DSWUC.ChannelOpenTimeOut
                DUGCMaxConnectionsToServer  = $DUGC.MaxConnectionsToServer
                DUGCRequestTimeout          = $DUGC.RequestTimeout
                DUGCChannelOpenTimeOut      = $DUGC.ChannelOpenTimeOut
                DRTCMaxConnectionsToServer  = $DRTC.MaxConnectionsToServer
                DRTCRequestTimeout          = $DRTC.RequestTimeout
                DRTCChannelOpenTimeOut      = $DRTC.ChannelOpenTimeOut
                DHSCMaxConnectionsToServer  = $DHSC.MaxConnectionsToServer
                DHSCRequestTimeout          = $DHSC.RequestTimeout
                DHSCChannelOpenTimeOut      = $DHSC.ChannelOpenTimeOut
            }
            return $returnValue
        }
        catch
        {
            return $nullReturnValue
        }
    }
    return $result
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.UInt32]
        $DLTCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DLTCRequestTimeout = 500,

        [Parameter()]
        [System.UInt32]
        $DLTCChannelOpenTimeOut = 20,

        [Parameter()]
        [System.UInt32]
        $DVSCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DVSCRequestTimeout = 20,

        [Parameter()]
        [System.UInt32]
        $DVSCChannelOpenTimeOut = 20,

        [Parameter()]
        [System.UInt32]
        $DACMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DACRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DACChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DAFMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DAFRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DAFChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DAFCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DAFCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DAFCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DBCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DBCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DBCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DDCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DDCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DDCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DSCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DSCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DSCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DTCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DTCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DTCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DSTACMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DSTACRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DSTACChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DFLTCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DFLTCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DFLTCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DSWUCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DSWUCRequestTimeout = 3000,

        [Parameter()]
        [System.UInt32]
        $DSWUCChannelOpenTimeOut = 3000,

        [Parameter()]
        [System.UInt32]
        $DUGCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DUGCRequestTimeout = 500,

        [Parameter()]
        [System.UInt32]
        $DUGCChannelOpenTimeOut = 100,

        [Parameter()]
        [System.UInt32]
        $DRTCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DRTCRequestTimeout = 500,

        [Parameter()]
        [System.UInt32]
        $DRTCChannelOpenTimeOut = 20,

        [Parameter()]
        [System.UInt32]
        $DHSCMaxConnectionsToServer = 4,

        [Parameter()]
        [System.UInt32]
        $DHSCRequestTimeout = 500,

        [Parameter()]
        [System.UInt32]
        $DHSCChannelOpenTimeOut = 20,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting the Distributed Cache Client Settings"

    if ($PSBoundParameters.ContainsKey("DFLTCMaxConnectionsToServer") -or
        $PSBoundParameters.ContainsKey("DFLTCRequestTimeout") -or
        $PSBoundParameters.ContainsKey("DFLTCChannelOpenTimeOut") -or
        $PSBoundParameters.ContainsKey("DSWUCMaxConnectionsToServer") -or
        $PSBoundParameters.ContainsKey("DSWUCRequestTimeout") -or
        $PSBoundParameters.ContainsKey("DSWUCChannelOpenTimeOut") -or
        $PSBoundParameters.ContainsKey("DUGCMaxConnectionsToServer") -or
        $PSBoundParameters.ContainsKey("DUGCRequestTimeout") -or
        $PSBoundParameters.ContainsKey("DUGCChannelOpenTimeOut") -or
        $PSBoundParameters.ContainsKey("DRTCMaxConnectionsToServer") -or
        $PSBoundParameters.ContainsKey("DRTCRequestTimeout") -or
        $PSBoundParameters.ContainsKey("DRTCChannelOpenTimeOut") -or
        $PSBoundParameters.ContainsKey("DHSCMaxConnectionsToServer") -or
        $PSBoundParameters.ContainsKey("DHSCRequestTimeout") -or
        $PSBoundParameters.ContainsKey("DHSCChannelOpenTimeOut"))
    {
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -eq 15)
        {
            throw ("The following parameters are only supported in SharePoint 2016 and above: " + `
                    "DFLTCMaxConnectionsToServer, DFLTCRequestTimeout, DFLTCChannelOpenTimeOut, " + `
                    "DSWUCMaxConnectionsToServer, DSWUCRequestTimeout, DSWUCChannelOpenTimeOut, " + `
                    "DUGCMaxConnectionsToServer, DUGCRequestTimeout, DUGCChannelOpenTimeOut, " + `
                    "DRTCMaxConnectionsToServer, DRTCRequestTimeout, DRTCChannelOpenTimeOut, " + `
                    "DHSCMaxConnectionsToServer, DHSCRequestTimeout and DHSCChannelOpenTimeOut")
        }
    }

    Invoke-SPDscCommand -Credential $InstallAccount `
        -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        #DistributedLogonTokenCache
        $DLTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedLogonTokenCache"

        if ($params.DLTCMaxConnectionsToServer)
        {
            $DLTC.MaxConnectionsToServer = $params.DLTCMaxConnectionsToServer
        }
        if ($params.DLTCRequestTimeout)
        {
            $DLTC.RequestTimeout = $params.DLTCRequestTimeout
        }
        if ($params.DLTCChannelOpenTimeOut)
        {
            $DLTC.ChannelOpenTimeOut = $params.DLTCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedLogonTokenCache" $DLTC

        #DistributedViewStateCache
        $DVSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedViewStateCache"
        if ($params.DVSCMaxConnectionsToServer)
        {
            $DVSC.MaxConnectionsToServer = $params.DVSCMaxConnectionsToServer
        }
        if ($params.DVSCRequestTimeout)
        {
            $DVSC.RequestTimeout = $params.DVSCRequestTimeout
        }
        if ($params.DVSCChannelOpenTimeOut)
        {
            $DVSC.ChannelOpenTimeOut = $params.DVSCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedViewStateCache" $DVSC

        #DistributedAccessCache
        $DAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedAccessCache"
        if ($params.DACMaxConnectionsToServer)
        {
            $DAC.MaxConnectionsToServer = $params.DACMaxConnectionsToServer
        }
        if ($params.DACRequestTimeout)
        {
            $DAC.RequestTimeout = $params.DACRequestTimeout
        }
        if ($params.DACChannelOpenTimeOut)
        {
            $DAC.ChannelOpenTimeOut = $params.DACChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedAccessCache" $DAC

        #DistributedActivityFeedCache
        $DAF = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedCache"
        if ($params.DAFMaxConnectionsToServer)
        {
            $DAF.MaxConnectionsToServer = $params.DAFMaxConnectionsToServer
        }
        if ($params.DAFRequestTimeout)
        {
            $DAF.RequestTimeout = $params.DAFRequestTimeout
        }
        if ($params.DAFChannelOpenTimeOut)
        {
            $DAF.ChannelOpenTimeOut = $params.DAFChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedCache" $DAF

        #DistributedActivityFeedLMTCache
        $DAFC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedLMTCache"
        if ($params.DAFCMaxConnectionsToServer)
        {
            $DAFC.MaxConnectionsToServer = $params.DAFCMaxConnectionsToServer
        }
        if ($params.DAFCRequestTimeout)
        {
            $DAFC.RequestTimeout = $params.DAFCRequestTimeout
        }
        if ($params.DAFCChannelOpenTimeOut)
        {
            $DAFC.ChannelOpenTimeOut = $params.DAFCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedLMTCache" $DAFC

        #DistributedBouncerCache
        $DBC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedBouncerCache"
        if ($params.DBCMaxConnectionsToServer)
        {
            $DBC.MaxConnectionsToServer = $params.DBCMaxConnectionsToServer
        }
        if ($params.DBCRequestTimeout)
        {
            $DBC.RequestTimeout = $params.DBCRequestTimeout
        }
        if ($params.DBCChannelOpenTimeOut)
        {
            $DBC.ChannelOpenTimeOut = $params.DBCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedBouncerCache" $DBC

        #DistributedDefaultCache
        $DDC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedDefaultCache"
        if ($params.DDCMaxConnectionsToServer)
        {
            $DDC.MaxConnectionsToServer = $params.DDCMaxConnectionsToServer
        }
        if ($params.DDCRequestTimeout)
        {
            $DDC.RequestTimeout = $params.DDCRequestTimeout
        }
        if ($params.DDCChannelOpenTimeOut)
        {
            $DDC.ChannelOpenTimeOut = $params.DDCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedDefaultCache" $DDC

        #DistributedSearchCache
        $DSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSearchCache"
        if ($params.DSCMaxConnectionsToServer)
        {
            $DSC.MaxConnectionsToServer = $params.DSCMaxConnectionsToServer
        }
        if ($params.DSCRequestTimeout)
        {
            $DSC.RequestTimeout = $params.DSCRequestTimeout
        }
        if ($params.DSCChannelOpenTimeOut)
        {
            $DSC.ChannelOpenTimeOut = $params.DSCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedSearchCache" $DSC

        #DistributedSecurityTrimmingCache
        $DTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSecurityTrimmingCache"
        if ($params.DTCMaxConnectionsToServer)
        {
            $DTC.MaxConnectionsToServer = $params.DTCMaxConnectionsToServer
        }
        if ($params.DTCRequestTimeout)
        {
            $DTC.RequestTimeout = $params.DTCRequestTimeout
        }
        if ($params.DTCChannelOpenTimeOut)
        {
            $DTC.ChannelOpenTimeOut = $params.DTCChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedSecurityTrimmingCache" $DTC

        #DistributedServerToAppServerAccessTokenCache
        $DSTAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedServerToAppServerAccessTokenCache"
        if ($params.DSTACMaxConnectionsToServer)
        {
            $DSTAC.MaxConnectionsToServer = $params.DSTACMaxConnectionsToServer
        }
        if ($params.DSTACRequestTimeout)
        {
            $DSTAC.RequestTimeout = $params.DSTACRequestTimeout
        }
        if ($params.DSTACChannelOpenTimeOut)
        {
            $DSTAC.ChannelOpenTimeOut = $params.DSTACChannelOpenTimeOut
        }
        Set-SPDistributedCacheClientSetting -ContainerType "DistributedServerToAppServerAccessTokenCache" $DSTAC

        # The following parameters are only required on SharePoint 2016 and above
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -ne 15)
        {
            #DistributedFileLockThrottlerCache
            $DFLTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedFileLockThrottlerCache"
            if ($params.DFLTCMaxConnectionsToServer)
            {
                $DFLTC.MaxConnectionsToServer = $params.DFLTCMaxConnectionsToServer
            }
            if ($params.DFLTCRequestTimeout)
            {
                $DFLTC.RequestTimeout = $params.DFLTCRequestTimeout
            }
            if ($params.DFLTCChannelOpenTimeOut)
            {
                $DFLTC.ChannelOpenTimeOut = $params.DFLTCChannelOpenTimeOut
            }
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedFileLockThrottlerCache" $DFLTC

            #DistributedSharedWithUserCache
            $DSWUC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSharedWithUserCache"
            if ($params.DSWUCMaxConnectionsToServer)
            {
                $DSWUC.MaxConnectionsToServer = $params.DSWUCMaxConnectionsToServer
            }
            if ($params.DSWUCRequestTimeout)
            {
                $DSWUC.RequestTimeout = $params.DSWUCRequestTimeout
            }
            if ($params.DSWUCChannelOpenTimeOut)
            {
                $DSWUC.ChannelOpenTimeOut = $params.DSWUCChannelOpenTimeOut
            }
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedSharedWithUserCache" $DSWUC

            #DistributedUnifiedGroupsCache
            $DUGC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedUnifiedGroupsCache"
            if ($params.DUGCMaxConnectionsToServer)
            {
                $DUGC.MaxConnectionsToServer = $params.DUGCMaxConnectionsToServer
            }
            if ($params.DUGCRequestTimeout)
            {
                $DUGC.RequestTimeout = $params.DUGCRequestTimeout
            }
            if ($params.DUGCChannelOpenTimeOut)
            {
                $DUGC.ChannelOpenTimeOut = $params.DUGCChannelOpenTimeOut
            }
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedUnifiedGroupsCache" $DUGC

            #DistributedResourceTallyCache
            $DRTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedResourceTallyCache"
            if ($params.DRTCMaxConnectionsToServer)
            {
                $DRTC.MaxConnectionsToServer = $params.DRTCMaxConnectionsToServer
            }
            if ($params.DRTCRequestTimeout)
            {
                $DRTC.RequestTimeout = $params.DRTCRequestTimeout
            }
            if ($params.DRTCChannelOpenTimeOut)
            {
                $DRTC.ChannelOpenTimeOut = $params.DRTCChannelOpenTimeOut
            }
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedResourceTallyCache" $DRTC

            #DistributedHealthScoreCache
            $DHSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedHealthScoreCache"
            if ($params.DHSCMaxConnectionsToServer)
            {
                $DHSC.MaxConnectionsToServer = $params.DHSCMaxConnectionsToServer
            }
            if ($params.DHSCRequestTimeout)
            {
                $DHSC.RequestTimeout = $params.DHSCRequestTimeout
            }
            if ($params.DHSCChannelOpenTimeOut)
            {
                $DHSC.ChannelOpenTimeOut = $params.DHSCChannelOpenTimeOut
            }
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedHealthScoreCache" $DHSC
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Yes")]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.UInt32]
        $DLTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DLTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DLTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DVSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DVSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DVSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DAFMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DAFRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DAFChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DAFCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DAFCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DAFCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DBCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DBCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DBCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DDCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DDCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DDCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSTACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSTACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSTACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DFLTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DFLTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DFLTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSWUCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSWUCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSWUCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUGCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUGCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUGCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DRTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DRTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DRTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DHSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DHSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DHSCChannelOpenTimeOut,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing the Distributed Cache Client Settings"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-SPDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SPDscHashtableToString -Hashtable $PSBoundParameters)"

    $result = Test-SPDscParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("DLTCMaxConnectionsToServer",
        "DLTCRequestTimeout",
        "DLTCChannelOpenTimeOut",
        "DVSCMaxConnectionsToServer",
        "DVSCRequestTimeout",
        "DVSCChannelOpenTimeOut",
        "DACMaxConnectionsToServer",
        "DACRequestTimeout",
        "DACChannelOpenTimeOut",
        "DAFMaxConnectionsToServer",
        "DAFRequestTimeout",
        "DAFChannelOpenTimeOut",
        "DAFCMaxConnectionsToServer",
        "DAFCRequestTimeout",
        "DAFCChannelOpenTimeOut",
        "DBCMaxConnectionsToServer",
        "DBCRequestTimeout",
        "DBCChannelOpenTimeOut",
        "DDCMaxConnectionsToServer",
        "DDCRequestTimeout",
        "DDCChannelOpenTimeOut",
        "DSCMaxConnectionsToServer",
        "DSCRequestTimeout",
        "DSCChannelOpenTimeOut",
        "DTCMaxConnectionsToServer",
        "DTCRequestTimeout",
        "DTCChannelOpenTimeOut",
        "DSTACMaxConnectionsToServer",
        "DSTACRequestTimeout",
        "DSTACChannelOpenTimeOut",
        "DFLTCMaxConnectionsToServer",
        "DFLTCRequestTimeout",
        "DFLTCChannelOpenTimeOut",
        "DSWUCMaxConnectionsToServer",
        "DSWUCRequestTimeout",
        "DSWUCChannelOpenTimeOut",
        "DUGCMaxConnectionsToServer",
        "DUGCRequestTimeout",
        "DUGCChannelOpenTimeOut",
        "DRTCMaxConnectionsToServer",
        "DRTCRequestTimeout",
        "DRTCChannelOpenTimeOut",
        "DHSCMaxConnectionsToServer",
        "DHSCRequestTimeout",
        "DHSCChannelOpenTimeOut"
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
