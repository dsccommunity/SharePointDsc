
<#PSScriptInfo

.VERSION 1.0.0

.GUID 80d306fa-8bd4-4a8d-9f7a-bf40df95e661

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS

.LICENSEURI https://github.com/dsccommunity/SharePointDsc/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/SharePointDsc

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Updated author, copyright notice, and URLs.

.PRIVATEDATA

#>

<#

.DESCRIPTION
 This example configures the distributed cache client settings
 in SharePoint 2019.

#>

Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SetupAccount
    )

    Import-DscResource -ModuleName SharePointDsc

    node localhost
    {
        SPDistributedCacheClientSettings Settings
        {
            IsSingleInstance              = "Yes"
            DLTCMaxConnectionsToServer    = 3
            DLTCRequestTimeout            = 1000
            DLTCChannelOpenTimeOut        = 1000
            DVSCMaxConnectionsToServer    = 3
            DVSCRequestTimeout            = 1000
            DVSCChannelOpenTimeOut        = 1000
            DACMaxConnectionsToServer     = 3
            DACRequestTimeout             = 1000
            DACChannelOpenTimeOut         = 1000
            DAFMaxConnectionsToServer     = 3
            DAFRequestTimeout             = 1000
            DAFChannelOpenTimeOut         = 1000
            DAFCMaxConnectionsToServer    = 3
            DAFCRequestTimeout            = 1000
            DAFCChannelOpenTimeOut        = 1000
            DBCMaxConnectionsToServer     = 3
            DBCRequestTimeout             = 1000
            DBCChannelOpenTimeOut         = 1000
            DDCMaxConnectionsToServer     = 3
            DDCRequestTimeout             = 1000
            DDCChannelOpenTimeOut         = 1000
            DSCMaxConnectionsToServer     = 3
            DSCRequestTimeout             = 1000
            DSCChannelOpenTimeOut         = 1000
            DTCMaxConnectionsToServer     = 3
            DTCRequestTimeout             = 1000
            DTCChannelOpenTimeOut         = 1000
            DSTACMaxConnectionsToServer   = 3
            DSTACRequestTimeout           = 1000
            DSTACChannelOpenTimeOut       = 1000
            DFLTCMaxConnectionsToServer   = 3
            DFLTCRequestTimeout           = 1000
            DFLTCChannelOpenTimeOut       = 1000
            DSWUCMaxConnectionsToServer   = 3
            DSWUCRequestTimeout           = 1000
            DSWUCChannelOpenTimeOut       = 1000
            DUGCMaxConnectionsToServer    = 3
            DUGCRequestTimeout            = 1000
            DUGCChannelOpenTimeOut        = 1000
            DRTCMaxConnectionsToServer    = 3
            DRTCRequestTimeout            = 1000
            DRTCChannelOpenTimeOut        = 1000
            DHSCMaxConnectionsToServer    = 3
            DHSCRequestTimeout            = 1000
            DHSCChannelOpenTimeOut        = 1000
            DDBFCMaxConnectionsToServer   = 1
            DDBFCRequestTimeout           = 3000
            DDBFCChannelOpenTimeOut       = 3000
            DEHCMaxConnectionsToServer    = 1
            DEHCRequestTimeout            = 3000
            DEHCChannelOpenTimeOut        = 3000
            DFSPTCMaxConnectionsToServer  = 1
            DFSPTCRequestTimeout          = 3000
            DFSPTCChannelOpenTimeOut      = 3000
            DSPABSCMaxConnectionsToServer = 1
            DSPABSCRequestTimeout         = 3000
            DSPABSCChannelOpenTimeOut     = 3000
            DSPCVCMaxConnectionsToServer  = 1
            DSPCVCRequestTimeout          = 3000
            DSPCVCChannelOpenTimeOut      = 3000
            DSPOATCMaxConnectionsToServer = 1
            DSPOATCRequestTimeout         = 3000
            DSPOATCChannelOpenTimeOut     = 3000
            DSGCMaxConnectionsToServer    = 1
            DSGCRequestTimeout            = 3000
            DSGCChannelOpenTimeOut        = 3000
            DUACMaxConnectionsToServer    = 1
            DUACRequestTimeout            = 3000
            DUACChannelOpenTimeOut        = 3000
            DUAuCMaxConnectionsToServer   = 1
            DUAuCRequestTimeout           = 3000
            DUAuCChannelOpenTimeOut       = 3000
            PsDscRunAscredential          = $SetupAccount
        }
    }
}
