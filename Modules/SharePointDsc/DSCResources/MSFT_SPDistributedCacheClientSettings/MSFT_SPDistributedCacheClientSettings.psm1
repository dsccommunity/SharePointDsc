function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

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
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Getting the Distributed Cache Client Settings"

    $result = Invoke-SPDSCCommand -Credential $InstallAccount `
                                  -Arguments $PSBoundParameters `
                                  -ScriptBlock {
        $params = $args[0]

        $nullReturnValue = @{
            Ensure = "Absent"
            DLTCMaxConnectionsToServer = $null
            DLTCRequestTimeout = $null
            DLTCChannelOpenTimeOut = $null
            DVSCMaxConnectionsToServer = $null
            DVSCRequestTimeout = $null
            DVSCChannelOpenTimeOut = $null
            DACMaxConnectionsToServer = $null
            DACRequestTimeout = $null
            DACChannelOpenTimeOut = $null
            DAFMaxConnectionsToServer = $null
            DAFRequestTimeout = $null
            DAFChannelOpenTimeOut = $null
            DAFCMaxConnectionsToServer = $null
            DAFCRequestTimeout = $null
            DAFCChannelOpenTimeOut = $null
            DBCMaxConnectionsToServer = $null
            DBCRequestTimeout = $null
            DBCChannelOpenTimeOut = $null
            DDCMaxConnectionsToServer = $null
            DDCRequestTimeout = $null
            DDCChannelOpenTimeOut = $null
            DSCMaxConnectionsToServer = $null
            DSCRequestTimeout = $null
            DSCChannelOpenTimeOut = $null
            DTCMaxConnectionsToServer = $null
            DTCRequestTimeout = $null
            DTCChannelOpenTimeOut = $null
            DSTACMaxConnectionsToServer = $null
            DSTACRequestTimeout = $null
            DSTACChannelOpenTimeOut = $null
            InstallAccount = $params.InstallAccount
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

            $returnValue = @{
                Ensure = "Present"
                DLTCMaxConnectionsToServer = $DLTC.MaxConnectionsToServer
                DLTCRequestTimeout = $DLTC.RequestTimeout
                DLTCChannelOpenTimeOut = $DLTC.ChannelOpenTimeOut
                DVSCMaxConnectionsToServer = $DVSC.MaxConnectionsToServer
                DVSCRequestTimeout = $DVSC.RequestTimeout
                DVSCChannelOpenTimeOut = $DVSC.ChannelOpenTimeOut
                DACMaxConnectionsToServer = $DAC.MaxConnectionsToServer
                DACRequestTimeout = $DAC.RequestTimeout
                DACChannelOpenTimeOut = $DAC.ChannelOpenTimeOut
                DAFMaxConnectionsToServer = $DAF.MaxConnectionsToServer
                DAFRequestTimeout = $DAF.RequestTimeout
                DAFChannelOpenTimeOut = $DAF.ChannelOpenTimeOut
                DAFCMaxConnectionsToServer = $DAFC.MaxConnectionsToServer
                DAFCRequestTimeout = $DAFC.RequestTimeout
                DAFCChannelOpenTimeOut = $DAFC.ChannelOpenTimeOut
                DBCMaxConnectionsToServer = $DBC.MaxConnectionsToServer
                DBCRequestTimeout = $DBC.RequestTimeout
                DBCChannelOpenTimeOut = $DBC.ChannelOpenTimeOut
                DDCMaxConnectionsToServer = $DDC.MaxConnectionsToServer
                DDCRequestTimeout = $DDC.RequestTimeout
                DDCChannelOpenTimeOut = $DDC.ChannelOpenTimeOut
                DSCMaxConnectionsToServer = $DSC.MaxConnectionsToServer
                DSCRequestTimeout = $DSC.RequestTimeout
                DSCChannelOpenTimeOut = $DSC.ChannelOpenTimeOut
                DTCMaxConnectionsToServer = $DTC.MaxConnectionsToServer
                DTCRequestTimeout = $DTC.RequestTimeout
                DTCChannelOpenTimeOut = $DTC.ChannelOpenTimeOut
                DSTACMaxConnectionsToServer = $DSTAC.MaxConnectionsToServer
                DSTACRequestTimeout = $DSTAC.RequestTimeout
                DSTACChannelOpenTimeOut = $DSTAC.ChannelOpenTimeOut
                InstallAccount = $params.InstallAccount
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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

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
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Setting the Distributed Cache Client Settings"

    if ($Ensure -eq "Present")
    {
        Invoke-SPDSCCommand -Credential $InstallAccount `
                        -Arguments $PSBoundParameters `
                        -ScriptBlock {
            $params = $args[0]

            #DistributedLogonTokenCache
            $DLTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedLogonTokenCache"
            $DLTC.MaxConnectionsToServer = $params.DLTCMaxConnectionsToServer
            $DLTC.RequestTimeout = $params.DLTCRequestTimeout
            $DLTC.ChannelOpenTimeOut = $params.DLTCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedLogonTokenCache" $DLTC

            #DistributedViewStateCache
            $DVSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedViewStateCache"
            $DVSC.MaxConnectionsToServer = $params.DVSCMaxConnectionsToServer
            $DVSC.RequestTimeout = $params.DVSCRequestTimeout
            $DVSC.ChannelOpenTimeOut = $params.DVSCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedViewStateCache" $DVSC

            #DistributedAccessCache
            $DAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedAccessCache"
            $DAC.MaxConnectionsToServer = $params.DACMaxConnectionsToServer
            $DAC.RequestTimeout = $params.DACRequestTimeout
            $DAC.ChannelOpenTimeOut = $params.DACChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedAccessCache" $DAC

            #DistributedActivityFeedCache
            $DAF = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedCache"
            $DAF.MaxConnectionsToServer = $params.DAFMaxConnectionsToServer
            $DAF.RequestTimeout = $params.DAFRequestTimeout
            $DAF.ChannelOpenTimeOut = $params.DAFChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedCache" $DAF

            #DistributedActivityFeedLMTCache
            $DAFC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedLMTCache"
            $DAFC.MaxConnectionsToServer = $params.DAFCMaxConnectionsToServer
            $DAFC.RequestTimeout = $params.DAFCRequestTimeout
            $DAFC.ChannelOpenTimeOut = $params.DAFCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedActivityFeedLMTCache" $DAFC

            #DistributedBouncerCache
            $DBC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedBouncerCache"
            $DBC.MaxConnectionsToServer = $params.DBCMaxConnectionsToServer
            $DBC.RequestTimeout = $params.DBCRequestTimeout
            $DBC.ChannelOpenTimeOut = $params.DBCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedBouncerCache" $DBC

            #DistributedDefaultCache
            $DDC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedDefaultCache"
            $DDC.MaxConnectionsToServer = $params.DDCMaxConnectionsToServer
            $DDC.RequestTimeout = $params.DDCRequestTimeout
            $DDC.ChannelOpenTimeOut = $params.DDCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedDefaultCache" $DDC

            #DistributedSearchCache
            $DSC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSearchCache"
            $DSC.MaxConnectionsToServer = $params.DSCMaxConnectionsToServer
            $DSC.RequestTimeout = $params.DSCRequestTimeout
            $DSC.ChannelOpenTimeOut = $params.DSCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedSearchCache" $DSC

            #DistributedSecurityTrimmingCache
            $DTC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedSecurityTrimmingCache"
            $DTC.MaxConnectionsToServer = $params.DTCMaxConnectionsToServer
            $DTC.RequestTimeout = $params.DTCRequestTimeout
            $DTC.ChannelOpenTimeOut = $params.DTCChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedSecurityTrimmingCache" $DTC

            #DistributedServerToAppServerAccessTokenCache
            $DSTAC = Get-SPDistributedCacheClientSetting -ContainerType "DistributedServerToAppServerAccessTokenCache"
            $DSTAC.MaxConnectionsToServer = $params.DSTACMaxConnectionsToServer
            $DSTAC.RequestTimeout = $params.DSTACRequestTimeout
            $DSTAC.ChannelOpenTimeOut = $params.DSTACChannelOpenTimeOut
            Set-SPDistributedCacheClientSetting -ContainerType "DistributedServerToAppServerAccessTokenCache" $DSTAC
        }
    }
    else
    {
        throw "The SPDistributedCacheClientSettings resource only supports Ensure='Present'."
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

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
        [System.Management.Automation.PSCredential]
        $InstallAccount
    )

    Write-Verbose -Message "Testing the Distributed Cache Client Settings"

    $PSBoundParameters.Ensure = $Ensure

    $CurrentValues = Get-TargetResource @PSBoundParameters

    return Test-SPDscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters `
                                    -ValuesToCheck @("Ensure")
}

Export-ModuleMember -Function *-TargetResource
