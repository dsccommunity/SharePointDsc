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
        [System.UInt32]
        $DDBFCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DDBFCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DDBFCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DEHCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DEHCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DEHCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DFSPTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DFSPTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DFSPTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPABSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPABSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPABSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPCVCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPCVCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPCVCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPOATCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPOATCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPOATCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSGCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSGCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSGCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUAuCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUAuCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUAuCChannelOpenTimeOut
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
            $message = ("The following parameters are only supported in SharePoint 2016 and above: " + `
                    "DFLTCMaxConnectionsToServer, DFLTCRequestTimeout, DFLTCChannelOpenTimeOut, " + `
                    "DSWUCMaxConnectionsToServer, DSWUCRequestTimeout, DSWUCChannelOpenTimeOut, " + `
                    "DUGCMaxConnectionsToServer, DUGCRequestTimeout, DUGCChannelOpenTimeOut, " + `
                    "DRTCMaxConnectionsToServer, DRTCRequestTimeout, DRTCChannelOpenTimeOut, " + `
                    "DHSCMaxConnectionsToServer, DHSCRequestTimeout and DHSCChannelOpenTimeOut")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey("DDBFCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DDBFCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DDBFCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCChannelOpenTimeOut") -eq $true)
    {
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -eq 15 -or `
                $installedVersion.ProductBuildPart.ToString().Length -eq 4)
        {
            $message = ("The following parameters are only supported in SharePoint 2019 and above: " + `
                    "DDBFCMaxConnectionsToServer, DDBFCRequestTimeout, DDBFCChannelOpenTimeOut, " + `
                    "DEHCMaxConnectionsToServer, DEHCRequestTimeout, DEHCChannelOpenTimeOut, " + `
                    "DFSPTCMaxConnectionsToServer, DFSPTCRequestTimeout, DFSPTCChannelOpenTimeOut, " + `
                    "DSPABSCMaxConnectionsToServer, DSPABSCRequestTimeout, DSPABSCChannelOpenTimeOut, " + `
                    "DSPCVCMaxConnectionsToServer, DSPCVCRequestTimeout, DSPCVCChannelOpenTimeOut, " + `
                    "DSPOATCMaxConnectionsToServer, DSPOATCRequestTimeout, DSPOATCChannelOpenTimeOut, " + `
                    "DSGCMaxConnectionsToServer, DSGCRequestTimeout, DSGCChannelOpenTimeOut, " + `
                    "DUACMaxConnectionsToServer, DUACRequestTimeout, DUACChannelOpenTimeOut, " + `
                    "DUAuCMaxConnectionsToServer, DUAuCRequestTimeout, DUAuCChannelOpenTimeOut")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    $result = Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        $nullReturnValue = @{
            IsSingleInstance              = "Yes"
            DLTCMaxConnectionsToServer    = $null
            DLTCRequestTimeout            = $null
            DLTCChannelOpenTimeOut        = $null
            DVSCMaxConnectionsToServer    = $null
            DVSCRequestTimeout            = $null
            DVSCChannelOpenTimeOut        = $null
            DACMaxConnectionsToServer     = $null
            DACRequestTimeout             = $null
            DACChannelOpenTimeOut         = $null
            DAFMaxConnectionsToServer     = $null
            DAFRequestTimeout             = $null
            DAFChannelOpenTimeOut         = $null
            DAFCMaxConnectionsToServer    = $null
            DAFCRequestTimeout            = $null
            DAFCChannelOpenTimeOut        = $null
            DBCMaxConnectionsToServer     = $null
            DBCRequestTimeout             = $null
            DBCChannelOpenTimeOut         = $null
            DDCMaxConnectionsToServer     = $null
            DDCRequestTimeout             = $null
            DDCChannelOpenTimeOut         = $null
            DSCMaxConnectionsToServer     = $null
            DSCRequestTimeout             = $null
            DSCChannelOpenTimeOut         = $null
            DTCMaxConnectionsToServer     = $null
            DTCRequestTimeout             = $null
            DTCChannelOpenTimeOut         = $null
            DSTACMaxConnectionsToServer   = $null
            DSTACRequestTimeout           = $null
            DSTACChannelOpenTimeOut       = $null
            DFLTCMaxConnectionsToServer   = $null
            DFLTCRequestTimeout           = $null
            DFLTCChannelOpenTimeOut       = $null
            DSWUCMaxConnectionsToServer   = $null
            DSWUCRequestTimeout           = $null
            DSWUCChannelOpenTimeOut       = $null
            DUGCMaxConnectionsToServer    = $null
            DUGCRequestTimeout            = $null
            DUGCChannelOpenTimeOut        = $null
            DRTCMaxConnectionsToServer    = $null
            DRTCRequestTimeout            = $null
            DRTCChannelOpenTimeOut        = $null
            DHSCMaxConnectionsToServer    = $null
            DHSCRequestTimeout            = $null
            DHSCChannelOpenTimeOut        = $null
            DDBFCMaxConnectionsToServer   = $null
            DDBFCRequestTimeout           = $null
            DDBFCChannelOpenTimeOut       = $null
            DEHCMaxConnectionsToServer    = $null
            DEHCRequestTimeout            = $null
            DEHCChannelOpenTimeOut        = $null
            DFSPTCMaxConnectionsToServer  = $null
            DFSPTCRequestTimeout          = $null
            DFSPTCChannelOpenTimeOut      = $null
            DSPABSCMaxConnectionsToServer = $null
            DSPABSCRequestTimeout         = $null
            DSPABSCChannelOpenTimeOut     = $null
            DSPCVCMaxConnectionsToServer  = $null
            DSPCVCRequestTimeout          = $null
            DSPCVCChannelOpenTimeOut      = $null
            DSPOATCMaxConnectionsToServer = $null
            DSPOATCRequestTimeout         = $null
            DSPOATCChannelOpenTimeOut     = $null
            DSGCMaxConnectionsToServer    = $null
            DSGCRequestTimeout            = $null
            DSGCChannelOpenTimeOut        = $null
            DUACMaxConnectionsToServer    = $null
            DUACRequestTimeout            = $null
            DUACChannelOpenTimeOut        = $null
            DUAuCMaxConnectionsToServer   = $null
            DUAuCRequestTimeout           = $null
            DUAuCChannelOpenTimeOut       = $null
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
            $DDBFC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedDbLevelFailoverCache"
            $DEHC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedEdgeHeaderCache"
            $DFSPTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedFileStorePerformanceTraceCache"
            $DSPABSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSPAbsBlobCache"
            $DSPCVC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSPCertificateValidatorCache"
            $DSPOATC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSPOAuthTokenCache"
            $DSGC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedStopgapCache"
            $DUAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedUnifiedAppsCache"
            $DUAuC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedUnifiedAuditCache"

            $returnValue = @{
                IsSingleInstance              = "Yes"
                DLTCMaxConnectionsToServer    = $DLTC.MaxConnectionsToServer
                DLTCRequestTimeout            = $DLTC.RequestTimeout
                DLTCChannelOpenTimeOut        = $DLTC.ChannelOpenTimeOut
                DVSCMaxConnectionsToServer    = $DVSC.MaxConnectionsToServer
                DVSCRequestTimeout            = $DVSC.RequestTimeout
                DVSCChannelOpenTimeOut        = $DVSC.ChannelOpenTimeOut
                DACMaxConnectionsToServer     = $DAC.MaxConnectionsToServer
                DACRequestTimeout             = $DAC.RequestTimeout
                DACChannelOpenTimeOut         = $DAC.ChannelOpenTimeOut
                DAFMaxConnectionsToServer     = $DAF.MaxConnectionsToServer
                DAFRequestTimeout             = $DAF.RequestTimeout
                DAFChannelOpenTimeOut         = $DAF.ChannelOpenTimeOut
                DAFCMaxConnectionsToServer    = $DAFC.MaxConnectionsToServer
                DAFCRequestTimeout            = $DAFC.RequestTimeout
                DAFCChannelOpenTimeOut        = $DAFC.ChannelOpenTimeOut
                DBCMaxConnectionsToServer     = $DBC.MaxConnectionsToServer
                DBCRequestTimeout             = $DBC.RequestTimeout
                DBCChannelOpenTimeOut         = $DBC.ChannelOpenTimeOut
                DDCMaxConnectionsToServer     = $DDC.MaxConnectionsToServer
                DDCRequestTimeout             = $DDC.RequestTimeout
                DDCChannelOpenTimeOut         = $DDC.ChannelOpenTimeOut
                DSCMaxConnectionsToServer     = $DSC.MaxConnectionsToServer
                DSCRequestTimeout             = $DSC.RequestTimeout
                DSCChannelOpenTimeOut         = $DSC.ChannelOpenTimeOut
                DTCMaxConnectionsToServer     = $DTC.MaxConnectionsToServer
                DTCRequestTimeout             = $DTC.RequestTimeout
                DTCChannelOpenTimeOut         = $DTC.ChannelOpenTimeOut
                DSTACMaxConnectionsToServer   = $DSTAC.MaxConnectionsToServer
                DSTACRequestTimeout           = $DSTAC.RequestTimeout
                DSTACChannelOpenTimeOut       = $DSTAC.ChannelOpenTimeOut
                DFLTCMaxConnectionsToServer   = $DFLTC.MaxConnectionsToServer
                DFLTCRequestTimeout           = $DFLTC.RequestTimeout
                DFLTCChannelOpenTimeOut       = $DFLTC.ChannelOpenTimeOut
                DSWUCMaxConnectionsToServer   = $DSWUC.MaxConnectionsToServer
                DSWUCRequestTimeout           = $DSWUC.RequestTimeout
                DSWUCChannelOpenTimeOut       = $DSWUC.ChannelOpenTimeOut
                DUGCMaxConnectionsToServer    = $DUGC.MaxConnectionsToServer
                DUGCRequestTimeout            = $DUGC.RequestTimeout
                DUGCChannelOpenTimeOut        = $DUGC.ChannelOpenTimeOut
                DRTCMaxConnectionsToServer    = $DRTC.MaxConnectionsToServer
                DRTCRequestTimeout            = $DRTC.RequestTimeout
                DRTCChannelOpenTimeOut        = $DRTC.ChannelOpenTimeOut
                DHSCMaxConnectionsToServer    = $DHSC.MaxConnectionsToServer
                DHSCRequestTimeout            = $DHSC.RequestTimeout
                DHSCChannelOpenTimeOut        = $DHSC.ChannelOpenTimeOut
                DDBFCMaxConnectionsToServer   = $DDBFC.MaxConnectionsToServer
                DDBFCRequestTimeout           = $DDBFC.RequestTimeout
                DDBFCChannelOpenTimeOut       = $DDBFC.ChannelOpenTimeOut
                DEHCMaxConnectionsToServer    = $DEHC.MaxConnectionsToServer
                DEHCRequestTimeout            = $DEHC.RequestTimeout
                DEHCChannelOpenTimeOut        = $DEHC.ChannelOpenTimeOut
                DFSPTCMaxConnectionsToServer  = $DFSPTC.MaxConnectionsToServer
                DFSPTCRequestTimeout          = $DFSPTC.RequestTimeout
                DFSPTCChannelOpenTimeOut      = $DFSPTC.ChannelOpenTimeOut
                DSPABSCMaxConnectionsToServer = $DSPABSC.MaxConnectionsToServer
                DSPABSCRequestTimeout         = $DSPABSC.RequestTimeout
                DSPABSCChannelOpenTimeOut     = $DSPABSC.ChannelOpenTimeOut
                DSPCVCMaxConnectionsToServer  = $DSPCVC.MaxConnectionsToServer
                DSPCVCRequestTimeout          = $DSPCVC.RequestTimeout
                DSPCVCChannelOpenTimeOut      = $DSPCVC.ChannelOpenTimeOut
                DSPOATCMaxConnectionsToServer = $DSPOATC.MaxConnectionsToServer
                DSPOATCRequestTimeout         = $DSPOATC.RequestTimeout
                DSPOATCChannelOpenTimeOut     = $DSPOATC.ChannelOpenTimeOut
                DSGCMaxConnectionsToServer    = $DSGC.MaxConnectionsToServer
                DSGCRequestTimeout            = $DSGC.RequestTimeout
                DSGCChannelOpenTimeOut        = $DSGC.ChannelOpenTimeOut
                DUACMaxConnectionsToServer    = $DUAC.MaxConnectionsToServer
                DUACRequestTimeout            = $DUAC.RequestTimeout
                DUACChannelOpenTimeOut        = $DUAC.ChannelOpenTimeOut
                DUAuCMaxConnectionsToServer   = $DUAuC.MaxConnectionsToServer
                DUAuCRequestTimeout           = $DUAuC.RequestTimeout
                DUAuCChannelOpenTimeOut       = $DUAuC.ChannelOpenTimeOut
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
        [System.UInt32]
        $DDBFCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DDBFCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DDBFCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DEHCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DEHCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DEHCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DFSPTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DFSPTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DFSPTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPABSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPABSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPABSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPCVCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPCVCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPCVCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPOATCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPOATCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPOATCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSGCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSGCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSGCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUAuCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUAuCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUAuCChannelOpenTimeOut
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
            $message = ("The following parameters are only supported in SharePoint 2016 and above: " + `
                    "DFLTCMaxConnectionsToServer, DFLTCRequestTimeout, DFLTCChannelOpenTimeOut, " + `
                    "DSWUCMaxConnectionsToServer, DSWUCRequestTimeout, DSWUCChannelOpenTimeOut, " + `
                    "DUGCMaxConnectionsToServer, DUGCRequestTimeout, DUGCChannelOpenTimeOut, " + `
                    "DRTCMaxConnectionsToServer, DRTCRequestTimeout, DRTCChannelOpenTimeOut, " + `
                    "DHSCMaxConnectionsToServer, DHSCRequestTimeout and DHSCChannelOpenTimeOut")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey("DDBFCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DDBFCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DDBFCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DEHCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DFSPTCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPABSCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPCVCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSPOATCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DSGCChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DUACChannelOpenTimeOut") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCMaxConnectionsToServer") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCRequestTimeout") -eq $true -or
        $PSBoundParameters.ContainsKey("DUAuCChannelOpenTimeOut") -eq $true)
    {
        $installedVersion = Get-SPDscInstalledProductVersion
        if ($installedVersion.FileMajorPart -eq 15 -or `
                $installedVersion.ProductBuildPart.ToString().Length -eq 4)
        {
            $message = ("The following parameters are only supported in SharePoint 2019 and above: " + `
                    "DDBFCMaxConnectionsToServer, DDBFCRequestTimeout, DDBFCChannelOpenTimeOut, " + `
                    "DEHCMaxConnectionsToServer, DEHCRequestTimeout, DEHCChannelOpenTimeOut, " + `
                    "DFSPTCMaxConnectionsToServer, DFSPTCRequestTimeout, DFSPTCChannelOpenTimeOut, " + `
                    "DSPABSCMaxConnectionsToServer, DSPABSCRequestTimeout, DSPABSCChannelOpenTimeOut, " + `
                    "DSPCVCMaxConnectionsToServer, DSPCVCRequestTimeout, DSPCVCChannelOpenTimeOut, " + `
                    "DSPOATCMaxConnectionsToServer, DSPOATCRequestTimeout, DSPOATCChannelOpenTimeOut, " + `
                    "DSGCMaxConnectionsToServer, DSGCRequestTimeout, DSGCChannelOpenTimeOut, " + `
                    "DUACMaxConnectionsToServer, DUACRequestTimeout, DUACChannelOpenTimeOut, " + `
                    "DUAuCMaxConnectionsToServer, DUAuCRequestTimeout, DUAuCChannelOpenTimeOut")
            Add-SPDscEvent -Message $message `
                -EntryType 'Error' `
                -EventID 100 `
                -Source $MyInvocation.MyCommand.Source
            throw $message
        }
    }

    Invoke-SPDscCommand -Arguments $PSBoundParameters `
        -ScriptBlock {
        $params = $args[0]

        #region Mapping Table
        $parameterToContainerTypeMapping = @{
            # DistributedLogonTokenCache
            DLTCMaxConnectionsToServer    = 'DistributedLogonTokenCache'
            DLTCRequestTimeout            = 'DistributedLogonTokenCache'
            DLTCChannelOpenTimeOut        = 'DistributedLogonTokenCache'
            # DistributedViewStateCache
            DVSCMaxConnectionsToServer    = 'DistributedViewStateCache'
            DVSCRequestTimeout            = 'DistributedViewStateCache'
            DVSCChannelOpenTimeOut        = 'DistributedViewStateCache'
            # DistributedAccessCache
            DACMaxConnectionsToServer     = 'DistributedAccessCache'
            DACRequestTimeout             = 'DistributedAccessCache'
            DACChannelOpenTimeOut         = 'DistributedAccessCache'
            # DistributedActivityFeedCache
            DAFMaxConnectionsToServer     = 'DistributedActivityFeedCache'
            DAFRequestTimeout             = 'DistributedActivityFeedCache'
            DAFChannelOpenTimeOut         = 'DistributedActivityFeedCache'
            # DistributedActivityFeedLMTCache
            DAFCMaxConnectionsToServer    = 'DistributedActivityFeedLMTCache'
            DAFCRequestTimeout            = 'DistributedActivityFeedLMTCache'
            DAFCChannelOpenTimeOut        = 'DistributedActivityFeedLMTCache'
            # DistributedBouncerCache
            DBCMaxConnectionsToServer     = 'DistributedBouncerCache'
            DBCRequestTimeout             = 'DistributedBouncerCache'
            DBCChannelOpenTimeOut         = 'DistributedBouncerCache'
            # DistributedDefaultCache
            DDCMaxConnectionsToServer     = 'DistributedDefaultCache'
            DDCRequestTimeout             = 'DistributedDefaultCache'
            DDCChannelOpenTimeOut         = 'DistributedDefaultCache'
            # DistributedSearchCache
            DSCMaxConnectionsToServer     = 'DistributedSearchCache'
            DSCRequestTimeout             = 'DistributedSearchCache'
            DSCChannelOpenTimeOut         = 'DistributedSearchCache'
            # DistributedSecurityTrimmingCache
            DTCMaxConnectionsToServer     = 'DistributedSecurityTrimmingCache'
            DTCRequestTimeout             = 'DistributedSecurityTrimmingCache'
            DTCChannelOpenTimeOut         = 'DistributedSecurityTrimmingCache'
            # DistributedServerToAppServerAccessTokenCache
            DSTACMaxConnectionsToServer   = 'DistributedServerToAppServerAccessTokenCache'
            DSTACRequestTimeout           = 'DistributedServerToAppServerAccessTokenCache'
            DSTACChannelOpenTimeOut       = 'DistributedServerToAppServerAccessTokenCache'
            # DistributedFileLockThrottlerCache
            DFLTCMaxConnectionsToServer   = 'DistributedFileLockThrottlerCache'
            DFLTCRequestTimeout           = 'DistributedFileLockThrottlerCache'
            DFLTCChannelOpenTimeOut       = 'DistributedFileLockThrottlerCache'
            # DistributedSharedWithUserCache
            DSWUCMaxConnectionsToServer   = 'DistributedSharedWithUserCache'
            DSWUCRequestTimeout           = 'DistributedSharedWithUserCache'
            DSWUCChannelOpenTimeOut       = 'DistributedSharedWithUserCache'
            # DistributedUnifiedGroupsCache
            DUGCMaxConnectionsToServer    = 'DistributedUnifiedGroupsCache'
            DUGCRequestTimeout            = 'DistributedUnifiedGroupsCache'
            DUGCChannelOpenTimeOut        = 'DistributedUnifiedGroupsCache'
            # DistributedResourceTallyCache
            DRTCMaxConnectionsToServer    = 'DistributedResourceTallyCache'
            DRTCRequestTimeout            = 'DistributedResourceTallyCache'
            DRTCChannelOpenTimeOut        = 'DistributedResourceTallyCache'
            # DistributedHealthScoreCache
            DHSCMaxConnectionsToServer    = 'DistributedHealthScoreCache'
            DHSCRequestTimeout            = 'DistributedHealthScoreCache'
            DHSCChannelOpenTimeOut        = 'DistributedHealthScoreCache'
            # DistributedDbLevelFailoverCache
            DDBFCMaxConnectionsToServer   = 'DistributedDbLevelFailoverCache'
            DDBFCRequestTimeout           = 'DistributedDbLevelFailoverCache'
            DDBFCChannelOpenTimeOut       = 'DistributedDbLevelFailoverCache'
            # DistributedEdgeHeaderCache
            DEHCMaxConnectionsToServer    = 'DistributedEdgeHeaderCache'
            DEHCRequestTimeout            = 'DistributedEdgeHeaderCache'
            DEHCChannelOpenTimeOut        = 'DistributedEdgeHeaderCache'
            # DistributedFileStorePerformanceTraceCache
            DFSPTCMaxConnectionsToServer  = 'DistributedFileStorePerformanceTraceCache'
            DFSPTCRequestTimeout          = 'DistributedFileStorePerformanceTraceCache'
            DFSPTCChannelOpenTimeOut      = 'DistributedFileStorePerformanceTraceCache'
            # DistributedSPAbsBlobCache
            DSPABSCMaxConnectionsToServer = 'DistributedSPAbsBlobCache'
            MaxConnectionsToServer        = 'DistributedSPAbsBlobCache'
            DSPABSCChannelOpenTimeOut     = 'DistributedSPAbsBlobCache'
            # DistributedSPCertificateValidatorCache
            DSPCVCMaxConnectionsToServer  = 'DistributedSPCertificateValidatorCache'
            DSPCVCRequestTimeout          = 'DistributedSPCertificateValidatorCache'
            DSPCVCChannelOpenTimeOut      = 'DistributedSPCertificateValidatorCache'
            # DistributedSPOAuthTokenCache
            DSPOATCMaxConnectionsToServer = 'DistributedSPOAuthTokenCache'
            DSPOATCRequestTimeout         = 'DistributedSPOAuthTokenCache'
            DSPOATCChannelOpenTimeOut     = 'DistributedSPOAuthTokenCache'
            # DistributedStopgapCache
            DSGCMaxConnectionsToServer    = 'DistributedStopgapCache'
            DSGCRequestTimeout            = 'DistributedStopgapCache'
            DSGCChannelOpenTimeOut        = 'DistributedStopgapCache'
            # DistributedUnifiedAppsCache
            DUACMaxConnectionsToServer    = 'DistributedUnifiedAppsCache'
            DUACRequestTimeout            = 'DistributedUnifiedAppsCache'
            DUACChannelOpenTimeOut        = 'DistributedUnifiedAppsCache'
            # DistributedUnifiedAuditCache
            DUAuCMaxConnectionsToServer   = 'DistributedUnifiedAuditCache'
            DUAuCRequestTimeout           = 'DistributedUnifiedAuditCache'
            DUAuCChannelOpenTimeOut       = 'DistributedUnifiedAuditCache'
        }
        #endregion

        # Get available Cache Container Types
        $containerTypes = [Enum]::GetNames([Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheContainerType])

        foreach ($parameter in $parameterToContainerTypeMapping.Keys)
        {
            # Check if the Parameter has been used
            if ($params.ContainsKey($parameter))
            {
                # Container Type
                $containerType = $parameterToContainerTypeMapping."$parameter"
                # Test if Container Type is available
                if ($containerTypes -contains $containerType)
                {
                    # Get the Cache Settings
                    $cacheClientSetting = Get-SPDistributedCacheClientSetting -ContainerType $containerType
                    # Get the Client Settings Property Names
                    $cacheClientProperties = $cacheClientSetting | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
                    # Find a match
                    foreach ($item in $cacheClientProperties)
                    {
                        if ($parameter -like "*$item")
                        {
                            $cacheClientSetting."$item" = $params."$parameter"
                            Set-SPDistributedCacheClientSetting -ContainerType $containerType -DistributedCacheClientSettings $cacheClientSetting
                            Write-Verbose -Message "Setting $item to $($params."$parameter") on ContainerType $containerType" -InformationAction Continue
                        }
                    }
                }
                else
                {
                    Write-Warning -Message "This Farm does not have the Container Type $containerType which is needed to set the Parameter $parameter"
                }
            }
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
        [System.UInt32]
        $DDBFCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DDBFCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DDBFCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DEHCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DEHCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DEHCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DFSPTCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DFSPTCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DFSPTCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPABSCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPABSCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPABSCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPCVCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPCVCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPCVCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSPOATCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSPOATCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSPOATCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DSGCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DSGCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DSGCChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUACMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUACRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUACChannelOpenTimeOut,

        [Parameter()]
        [System.UInt32]
        $DUAuCMaxConnectionsToServer,

        [Parameter()]
        [System.UInt32]
        $DUAuCRequestTimeout,

        [Parameter()]
        [System.UInt32]
        $DUAuCChannelOpenTimeOut
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
        "DHSCChannelOpenTimeOut",
        'DDBFCMaxConnectionsToServer',
        'DDBFCRequestTimeout',
        'DDBFCChannelOpenTimeOut',
        'DEHCMaxConnectionsToServer',
        'DEHCRequestTimeout',
        'DEHCChannelOpenTimeOut',
        'DFSPTCMaxConnectionsToServer',
        'DFSPTCRequestTimeout',
        'DFSPTCChannelOpenTimeOut',
        'DSPABSCMaxConnectionsToServer',
        'DSPABSCRequestTimeout',
        'DSPABSCChannelOpenTimeOut',
        'DSPCVCMaxConnectionsToServer',
        'DSPCVCRequestTimeout',
        'DSPCVCChannelOpenTimeOut',
        'DSPOATCMaxConnectionsToServer',
        'DSPOATCRequestTimeout',
        'DSPOATCChannelOpenTimeOut',
        'DSGCMaxConnectionsToServer',
        'DSGCRequestTimeout',
        'DSGCChannelOpenTimeOut',
        'DUACMaxConnectionsToServer',
        'DUACRequestTimeout',
        'DUACChannelOpenTimeOut',
        'DUAuCMaxConnectionsToServer',
        'DUAuCRequestTimeout',
        'DUAuCChannelOpenTimeOut'
    )

    Write-Verbose -Message "Test-TargetResource returned $result"

    return $result
}

Export-ModuleMember -Function *-TargetResource
