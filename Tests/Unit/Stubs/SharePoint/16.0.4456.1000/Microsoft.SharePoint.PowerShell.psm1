function Add-DatabaseToAvailabilityGroup { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${AGName},

    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='AllDatabases', Mandatory=$true)]
    [switch]
    ${ProcessAllDatabases},

    [string]
    ${FileShare},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPAppDeniedEndpoint { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Endpoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPClaimTypeMapping { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${TrustedIdentityTokenIssuer},

    [ValidateNotNull()]
    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPDiagnosticsPerformanceCounter { 
  [CmdletBinding(DefaultParameterSetName='AddCounter', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AddMultipleCounters', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddCounter', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddInstance', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Category},

    [Parameter(ParameterSetName='AddInstance', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddCounter', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Counter},

    [Parameter(ParameterSetName='AddMultipleCounters', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [string[]]
    ${CounterList},

    [Parameter(ParameterSetName='AddInstance', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddMultipleCounters', ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Instance},

    [Parameter(ParameterSetName='AddMultipleCounters', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddCounter', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddInstance', ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${WebFrontEnd},

    [Parameter(ParameterSetName='AddMultipleCounters', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddCounter', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddInstance', ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${DatabaseServer},

    [Parameter(ParameterSetName='AddCounter', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddMultipleCounters', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='AddInstance', ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${AllInstances},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPDistributedCacheServiceInstance { 
  [CmdletBinding(DefaultParameterSetName='NoArgumentsDefaultSet')]
param(
    [Parameter(ParameterSetName='LocalServerRoleSet')]
    [ValidateSet('DistributedCache','SingleServerFarm','WebFrontEndWithDistributedCache')]
    [object]
    ${Role},

    [Parameter(ParameterSetName='CacheSizeSet')]
    [ValidateRange(1, 2147483647)]
    [int]
    ${CacheSizeInMB},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPInfoPathUserAgent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPPluggableSecurityTrimmer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNull()]
    [guid]
    ${UserProfileApplicationProxyId},

    [Parameter(Mandatory=$true)]
    [int]
    ${PlugInId},

    [string]
    ${QualifiedTypeName},

    [System.Collections.Specialized.NameValueCollection]
    ${CustomProperties},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPProfileLeader { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPProfileSyncConnection { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionForestName},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionDomain},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionUserName},

    [Parameter(Mandatory=$true)]
    [securestring]
    ${ConnectionPassword},

    [string]
    ${ConnectionServerName},

    [int]
    ${ConnectionPort},

    [bool]
    ${ConnectionUseSSL},

    [bool]
    ${ConnectionUseDisabledFilter},

    [string]
    ${ConnectionNamingContext},

    [string]
    ${ConnectionSynchronizationOU},

    [string]
    ${ConnectionClaimProviderTypeValue},

    [string]
    ${ConnectionClaimProviderIdValue},

    [string]
    ${ConnectionClaimIDMapAttribute},

    [bool]
    ${ConnectionFilterOutUnlicensed},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPRoutingMachineInfo { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${RequestManagementSettings},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${Availability},

    [ValidateNotNull()]
    [object]
    ${OutgoingScheme},

    [System.Nullable[int]]
    ${OutgoingPort},

    [ValidateNotNull()]
    [System.Nullable[double]]
    ${StaticWeight},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPRoutingMachinePool { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${RequestManagementSettings},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${MachineTargets},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPRoutingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${RequestManagementSettings},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${Criteria},

    [object]
    ${MachinePool},

    [ValidateNotNull()]
    [System.Nullable[int]]
    ${ExecutionGroup},

    [ValidateNotNull()]
    [System.Nullable[datetime]]
    ${Expiration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseFailoverServer},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPSecureStoreSystemAccount { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${AccountName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPServerScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseFailoverServer},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPServiceApplicationProxyGroupMember { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [Alias('Proxy')]
    [ValidateNotNull()]
    [object]
    ${Member},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPShellAdmin { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${UserName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${database},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPSiteSubscriptionFeaturePackMember { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${FeatureDefinition},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPSiteSubscriptionProfileConfig { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='MySiteSettings', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${MySiteHostLocation},

    [Parameter(ParameterSetName='MySiteSettings', ValueFromPipeline=$true)]
    [object]
    ${MySiteManagedPath},

    [Parameter(ParameterSetName='MySiteSettings')]
    [ValidateSet('None','Resolve','Block')]
    [string]
    ${SiteNamingConflictResolution},

    [string]
    ${SynchronizationOU},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${LiteralPath},

    [uint32]
    ${Language},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPThrottlingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${RequestManagementSettings},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${Criteria},

    [ValidateRange(0, 10)]
    [ValidateNotNull()]
    [System.Nullable[int]]
    ${Threshold},

    [ValidateNotNull()]
    [System.Nullable[datetime]]
    ${Expiration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPUserLicenseMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ValueFromRemainingArguments=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Mapping},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Add-SPUserSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${LiteralPath},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Backup-SPConfigurationDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet')]
param(
    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ParameterSetName='DefaultSet', Mandatory=$true)]
    [string]
    ${Directory},

    [string]
    ${Item},

    [Parameter(ParameterSetName='ShowTree', Mandatory=$true)]
    [switch]
    ${ShowTree},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Backup-SPEnterpriseSearchServiceApplicationIndex { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='RunBackup', Mandatory=$true, Position=0)]
    [int]
    ${Phase},

    [Parameter(ParameterSetName='AbortBackup', Mandatory=$true, Position=0)]
    [switch]
    ${Abort},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ParameterSetName='RunBackup', Mandatory=$true, Position=2)]
    [string]
    ${BackupFolder},

    [Parameter(Mandatory=$true, Position=3)]
    [string]
    ${BackupHandleFile},

    [Parameter(Position=4)]
    [int]
    ${Retries},

    [Parameter(Position=5)]
    [switch]
    ${PeerToPeer},

    [Parameter(Position=6)]
    [string]
    ${SpecifiedBackupHandle},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Backup-SPFarm { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='DefaultSet', Mandatory=$true)]
    [string]
    ${Directory},

    [Parameter(ParameterSetName='DefaultSet', Mandatory=$true)]
    [ValidateSet('Full','Differential','None')]
    [string]
    ${BackupMethod},

    [Parameter(ParameterSetName='DefaultSet')]
    [int]
    ${BackupThreads},

    [Parameter(ParameterSetName='DefaultSet')]
    [switch]
    ${Force},

    [string]
    ${Item},

    [Parameter(ParameterSetName='ShowTree', Mandatory=$true)]
    [switch]
    ${ShowTree},

    [switch]
    ${ConfigurationOnly},

    [Parameter(ParameterSetName='DefaultSet')]
    [int]
    ${Percentage},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Backup-SPSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [string]
    ${Path},

    [switch]
    ${Force},

    [switch]
    ${UseSqlSnapshot},

    [switch]
    ${NoSiteLock},

    [switch]
    ${UseABSDocStreamInfo},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPAppDeniedEndpointList { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPBusinessDataCatalogEntityNotificationWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPDistributedCacheItem { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ContainerType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPLogLevel { 
  [CmdletBinding()]
param(
    [string[]]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPMetadataWebServicePartitionData { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(ParameterSetName='Default', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceProxy},

    [Parameter(ParameterSetName='ServiceContext', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [switch]
    ${FromServiceDatabase},

    [ValidateNotNull()]
    [object]
    ${FromContentDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPPerformancePointServiceApplicationTrustedLocation { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [object]
    ${TrustedLocationType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPScaleOutDatabaseDeletedDataSubRange { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Range},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPScaleOutDatabaseLog { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [int]
    ${LogEntryTimeout},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPSecureStoreCredentialMapping { 
  [CmdletBinding(DefaultParameterSetName='OneApplication', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='AllApplications', Mandatory=$true)]
    [switch]
    ${All},

    [Parameter(ParameterSetName='OneApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(ParameterSetName='AllApplications', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPSecureStoreDefaultProvider { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPServerScaleOutDatabaseDeletedDataSubRange { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Range},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPServerScaleOutDatabaseLog { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [int]
    ${LogEntryTimeout},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPServerScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Clear-SPSiteSubscriptionBusinessDataCatalogConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Connect-SPConfigurationDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${DatabaseName},

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(Mandatory=$true, Position=8, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [securestring]
    ${Passphrase},

    [Parameter(Position=9, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${SkipRegisterAsDistributedCacheHost},

    [string]
    ${DatabaseFailOverPartner},

    [ValidateSet('Application','ApplicationWithSearch','Custom','DistributedCache','Search','SingleServerFarm','WebFrontEnd','WebFrontEndWithDistributedCache')]
    [object]
    ${LocalServerRole},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Convert-SPWebApplication { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='Claims', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Claims', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateSet('LEGACY','CLAIMS-WINDOWS','CLAIMS-TRUSTED-DEFAULT')]
    [string]
    ${From},

    [Parameter(ParameterSetName='Claims', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateSet('CLAIMS','CLAIMS-WINDOWS','CLAIMS-TRUSTED-DEFAULT','CLAIMS-SHAREPOINT-ONLINE')]
    [string]
    ${To},

    [Parameter(ParameterSetName='Claims')]
    [switch]
    ${Force},

    [Parameter(ParameterSetName='Claims')]
    [switch]
    ${RetainPermissions},

    [Parameter(ParameterSetName='Claims')]
    [string]
    ${SourceSkipList},

    [Parameter(ParameterSetName='Claims')]
    [string]
    ${MapList},

    [Parameter(ParameterSetName='Claims')]
    [switch]
    ${SkipSites},

    [Parameter(ParameterSetName='Claims')]
    [switch]
    ${SkipPolicies},

    [Parameter(ParameterSetName='Claims')]
    [object]
    ${Database},

    [Parameter(ParameterSetName='Claims')]
    [object]
    ${TrustedProvider},

    [Parameter(ParameterSetName='Claims')]
    [guid]
    ${SiteSubsriptionId},

    [Parameter(ParameterSetName='Claims')]
    [string]
    ${LoggingDirectory},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPAccessServicesDatabaseCredentials { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${AppUrl},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [string]
    ${SourceServer},

    [Parameter(Mandatory=$true)]
    [string]
    ${TargetServer},

    [Parameter(Mandatory=$true)]
    [System.Net.NetworkCredential]
    ${ServerCredential},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPActivitiesToWorkflowService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${WorkflowServiceAddress},

    [string]
    ${ActivityName},

    [System.Net.ICredentials]
    ${Credential},

    [bool]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPBusinessDataCatalogAclToChildren { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${MetadataObject},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPSideBySideFiles { 
  [CmdletBinding()]
param(
    [string]
    ${LogFile},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPSite { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [object]
    ${DestinationDatabase},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [string]
    ${TargetUrl},

    [string]
    ${HostHeaderWebApplication},

    [switch]
    ${PreserveSiteId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Copy-SPTaxonomyGroups { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${LocalTermStoreName},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [uri]
    ${RemoteSiteUrl},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [uri]
    ${LocalSiteUrl},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${GroupNames},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${Credential},

    [string]
    ${AuthEndpoint},

    [string]
    ${GraphApiEndpoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-ProjectServerLicense { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPAppAutoProvision { 
  [CmdletBinding()]
param(
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPBusinessDataCatalogEntity { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPFeature { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Url},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPHealthAnalysisRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('Url')]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPProjectActiveDirectoryEnterpriseResourcePoolSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPProjectEmailNotification { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPProjectEnterpriseProjectTaskSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPProjectQueueStatsMonitoring { 
  [CmdletBinding(DefaultParameterSetName='__AllParameterSets')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPSessionStateService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPSingleSignOn { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServerName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPTimerJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPUserLicensing { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPUserSolutionAllowList { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPWebApplicationHttpThrottling { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disable-SPWebTemplateForSiteMaster { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${Template},

    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Disconnect-SPConfigurationDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Dismount-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Dismount-SPSiteMapDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [guid]
    ${DatabaseId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Dismount-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-ProjectServerLicense { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Key},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPAppAutoProvision { 
  [CmdletBinding()]
param(
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPBusinessDataCatalogEntity { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPFeature { 
  [CmdletBinding(DefaultParameterSetName='FarmFeatureDefinition', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SiteFeature')]
    [string]
    ${Url},

    [switch]
    ${PassThru},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='FarmFeatureDefinition')]
    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPHealthAnalysisRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('url')]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPProjectActiveDirectoryEnterpriseResourcePoolSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Generic.IEnumerable[guid]]
    ${GroupUids},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPProjectEmailNotification { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPProjectEnterpriseProjectTaskSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPProjectQueueStatsMonitoring { 
  [CmdletBinding(DefaultParameterSetName='__AllParameterSets')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPSessionStateService { 
  [CmdletBinding(DefaultParameterSetName='AdvancedProvision', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='DefaultProvision', Mandatory=$true)]
    [switch]
    ${DefaultProvision},

    [Parameter(ParameterSetName='AdvancedProvision')]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='AdvancedProvision', Mandatory=$true)]
    [string]
    ${DatabaseName},

    [System.Nullable[int]]
    ${SessionTimeout},

    [Parameter(ParameterSetName='AdvancedProvision')]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPTimerJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPUserLicensing { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPUserSolutionAllowList { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPWebApplicationHttpThrottling { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Enable-SPWebTemplateForSiteMaster { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${Template},

    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPAccessServicesDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [guid]
    ${ServerReferenceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPAppPackage { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${App},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPBusinessDataCatalogModel { 
  [CmdletBinding()]
param(
    [switch]
    ${ModelsIncluded},

    [switch]
    ${LocalizedNamesIncluded},

    [switch]
    ${PropertiesIncluded},

    [switch]
    ${ProxiesIncluded},

    [switch]
    ${PermissionsIncluded},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [string]
    ${SettingId},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPEnterpriseSearchTopology { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${Filename},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPInfoPathAdministrationFiles { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Path},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPMetadataWebServicePartitionData { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceProxy},

    [switch]
    ${NoCompression},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPPerformancePointContent { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${ExportFileUrl},

    [Parameter(Mandatory=$true)]
    [array]
    ${ItemUrls},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${FilePath},

    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPServerScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${FilePath},

    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPSiteSubscriptionBusinessDataCatalogConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [switch]
    ${Force},

    [switch]
    ${ModelsIncluded},

    [switch]
    ${LocalizedNamesIncluded},

    [switch]
    ${PropertiesIncluded},

    [switch]
    ${ProxiesIncluded},

    [switch]
    ${PermissionsIncluded},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPSiteSubscriptionSettings { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [switch]
    ${AdminProperties},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPTagsAndNotesData { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${FilePath},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Export-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${IncludeAlerts},

    [object]
    ${IncludeVersions},

    [int]
    ${CompressionSize},

    [switch]
    ${UseSqlSnapshot},

    [string]
    ${AppLogFilePath},

    [string]
    ${ItemUrl},

    [Parameter(Mandatory=$true)]
    [string]
    ${Path},

    [switch]
    ${Force},

    [switch]
    ${IncludeUserSecurity},

    [switch]
    ${HaltOnWarning},

    [switch]
    ${HaltOnError},

    [switch]
    ${NoLogFile},

    [switch]
    ${NoFileCompression},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-AvailabilityGroupStatus { 
  [CmdletBinding()]
param(
    [string]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-ProjectServerLicense { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServicesApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServicesDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Position=1, ValueFromPipeline=$true)]
    [object]
    ${ContentDb},

    [Parameter(Position=2, ValueFromPipeline=$true)]
    [bool]
    ${AccessAppsOnly},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServicesDatabaseServer { 
  [CmdletBinding(DefaultParameterSetName='GetDatabaseServersParameterSet')]
param(
    [Parameter(ParameterSetName='GetDatabaseServersParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='GetSingleDatabaseServerParamterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='GetDatabaseServersParameterSet')]
    [Parameter(ParameterSetName='GetSingleDatabaseServerParamterSet', Mandatory=$true)]
    [object]
    ${DatabaseServerGroup},

    [Parameter(ParameterSetName='GetSingleDatabaseServerParamterSet', Mandatory=$true)]
    [object]
    ${DatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServicesDatabaseServerGroup { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(Position=1, ValueFromPipeline=$true)]
    [object]
    ${DatabaseServerGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAccessServicesDatabaseServerGroupMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAlternateURL { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [object]
    ${Zone},

    [Parameter(ParameterSetName='ResourceName', Mandatory=$true)]
    [string]
    ${ResourceName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppAcquisitionConfiguration { 
  [CmdletBinding(DefaultParameterSetName='MarketplaceSettingsInWebApplication')]
param(
    [Parameter(ParameterSetName='MarketplaceSettingsInWebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='MarketplaceSettingsInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppAutoProvisionConnection { 
  [CmdletBinding()]
param(
    [object]
    ${SiteSubscription},

    [object]
    ${ConnectionType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppDeniedEndpointList { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppDisablingConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppDomain { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppHostingQuotaConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppInstance { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='IdentityParameterSet', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='WebParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [Parameter(ParameterSetName='WebParameterSet')]
    [ValidateNotNull()]
    [object]
    ${App},

    [Parameter(ParameterSetName='SiteAndIdParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(ParameterSetName='SiteAndIdParameterSet', Mandatory=$true)]
    [guid]
    ${AppInstanceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppPrincipal { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NameIdentifier},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppScaleProfile { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppSiteSubscriptionName { 
  [CmdletBinding()]
param(
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppStateSyncLastRunTime { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppStateUpdateInterval { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppStoreConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAppStoreWebServiceConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAuthenticationProvider { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(Mandatory=$true, Position=2)]
    [object]
    ${Zone},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPAuthenticationRealm { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBackupHistory { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Directory},

    [switch]
    ${ShowBackup},

    [switch]
    ${ShowRestore},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBingMapsBlock { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBingMapsKey { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBrowserCustomerExperienceImprovementProgram { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='Farm', Mandatory=$true)]
    [switch]
    ${Farm},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='SiteSubscription', Mandatory=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBusinessDataCatalogEntityNotificationWeb { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBusinessDataCatalogMetadataObject { 
  [CmdletBinding()]
param(
    [string]
    ${Namespace},

    [string]
    ${Name},

    [string]
    ${ContainingLobSystem},

    [Parameter(Mandatory=$true)]
    [object]
    ${BdcObjectType},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPBusinessDataCatalogThrottleConfig { 
  [CmdletBinding(DefaultParameterSetName='ProxyProvided')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${Scope},

    [Parameter(Mandatory=$true)]
    [object]
    ${ThrottleType},

    [Parameter(ParameterSetName='ProxyProvided', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceApplicationProxy},

    [Parameter(ParameterSetName='FileBackedProvided', Mandatory=$true)]
    [switch]
    ${FileBacked},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPCertificateAuthority { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPClaimProvider { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPClaimProviderManager { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPClaimTypeEncoding { 
  [CmdletBinding()]
param(
    [char]
    ${EncodingCharacter},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ClaimType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPConnectedServiceApplicationInformation { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet')]
param(
    [Parameter(ParameterSetName='DefaultSet', Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='AllContentDatabasesInWebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='ContentDatabasesOfSite', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(ParameterSetName='Unattached', Mandatory=$true)]
    [switch]
    ${ConnectAsUnattachedDatabase},

    [Parameter(ParameterSetName='Unattached')]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ParameterSetName='Unattached', Mandatory=$true)]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='Unattached', Mandatory=$true)]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='AllContentDatabasesInWebApplication')]
    [Parameter(ParameterSetName='DefaultSet')]
    [switch]
    ${NoStatusFilter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPContentDeploymentJob { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Path},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPContentDeploymentPath { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPCustomLayoutsPage { 
  [CmdletBinding()]
param(
    [object]
    ${Identity},

    [ValidateRange(14, 15)]
    [int]
    ${CompatibilityLevel},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultParameterSet')]
param(
    [Parameter(ParameterSetName='DefaultParameterSet', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='ServerParameterSet', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServerInstance},

    [Parameter(ParameterSetName='NameParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDataConnectionFile { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDataConnectionFileDependent { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDeletedSite { 
  [CmdletBinding(DefaultParameterSetName='AllDeletedSitesInWebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AllDeletedSitesInIdentity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Limit},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [string]
    ${DateTimeFrom},

    [string]
    ${DateTimeTo},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDesignerSettings { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDiagnosticConfig { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDiagnosticsPerformanceCounter { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [switch]
    ${WebFrontEnd},

    [Parameter(ValueFromPipeline=$true)]
    [switch]
    ${DatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDiagnosticsProvider { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPDistributedCacheClientSetting { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ContainerType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchAdministrationComponent { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchComponent { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchContentEnrichmentConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlContentSource { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlCustomConnector { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SearchApplication},

    [string]
    ${Protocol},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlExtension { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlLogReadPermission { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SearchApplication},

    [guid]
    ${Tenant},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlMapping { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchCrawlRule { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchFileFormat { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchHostController { 
  [CmdletBinding()]
param(
    [object]
    ${SearchServiceInstance},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchLanguageResourcePhrase { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [object]
    ${Type},

    [string]
    ${Language},

    [string]
    ${Mapping},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [guid]
    ${SourceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchLinguisticComponentsStatus { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchLinksDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchMetadataCategory { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchMetadataCrawledProperty { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Alias('p')]
    [System.Nullable[guid]]
    ${PropSet},

    [Alias('vt')]
    [Obsolete()]
    [System.Nullable[int]]
    ${VariantType},

    [Alias('c')]
    [object]
    ${Category},

    [string]
    ${Limit},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchMetadataManagedProperty { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [string]
    ${Limit},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchMetadataMapping { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [object]
    ${ManagedProperty},

    [object]
    ${CrawledProperty},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchOwner { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [Alias('l')]
    [object]
    ${Level},

    [object]
    ${SPWeb},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchPropertyRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${PropertyName},

    [Parameter(Mandatory=$true, Position=1)]
    [object]
    ${Operator},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchPropertyRuleCollection { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryAndSiteSettingsService { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [switch]
    ${Local},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryAndSiteSettingsServiceProxy { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryAuthority { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryDemoted { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryKeyword { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryScope { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Alias('u')]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQueryScopeRule { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [uri]
    ${Url},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Alias('n')]
    [object]
    ${Scope},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQuerySpellingCorrection { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchQuerySuggestionCandidates { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [guid]
    ${SourceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchRankingModel { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchResultItemType { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplicationProxy},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchResultSource { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchSecurityTrimmer { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchService { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchServiceApplicationBackupStore { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${BackupFolder},

    [Parameter(Mandatory=$true, Position=1)]
    [string]
    ${Name},

    [Parameter(Position=3, ValueFromPipeline=$true)]
    [string]
    ${BackupId},

    [Parameter(Position=4)]
    [switch]
    ${UseMostRecent},

    [Parameter(Position=5)]
    [switch]
    ${IsVerbose},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchServiceInstance { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [switch]
    ${Local},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchSiteHitRule { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchService},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchStatus { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [switch]
    ${Primary},

    [switch]
    ${Text},

    [switch]
    ${Detailed},

    [switch]
    ${Constellation},

    [switch]
    ${JobStatus},

    [switch]
    ${HealthReport},

    [switch]
    ${DetailSearchRuntime},

    [string]
    ${Component},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchTopology { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [switch]
    ${Active},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPEnterpriseSearchVssDataPath { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPFarm { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPFarmConfig { 
  [CmdletBinding()]
param(
    [switch]
    ${ServiceConnectionPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPFeature { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='FarmFeatures')]
    [switch]
    ${Farm},

    [Parameter(ParameterSetName='SiteFeatures')]
    [object]
    ${Site},

    [Parameter(ParameterSetName='WebFeatures')]
    [object]
    ${Web},

    [Parameter(ParameterSetName='WebApplicationFeatures')]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='SiteFeatures')]
    [switch]
    ${Sandboxed},

    [string]
    ${Limit},

    [Parameter(ParameterSetName='FarmFeatureDefinitions')]
    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPHealthAnalysisRule { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(ParameterSetName='SpecificRule', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPHelpCollection { 
  [CmdletBinding()]
param(
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInfoPathFormsService { 
  [CmdletBinding()]
param(
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInfoPathFormTemplate { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInfoPathUserAgent { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInfoPathWebServiceProxy { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInsightsConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInternalAppStateSyncLastRunTime { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPInternalAppStateUpdateInterval { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPIRMSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPLogEvent { 
  [CmdletBinding(DefaultParameterSetName='Directory')]
param(
    [Parameter(ParameterSetName='Directory')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Directory},

    [Parameter(ParameterSetName='File')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${File},

    [switch]
    ${AsString},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${ContextKey},

    [datetime]
    ${StartTime},

    [datetime]
    ${EndTime},

    [ValidateNotNullOrEmpty()]
    [string]
    ${MinimumLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPLogLevel { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [string[]]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPManagedAccount { 
  [CmdletBinding(DefaultParameterSetName='Service')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Service', ValueFromPipeline=$true)]
    [object]
    ${Service},

    [Parameter(ParameterSetName='WebApplication', ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='Server', ValueFromPipeline=$true)]
    [object]
    ${Server},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPManagedPath { 
  [CmdletBinding(DefaultParameterSetName='WebApplication')]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='HostHeader', Mandatory=$true)]
    [switch]
    ${HostHeader},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPMetadataServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPMetadataServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPMicrofeedOptions { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPMobileMessagingAccount { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [Alias('ServiceType','AccountType')]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPO365LinkSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPODataConnectionSetting { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [ValidateNotNull()]
    [ValidateLength(0, 246)]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPODataConnectionSettingMetadata { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [ValidateLength(0, 255)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPOfficeStoreAppsDefaultActivation { 
  [CmdletBinding(DefaultParameterSetName='AppsForOfficeSettingsInWebApplication')]
param(
    [Parameter(ParameterSetName='AppsForOfficeSettingsInWebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='AppsForOfficeSettingsInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPPendingUpgradeActions { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${RootObject},

    [switch]
    ${Recursive},

    [switch]
    ${SkipSiteUpgradeActionInfo},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPPerformancePointServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPPerformancePointServiceApplicationTrustedLocation { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPPluggableSecurityTrimmer { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNull()]
    [guid]
    ${UserProfileApplicationProxyId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProcessAccount { 
  [CmdletBinding(DefaultParameterSetName='NetworkService')]
param(
    [Parameter(ParameterSetName='NetworkService')]
    [switch]
    ${NetworkService},

    [Parameter(ParameterSetName='LocalSystem')]
    [switch]
    ${LocalSystem},

    [Parameter(ParameterSetName='LocalService')]
    [switch]
    ${LocalService},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProduct { 
  [CmdletBinding(DefaultParameterSetName='Local')]
param(
    [Parameter(ParameterSetName='Server', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Server},

    [Parameter(ParameterSetName='Local')]
    [switch]
    ${Local},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProfileLeader { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProfileServiceApplicationSecurity { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [ValidateSet('UserACL','MySiteReaderACL')]
    [string]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectDatabaseQuota { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectDatabaseUsage { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectEnterpriseProjectTaskSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectEventServiceSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectIsEmailNotificationEnabled { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectOdataConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectPCSSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectPermissionMode { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectQueueSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPProjectWebInstance { 
  [CmdletBinding()]
param(
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPRequestManagementSettings { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPRoutingMachineInfo { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${RequestManagementSettings},

    [ValidateNotNull()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${Availability},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPRoutingMachinePool { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${RequestManagementSettings},

    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPRoutingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${RequestManagementSettings},

    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPScaleOutDatabaseDataState { 
  [CmdletBinding(DefaultParameterSetName='AttachedDatabase', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AttachedDatabase', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(ParameterSetName='UnattachedDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ConnectionString},

    [Parameter(ParameterSetName='UnattachedDatabase')]
    [switch]
    ${IsAzureDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPScaleOutDatabaseInconsistency { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPScaleOutDatabaseLogEntry { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [int]
    ${Count},

    [object]
    ${MajorAction},

    [System.Nullable[guid]]
    ${CorrelationId},

    [byte[]]
    ${RangeLimitPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSecureStoreApplication { 
  [CmdletBinding(DefaultParameterSetName='NameSet')]
param(
    [Parameter(ParameterSetName='AllSet', Mandatory=$true)]
    [switch]
    ${All},

    [Parameter(ParameterSetName='NameSet', Mandatory=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSecureStoreSystemAccount { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSecurityTokenServiceConfig { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServer { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Alias('Address')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServerScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServerScaleOutDatabaseDataState { 
  [CmdletBinding(DefaultParameterSetName='AttachedDatabase', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AttachedDatabase', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(ParameterSetName='UnattachedDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ConnectionString},

    [Parameter(ParameterSetName='UnattachedDatabase')]
    [switch]
    ${IsAzureDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServerScaleOutDatabaseInconsistency { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServerScaleOutDatabaseLogEntry { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [int]
    ${Count},

    [object]
    ${MajorAction},

    [System.Nullable[guid]]
    ${CorrelationId},

    [byte[]]
    ${RangeLimitPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPService { 
  [CmdletBinding(DefaultParameterSetName='Identity')]
param(
    [Parameter(ParameterSetName='Identity', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${All},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplicationEndpoint { 
  [CmdletBinding(DefaultParameterSetName='Identity')]
param(
    [Parameter(ParameterSetName='Identity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Name', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ParameterSetName='Name')]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplicationPool { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplicationProxyGroup { 
  [CmdletBinding(DefaultParameterSetName='Identity')]
param(
    [Parameter(ParameterSetName='Identity', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Default identity', Mandatory=$true)]
    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceApplicationSecurity { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [switch]
    ${Admin},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceContext { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='Site', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Site},

    [Parameter(ParameterSetName='SiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceHostConfig { 
  [CmdletBinding()]
param(
    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPServiceInstance { 
  [CmdletBinding(DefaultParameterSetName='Identity')]
param(
    [Parameter(ParameterSetName='Identity', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Server', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Server},

    [switch]
    ${All},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSessionStateService { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPShellAdmin { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${database},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSite { 
  [CmdletBinding(DefaultParameterSetName='AllSitesInWebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AllSitesInIdentity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Limit},

    [Parameter(ParameterSetName='AllSitesInContentDB', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ParameterSetName='AllSitesInContentDB')]
    [switch]
    ${NeedsB2BUpgrade},

    [Parameter(ParameterSetName='AllSitesInWebApplication', ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='AllSitesInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='AllSitesInIdentity')]
    [switch]
    ${Regex},

    [scriptblock]
    ${Filter},

    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteAdministration { 
  [CmdletBinding(DefaultParameterSetName='AllSitesInWebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AllSitesInIdentity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Limit},

    [Parameter(ParameterSetName='AllSitesInContentDB', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ParameterSetName='AllSitesInWebApplication', ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='AllSitesInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='AllSitesInIdentity')]
    [switch]
    ${Regex},

    [scriptblock]
    ${Filter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteMapDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteMaster { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscription { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionConfig { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionEdiscoveryHub { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionEdiscoverySearchScope { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionFeaturePack { 
  [CmdletBinding(DefaultParameterSetName='FeaturePack')]
param(
    [Parameter(ParameterSetName='FeaturePack', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SiteSubscription', ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionIRMConfig { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteSubscriptionMetadataConfig { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteUpgradeSessionInfo { 
  [CmdletBinding(DefaultParameterSetName='ContentDB')]
param(
    [Parameter(ParameterSetName='Site', Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ParameterSetName='ContentDB', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ParameterSetName='ContentDB')]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='ContentDB')]
    [switch]
    ${HideWaiting},

    [Parameter(ParameterSetName='ContentDB')]
    [switch]
    ${ShowInProgress},

    [Parameter(ParameterSetName='ContentDB')]
    [switch]
    ${ShowCompleted},

    [Parameter(ParameterSetName='ContentDB')]
    [switch]
    ${ShowFailed},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSiteURL { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPSolution { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPStateServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPStateServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPStateServiceDatabase { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Default', Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='ServiceApplication', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('Application')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTaxonomySession { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPThrottlingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${RequestManagementSettings},

    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTimerJob { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTopologyServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTopologyServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTranslationThrottlingSetting { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [object]
    ${Farm},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTrustedIdentityTokenIssuer { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTrustedRootAuthority { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTrustedSecurityTokenIssuer { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPTrustedServiceTokenIssuer { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUpgradeActions { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUsageApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${UsageService},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUsageDefinition { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUsageService { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUser { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [Alias('UserAlias')]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [object]
    ${Group},

    [string]
    ${Limit},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserLicense { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserLicenseMapping { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='WebApplication', ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserLicensing { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserSettingsProvider { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserSettingsProviderManager { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserSolution { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPUserSolutionAllowList { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPVisioExternalData { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPVisioPerformance { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPVisioSafeDataProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [string]
    ${DataProviderId},

    [int]
    ${DataProviderType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPVisioServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPVisioServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Site},

    [string]
    ${Limit},

    [switch]
    ${Regex},

    [scriptblock]
    ${Filter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebApplication { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${IncludeCentralAdministration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebApplicationAppDomain { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='ResourceName', Mandatory=$true)]
    [string]
    ${AppDomain},

    [object]
    ${Zone},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebApplicationHttpThrottlingMonitor { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebPartPack { 
  [CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [switch]
    ${GlobalOnly},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebTemplate { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [uint32]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWebTemplatesEnabledForSiteMaster { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWOPIBinding { 
  [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    ${Application},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Action},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Extension},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ProgId},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Server},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${WOPIZone},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWOPISuppressionSetting { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWOPIZone { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWorkflowConfig { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='SiteCollection', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Get-SPWorkflowServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Grant-SPBusinessDataCatalogMetadataObject { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Right},

    [string]
    ${SettingId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Grant-SPObjectSecurity { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(Mandatory=$true, Position=2)]
    [ValidateNotNull()]
    [string[]]
    ${Rights},

    [switch]
    ${Replace},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPAccessServicesDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [guid]
    ${ServerReferenceId},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [byte[]]
    ${Bacpac},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPAppPackage { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [object]
    ${Source},

    [string]
    ${AssetId},

    [string]
    ${ContentMarket},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPBusinessDataCatalogDotNetAssembly { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [ValidateNotNullOrEmpty()]
    [string[]]
    ${DependentAssemblyPaths},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${LobSystem},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPBusinessDataCatalogModel { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${ModelsIncluded},

    [switch]
    ${LocalizedNamesIncluded},

    [switch]
    ${PropertiesIncluded},

    [switch]
    ${PermissionsIncluded},

    [Parameter(ParameterSetName='Catalog', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='ServiceContext', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [switch]
    ${Force},

    [string]
    ${SettingId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPEnterpriseSearchCustomExtractionDictionary { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, HelpMessage='Specify the UNC path to the CSV file.')]
    [string]
    ${FileName},

    [Parameter(Mandatory=$true, HelpMessage='Specify the fully qualified name of the target dictionary to be deployed.')]
    [ValidateSet('Microsoft.UserDictionaries.EntityExtraction.Custom.Word.1','Microsoft.UserDictionaries.EntityExtraction.Custom.Word.2','Microsoft.UserDictionaries.EntityExtraction.Custom.Word.3','Microsoft.UserDictionaries.EntityExtraction.Custom.Word.4','Microsoft.UserDictionaries.EntityExtraction.Custom.Word.5','Microsoft.UserDictionaries.EntityExtraction.Custom.ExactWord.1','Microsoft.UserDictionaries.EntityExtraction.Custom.WordPart.1','Microsoft.UserDictionaries.EntityExtraction.Custom.WordPart.2','Microsoft.UserDictionaries.EntityExtraction.Custom.WordPart.3','Microsoft.UserDictionaries.EntityExtraction.Custom.WordPart.4','Microsoft.UserDictionaries.EntityExtraction.Custom.WordPart.5','Microsoft.UserDictionaries.EntityExtraction.Custom.ExactWordPart.1')]
    [string]
    ${DictionaryName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPEnterpriseSearchPopularQueries { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplicationProxy},

    [Parameter(Mandatory=$true)]
    [object]
    ${ResultSource},

    [Parameter(Mandatory=$true)]
    [object]
    ${Web},

    [string]
    ${Filename},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPEnterpriseSearchThesaurus { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, HelpMessage='Specify the UNC path to the CSV file.')]
    [string]
    ${FileName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPEnterpriseSearchTopology { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${Filename},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPInfoPathAdministrationFiles { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Path},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPMetadataWebServicePartitionData { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceProxy},

    [switch]
    ${ToServiceDatabase},

    [ValidateNotNull()]
    [object]
    ${ToContentDatabase},

    [switch]
    ${NoCompression},

    [ValidateSet('true','false')]
    [switch]
    ${OverwriteExisting},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPPerformancePointContent { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${ImportFileUrl},

    [Parameter(Mandatory=$true)]
    [string]
    ${MasterPageUrl},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${SiteDestination},

    [Parameter(Mandatory=$true)]
    [hashtable]
    ${LocationMap},

    [Parameter(Mandatory=$true)]
    [hashtable]
    ${DatasourceMap},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${FilePath},

    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPServerScaleOutDatabaseTenantData { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${FilePath},

    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPSiteSubscriptionBusinessDataCatalogConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [switch]
    ${ModelsIncluded},

    [switch]
    ${LocalizedNamesIncluded},

    [switch]
    ${PropertiesIncluded},

    [switch]
    ${ProxiesIncluded},

    [switch]
    ${PermissionsIncluded},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPSiteSubscriptionSettings { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Path},

    [switch]
    ${AdminProperties},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Import-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${IncludeUserCustomAction},

    [switch]
    ${ActivateSolutions},

    [object]
    ${UpdateVersions},

    [Parameter(Mandatory=$true)]
    [string]
    ${Path},

    [switch]
    ${Force},

    [switch]
    ${IncludeUserSecurity},

    [switch]
    ${HaltOnWarning},

    [switch]
    ${HaltOnError},

    [switch]
    ${NoLogFile},

    [switch]
    ${NoFileCompression},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Initialize-SPResourceSecurity { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Initialize-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPApp { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPApplicationContent { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPDataConnectionFile { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Path},

    [ValidateLength(0, 255)]
    [string]
    ${Category},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${WebAccessible},

    [switch]
    ${Overwrite},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPFeature { 
  [CmdletBinding(DefaultParameterSetName='PathSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='PathSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Path},

    [Parameter(ParameterSetName='AllExistingFeatures', Mandatory=$true)]
    [switch]
    ${AllExistingFeatures},

    [Parameter(ParameterSetName='ScanForFeatures', Mandatory=$true)]
    [switch]
    ${ScanForFeatures},

    [switch]
    ${Force},

    [Parameter(ParameterSetName='ScanForFeatures')]
    [Parameter(ParameterSetName='AllExistingFeatures')]
    [string]
    ${SolutionId},

    [Parameter(ParameterSetName='PathSet')]
    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPHelpCollection { 
  [CmdletBinding(DefaultParameterSetName='InstallOne')]
param(
    [Parameter(ParameterSetName='InstallOne', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${LiteralPath},

    [Parameter(ParameterSetName='InstallAll', Mandatory=$true)]
    [switch]
    ${All},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Path},

    [switch]
    ${EnableGradualUpgrade},

    [switch]
    ${NoWait},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPService { 
  [CmdletBinding()]
param(
    [switch]
    ${Provision},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPSolution { 
  [CmdletBinding(DefaultParameterSetName='Deploy', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Synchronize', Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Deploy', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Deploy')]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='Deploy')]
    [string]
    ${Time},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${CASPolicies},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${GACDeployment},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${FullTrustBinDeployment},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${Local},

    [uint32]
    ${Language},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${Force},

    [Parameter(ParameterSetName='Deploy')]
    [switch]
    ${AllWebApplications},

    [Parameter(ParameterSetName='Deploy')]
    [string]
    ${CompatibilityLevel},

    [Parameter(ParameterSetName='Synchronize', Mandatory=$true)]
    [switch]
    ${Synchronize},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPUserSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Install-SPWebPartPack { 
  [CmdletBinding(DefaultParameterSetName='UseFileName', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='UseName', Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='UseFileName', Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${LiteralPath},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [switch]
    ${GlobalInstall},

    [uint32]
    ${Language},

    [switch]
    ${Force},

    [string]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Invoke-SPProjectActiveDirectoryEnterpriseResourcePoolSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Invoke-SPProjectActiveDirectoryGroupSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Merge-SPLogFile { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Path},

    [switch]
    ${Overwrite},

    [datetime]
    ${StartTime},

    [datetime]
    ${EndTime},

    [string[]]
    ${Process},

    [uint32[]]
    ${ThreadID},

    [string[]]
    ${Area},

    [string[]]
    ${Category},

    [string[]]
    ${EventID},

    [string]
    ${Level},

    [string[]]
    ${Message},

    [guid[]]
    ${Correlation},

    [string[]]
    ${ContextFilter},

    [switch]
    ${ExcludeNestedCorrelation},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Merge-SPUsageLog { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [datetime]
    ${StartTime},

    [datetime]
    ${EndTime},

    [string[]]
    ${Servers},

    [string]
    ${DiagnosticLogPath},

    [switch]
    ${OverWrite},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Migrate-SPDatabase { 
  [CmdletBinding(DefaultParameterSetName='SiteSubscription', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SiteSubscription', Mandatory=$true, Position=1)]
    [object]
    ${DestinationDatabase},

    [Parameter(ParameterSetName='SiteCollection', Mandatory=$true, Position=2)]
    [object]
    ${SiteCollection},

    [Parameter(ParameterSetName='SiteSubscription', Mandatory=$true, Position=2)]
    [object]
    ${SiteSubscription},

    [Parameter(Mandatory=$true, Position=3)]
    [object]
    ${ServiceType},

    [Parameter(Position=4)]
    [switch]
    ${Overwrite},

    [Parameter(Position=5)]
    [switch]
    ${UseLinkedSqlServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Migrate-SPProjectDatabase { 
  [CmdletBinding(DefaultParameterSetName='web', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='web', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='web')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='web')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${FailoverPartner},

    [Parameter(ParameterSetName='web')]
    [pscredential]
    ${SQLLogon},

    [Parameter(ParameterSetName='web')]
    [switch]
    ${Overwrite},

    [Parameter(ParameterSetName='web', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Migrate-SPProjectResourcePlans { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Mount-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${SkipIntegrityChecks},

    [Alias('NoB2BSiteUpgrade')]
    [switch]
    ${SkipSiteUpgrade},

    [string]
    ${DatabaseFailoverServer},

    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseAccessCredentials},

    [ValidateRange(1, 2147483647)]
    [int]
    ${MaxSiteCount},

    [ValidateRange(0, 2147483647)]
    [int]
    ${WarningSiteCount},

    [switch]
    ${ClearChangeLog},

    [switch]
    ${ChangeSyncKnowledge},

    [switch]
    ${AssignNewDatabaseId},

    [switch]
    ${UseLatestSchema},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Mount-SPSiteMapDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [string]
    ${DatabaseFailoverServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Mount-SPStateServiceDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [ValidateRange(0, 10)]
    [System.Nullable[int]]
    ${Weight},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPAppManagementData { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [object]
    ${SourceAppManagementDatabase},

    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [object]
    ${TargetContentDatabase},

    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(ParameterSetName='Default')]
    [switch]
    ${OverWrite},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPBlobStorageLocation { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SourceDatabase},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DestinationDataSourceInstance},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DestinationDatabase},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Dir},

    [ValidateNotNullOrEmpty()]
    [bool]
    ${VerboseMod},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPDeletedSite { 
  [CmdletBinding(DefaultParameterSetName='DatabaseFromPipebind', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${DestinationDatabase},

    [hashtable]
    ${RbsProviderMapping},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPEnterpriseSearchLinksDatabases { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=1)]
    [System.Nullable[guid]]
    ${RepartitioningId},

    [Parameter(Position=2)]
    [object]
    ${SourceStores},

    [Parameter(Position=3)]
    [object]
    ${TargetStores},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPProfileManagedMetadataProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Identity},

    [string]
    ${TermSetName},

    [switch]
    ${AvailableForTagging},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${DestinationDatabase},

    [hashtable]
    ${RbsProviderMapping},

    [bool]
    ${CopyEvents},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPSocialComment { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [string]
    ${OldUrl},

    [string]
    ${NewUrl},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Move-SPUser { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('UserAlias')]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewAlias},

    [switch]
    ${IgnoreSID},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAccessServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [string]
    ${Name},

    [switch]
    ${Default},

    [ValidateRange(1, 255)]
    [int]
    ${ColumnsMax},

    [ValidateRange(1, 200000)]
    [int]
    ${RowsMax},

    [ValidateRange(1, 20)]
    [int]
    ${SourcesMax},

    [ValidateRange(0, 32)]
    [int]
    ${OutputCalculatedColumnsMax},

    [ValidateRange(0, 8)]
    [int]
    ${OrderByMax},

    [switch]
    ${OuterJoinsAllowed},

    [switch]
    ${NonRemotableQueriesAllowed},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${RecordsInTableMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${ApplicationLogSizeMax},

    [ValidateRange(-1, 2073600)]
    [int]
    ${RequestDurationMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerUserMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerAnonymousUserMax},

    [ValidateRange(-1, 2073600)]
    [int]
    ${CacheTimeout},

    [ValidateRange(0, 4096)]
    [int]
    ${SessionMemoryMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${PrivateBytesMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${TemplateSizeMax},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAccessServicesApplication { 
  [CmdletBinding(DefaultParameterSetName='NoApplicationServerParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='DefaultParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [ValidateNotNull()]
    [pscredential]
    ${DatabaseServerCredentials},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='DefaultParameterSet', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet')]
    [string]
    ${Name},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet', Mandatory=$true)]
    [switch]
    ${Default},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet')]
    [ValidateRange(-1, 2073600)]
    [int]
    ${RequestDurationMax},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerUserMax},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet')]
    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerAnonymousUserMax},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet')]
    [ValidateRange(-1, 2073600)]
    [int]
    ${CacheTimeout},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [ValidateRange(-1, 2147483647)]
    [int]
    ${PrivateBytesMax},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [ValidateRange(-1, 2073600)]
    [int]
    ${QueryTimeout},

    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [Parameter(ParameterSetName='DefaultParameterSet')]
    [ValidateRange(-1, 1440)]
    [int]
    ${RecoveryPointObjective},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [Parameter(ParameterSetName='NoApplicationServerParameterSet')]
    [bool]
    ${Hosted},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [bool]
    ${Encrypt},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [bool]
    ${TrustServerCertificate},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAccessServicesApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${application},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAccessServicesDatabaseServer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServerName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServerGroupName},

    [ValidateNotNullOrEmpty()]
    [guid]
    ${ServerReferenceId},

    [ValidateNotNullOrEmpty()]
    [pscredential]
    ${DatabaseServerCredentials},

    [ValidateNotNullOrEmpty()]
    [bool]
    ${AvailableForCreate},

    [ValidateNotNullOrEmpty()]
    [bool]
    ${Exclusive},

    [bool]
    ${Encrypt},

    [bool]
    ${TrustServerCertificate},

    [bool]
    ${ValidateServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${SecondaryDatabaseServerName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${UserDomain},

    [object]
    ${LoginType},

    [object]
    ${State},

    [object]
    ${StateOwner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAlternateURL { 
  [CmdletBinding(DefaultParameterSetName='WebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Url},

    [object]
    ${Zone},

    [switch]
    ${Internal},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='ResourceName', Mandatory=$true)]
    [string]
    ${ResourceName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAppManagementServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAppManagementServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Name},

    [switch]
    ${UseDefaultProxyGroup},

    [Parameter(ParameterSetName='Uri', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Uri},

    [Parameter(ParameterSetName='ServiceApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAuthenticationProvider { 
  [CmdletBinding(DefaultParameterSetName='Windows')]
param(
    [Parameter(ParameterSetName='Windows')]
    [switch]
    ${AllowAnonymous},

    [Parameter(ParameterSetName='Windows')]
    [switch]
    ${UseBasicAuthentication},

    [Parameter(ParameterSetName='Windows')]
    [switch]
    ${DisableKerberos},

    [Parameter(ParameterSetName='Windows')]
    [switch]
    ${UseWindowsIntegratedAuthentication},

    [Parameter(ParameterSetName='Forms', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ASPNETMembershipProvider},

    [Parameter(ParameterSetName='Forms', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ASPNETRoleProviderName},

    [Parameter(ParameterSetName='Trusted', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${TrustedIdentityTokenIssuer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPAzureAccessControlServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${MetadataServiceEndpointUri},

    [ValidateNotNull()]
    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPBECWebServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServiceEndpointUri},

    [ValidateNotNull()]
    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPBusinessDataCatalogServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Name},

    [switch]
    ${PartitionMode},

    [switch]
    ${Sharing},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [pscredential]
    ${DatabaseCredentials},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPBusinessDataCatalogServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Uri', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${Uri},

    [switch]
    ${DefaultProxyGroup},

    [string]
    ${Name},

    [Parameter(ParameterSetName='PipeBind', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceApplication},

    [Parameter(ParameterSetName='Uri')]
    [switch]
    ${PartitionMode},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPCentralAdministration { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [int]
    ${Port},

    [Parameter(Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${WindowsAuthProvider},

    [Parameter(Position=2, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${SecureSocketsLayer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPClaimProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${DisplayName},

    [Parameter(Mandatory=$true)]
    [string]
    ${Description},

    [Parameter(Mandatory=$true)]
    [string]
    ${AssemblyName},

    [Parameter(Mandatory=$true)]
    [string]
    ${Type},

    [switch]
    ${Enabled},

    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPClaimsPrincipal { 
  [CmdletBinding(DefaultParameterSetName='IdentityType')]
param(
    [Parameter(ParameterSetName='TrustIdentity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='IdentityType', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Identity},

    [Parameter(ParameterSetName='TrustIdentity', Mandatory=$true, Position=1)]
    [Parameter(ParameterSetName='STSIdentity', Mandatory=$true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${TrustedIdentityTokenIssuer},

    [Parameter(ParameterSetName='IdentityType', Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${IdentityType},

    [Parameter(ParameterSetName='BasicClaim', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${EncodedClaim},

    [Parameter(ParameterSetName='ClaimProvider', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='STSIdentity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ClaimValue},

    [Parameter(ParameterSetName='ClaimProvider', Mandatory=$true, Position=1)]
    [Parameter(ParameterSetName='STSIdentity', Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ClaimType},

    [Parameter(ParameterSetName='ClaimProvider', Mandatory=$true, Position=2)]
    [ValidateNotNull()]
    [object]
    ${ClaimProvider},

    [Parameter(ParameterSetName='STSIdentity', Position=3)]
    [ValidateNotNull()]
    [switch]
    ${IdentifierClaim},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPClaimTypeEncoding { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [char]
    ${EncodingCharacter},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ClaimType},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPClaimTypeMapping { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${IncomingClaimType},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${IncomingClaimTypeDisplayName},

    [Parameter(Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${LocalClaimType},

    [ValidateNotNull()]
    [switch]
    ${SameAsIncoming},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPConfigurationDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${DatabaseName},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(Position=2, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DirectoryDomain},

    [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DirectoryOrganizationUnit},

    [Parameter(Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${AdministrationContentDatabaseName},

    [Parameter(Position=5, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(Mandatory=$true, Position=6, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${FarmCredentials},

    [Parameter(Mandatory=$true, Position=7, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [securestring]
    ${Passphrase},

    [Parameter(Position=8, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${SkipRegisterAsDistributedCacheHost},

    [Parameter(Position=11, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${DatabaseFailOverServer},

    [ValidateSet('Application','ApplicationWithSearch','Custom','DistributedCache','Search','SingleServerFarm','WebFrontEnd','WebFrontEndWithDistributedCache')]
    [object]
    ${LocalServerRole},

    [switch]
    ${ServerRoleOptional},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseAccessCredentials},

    [ValidateRange(1, 2147483647)]
    [int]
    ${MaxSiteCount},

    [ValidateRange(0, 2147483647)]
    [int]
    ${WarningSiteCount},

    [switch]
    ${ClearChangeLog},

    [switch]
    ${ChangeSyncKnowledge},

    [switch]
    ${AssignNewDatabaseId},

    [switch]
    ${UseLatestSchema},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPContentDeploymentJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [string]
    ${Description},

    [Parameter(Mandatory=$true)]
    [object]
    ${SPContentDeploymentPath},

    [object]
    ${Scope},

    [string]
    ${Schedule},

    [switch]
    ${ScheduleEnabled},

    [switch]
    ${IncrementalEnabled},

    [object]
    ${SqlSnapshotSetting},

    [switch]
    ${HostingSupportEnabled},

    [object]
    ${EmailNotifications},

    [string[]]
    ${EmailAddresses},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPContentDeploymentPath { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [string]
    ${Description},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceSPWebApplication},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceSPSite},

    [Parameter(Mandatory=$true)]
    [uri]
    ${DestinationCentralAdministrationURL},

    [Parameter(Mandatory=$true)]
    [uri]
    ${DestinationSPWebApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${DestinationSPSite},

    [object]
    ${Authentication},

    [Parameter(Mandatory=$true)]
    [pscredential]
    ${PathAccount},

    [switch]
    ${DeployUserNamesEnabled},

    [object]
    ${DeploySecurityInformation},

    [switch]
    ${EventReceiversEnabled},

    [switch]
    ${CompressionEnabled},

    [switch]
    ${PathEnabled},

    [object]
    ${KeepTemporaryFilesOptions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchAdminComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchAnalyticsProcessingComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchContentEnrichmentConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchContentProcessingComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlContentSource { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('t')]
    [object]
    ${Type},

    [string]
    ${Tag},

    [Alias('s')]
    [string]
    ${StartAddresses},

    [Alias('p')]
    [object]
    ${CrawlPriority},

    [System.Nullable[int]]
    ${MaxPageEnumerationDepth},

    [System.Nullable[int]]
    ${MaxSiteEnumerationDepth},

    [object]
    ${SharePointCrawlBehavior},

    [object]
    ${BDCApplicationProxyGroup},

    [string[]]
    ${LOBSystemSet},

    [string]
    ${CustomProtocol},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlCustomConnector { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${Protocol},

    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [string]
    ${ModelFilePath},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlExtension { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Url},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('t')]
    [string]
    ${Target},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchCrawlRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Path},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('t')]
    [object]
    ${Type},

    [System.Nullable[bool]]
    ${IsAdvancedRegularExpression},

    [System.Nullable[bool]]
    ${CrawlAsHttp},

    [System.Nullable[bool]]
    ${FollowComplexUrls},

    [System.Nullable[int]]
    ${PluggableSecurityTimmerId},

    [System.Nullable[bool]]
    ${SuppressIndexing},

    [System.Nullable[int]]
    ${Priority},

    [string]
    ${ContentClass},

    [object]
    ${AuthenticationType},

    [string]
    ${AccountName},

    [securestring]
    ${AccountPassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchFileFormat { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${FormatId},

    [Parameter(Mandatory=$true, Position=1)]
    [string]
    ${FormatName},

    [Parameter(Mandatory=$true, Position=2)]
    [string]
    ${MimeType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchIndexComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [uint32]
    ${IndexPartition},

    [string]
    ${RootDirectory},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchLanguageResourcePhrase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [object]
    ${Type},

    [Parameter(Mandatory=$true)]
    [string]
    ${Language},

    [string]
    ${Mapping},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [guid]
    ${SourceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchLinksDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchMetadataCategory { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Alias('p')]
    [System.Nullable[guid]]
    ${PropSet},

    [Alias('d')]
    [System.Nullable[bool]]
    ${DiscoverNewProperties},

    [Alias('m')]
    [System.Nullable[bool]]
    ${MapToContents},

    [Alias('auto')]
    [System.Nullable[bool]]
    ${AutoCreateNewManagedProperties},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchMetadataCrawledProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('c')]
    [object]
    ${Category},

    [Parameter(Mandatory=$true)]
    [Alias('ie')]
    [bool]
    ${IsNameEnum},

    [Parameter(Mandatory=$true)]
    [Alias('vt')]
    [Obsolete()]
    [int]
    ${VariantType},

    [Parameter(Mandatory=$true)]
    [Alias('p')]
    [guid]
    ${PropSet},

    [Alias('im')]
    [System.Nullable[bool]]
    ${IsMappedToContents},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchMetadataManagedProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('t')]
    [int]
    ${Type},

    [Alias('d')]
    [string]
    ${Description},

    [Alias('f')]
    [System.Nullable[bool]]
    ${FullTextQueriable},

    [Alias('r')]
    [System.Nullable[bool]]
    ${Retrievable},

    [Alias('q')]
    [System.Nullable[bool]]
    ${Queryable},

    [Alias('e')]
    [System.Nullable[bool]]
    ${EnabledForScoping},

    [Alias('nn')]
    [System.Nullable[bool]]
    ${NameNormalized},

    [Alias('rp')]
    [System.Nullable[bool]]
    ${RespectPriority},

    [Alias('rd')]
    [System.Nullable[bool]]
    ${RemoveDuplicates},

    [Alias('im5')]
    [Obsolete('This property is replaced by IncludeInAlertSignature.')]
    [System.Nullable[bool]]
    ${IncludeInMd5},

    [Alias('sfa')]
    [System.Nullable[bool]]
    ${SafeForAnonymous},

    [Alias('ia')]
    [System.Nullable[bool]]
    ${IncludeInAlertSignature},

    [Alias('nw')]
    [System.Nullable[bool]]
    ${NoWordBreaker},

    [Alias('u')]
    [System.Nullable[int16]]
    ${UserFlags},

    [Alias('qir')]
    [System.Nullable[bool]]
    ${EnabledForQueryIndependentRank},

    [Alias('def')]
    [System.Nullable[uint32]]
    ${DefaultForQueryIndependentRank},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchMetadataMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [object]
    ${ManagedProperty},

    [Parameter(Mandatory=$true)]
    [object]
    ${CrawledProperty},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Url},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('l')]
    [float]
    ${Level},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryDemoted { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Url},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryKeyword { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Term},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Alias('d')]
    [string]
    ${Definition},

    [Alias('c')]
    [string]
    ${Contact},

    [Alias('s')]
    [System.Nullable[datetime]]
    ${StartDate},

    [Alias('e')]
    [System.Nullable[datetime]]
    ${EndDate},

    [Alias('r')]
    [System.Nullable[datetime]]
    ${ReviewDate},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryProcessingComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchTopology},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchServiceInstance},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryScope { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('d')]
    [string]
    ${Description},

    [Alias('o')]
    [uri]
    ${OwningSiteUrl},

    [Alias('a')]
    [string]
    ${AlternateResultsPage},

    [Parameter(Mandatory=$true)]
    [Alias('disp')]
    [System.Nullable[bool]]
    ${DisplayInAdminUI},

    [Alias('type')]
    [System.Nullable[int]]
    ${CompilationType},

    [Alias('f')]
    [string]
    ${ExtendedSearchFilter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchQueryScopeRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('u')]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Alias('s')]
    [object]
    ${Scope},

    [Parameter(Mandatory=$true)]
    [Alias('type')]
    [string]
    ${RuleType},

    [Alias('f')]
    [string]
    ${FilterBehavior},

    [Alias('ut')]
    [string]
    ${UrlScopeRuleType},

    [Alias('text')]
    [string]
    ${MatchingString},

    [Alias('value')]
    [string]
    ${PropertyValue},

    [Alias('mname')]
    [object]
    ${ManagedProperty},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchRankingModel { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${RankingModelXML},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchResultItemType { 
  [CmdletBinding(DefaultParameterSetName='New', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplicationProxy},

    [Parameter(ParameterSetName='Copy', Position=1)]
    [Parameter(ParameterSetName='New', Mandatory=$true, Position=1)]
    [Alias('n')]
    [string]
    ${Name},

    [Parameter(ParameterSetName='New', Mandatory=$true, Position=2)]
    [Parameter(ParameterSetName='Copy', Position=2)]
    [Alias('rule')]
    [object]
    ${Rules},

    [Parameter(Position=3)]
    [Alias('priority')]
    [int]
    ${RulePriority},

    [Parameter(Position=4)]
    [Alias('dp')]
    [string]
    ${DisplayProperties},

    [Parameter(Position=5)]
    [Alias('sid')]
    [System.Nullable[guid]]
    ${SourceID},

    [Parameter(ParameterSetName='Copy', Position=6)]
    [Parameter(ParameterSetName='New', Mandatory=$true, Position=6)]
    [Alias('url')]
    [string]
    ${DisplayTemplateUrl},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ParameterSetName='Copy', Mandatory=$true)]
    [Alias('copy')]
    [object]
    ${ExistingResultItemType},

    [Parameter(ParameterSetName='Copy', Mandatory=$true)]
    [Alias('eo')]
    [object]
    ${ExistingResultItemTypeOwner},

    [Alias('opt')]
    [System.Nullable[bool]]
    ${OptimizeForFrequentUse},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchResultSource { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [string]
    ${Description},

    [string]
    ${QueryTemplate},

    [Parameter(Mandatory=$true)]
    [guid]
    ${ProviderId},

    [string]
    ${RemoteUrl},

    [System.Nullable[bool]]
    ${AutoDiscover},

    [object]
    ${AuthenticationType},

    [string]
    ${UserName},

    [string]
    ${Password},

    [string]
    ${SsoId},

    [System.Nullable[bool]]
    ${MakeDefault},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchSecurityTrimmer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [int]
    ${Id},

    [Parameter(Mandatory=$true)]
    [string]
    ${TypeName},

    [string]
    ${Properties},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [string]
    ${RulePath},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='DefaultParameterSet', Position=0)]
    [string]
    ${Name},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [string]
    ${DatabaseUsername},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [securestring]
    ${DatabasePassword},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [switch]
    ${Partitioned},

    [Parameter(ParameterSetName='DefaultParameterSet', Mandatory=$true)]
    [object]
    ${ApplicationPool},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [object]
    ${AdminApplicationPool},

    [Parameter(ParameterSetName='DefaultParameterSet')]
    [bool]
    ${CloudIndex},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='SSA', Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=0)]
    [string]
    ${Name},

    [Parameter(ParameterSetName='Uri', Mandatory=$true)]
    [string]
    ${Uri},

    [switch]
    ${Partitioned},

    [switch]
    ${MergeWithDefaultPartition},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchSiteHitRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchService},

    [Parameter(Mandatory=$true)]
    [string]
    ${HitRate},

    [Parameter(Mandatory=$true)]
    [string]
    ${Behavior},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPEnterpriseSearchTopology { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ParameterSetName='Clone')]
    [switch]
    ${Clone},

    [Parameter(ParameterSetName='Clone')]
    [object]
    ${SearchTopology},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPLogFile { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPManagedAccount { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [pscredential]
    ${Credential},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPManagedPath { 
  [CmdletBinding(DefaultParameterSetName='WebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${RelativeURL},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='HostHeader', Mandatory=$true)]
    [switch]
    ${HostHeader},

    [switch]
    ${Explicit},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPMarketplaceWebServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServiceEndpointUri},

    [ValidateNotNull()]
    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPMetadataServiceApplication { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${AdministratorAccount},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredentials},

    [string]
    ${FailoverDatabaseServer},

    [string]
    ${FullAccessAccount},

    [string]
    ${HubUri},

    [Parameter(ParameterSetName='Quota', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='Default', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='NoQuota', Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [switch]
    ${PartitionMode},

    [string]
    ${ReadAccessAccount},

    [string]
    ${RestrictedAccount},

    [switch]
    ${SyndicationErrorReportEnabled},

    [int]
    ${CacheTimeCheckInterval},

    [int]
    ${MaxChannelCache},

    [Parameter(ParameterSetName='NoQuota', Mandatory=$true)]
    [switch]
    ${DisablePartitionQuota},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${GroupsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${TermSetsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${TermsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${LabelsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${PropertiesPerPartition},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPMetadataServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${ContentTypePushdownEnabled},

    [switch]
    ${ContentTypeSyndicationEnabled},

    [switch]
    ${DefaultProxyGroup},

    [switch]
    ${DefaultKeywordTaxonomy},

    [switch]
    ${DefaultSiteCollectionTaxonomy},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [switch]
    ${PartitionMode},

    [object]
    ${ServiceApplication},

    [string]
    ${Uri},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPODataConnectionSetting { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateLength(0, 246)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${ServiceAddressURL},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${AuthenticationMode},

    [ValidateNotNull()]
    [ValidateLength(0, 1024)]
    [string]
    ${SecureStoreTargetApplicationId},

    [string]
    ${ExtensionProvider},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPOnlineApplicationPrincipalManagementServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${OnlineTenantUri},

    [ValidateNotNull()]
    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPPerformancePointServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateLength(0, 64)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ApplicationPool},

    [bool]
    ${CommentsDisabled},

    [int]
    ${CommentsScorecardMax},

    [int]
    ${IndicatorImageCacheSeconds},

    [int]
    ${DataSourceQueryTimeoutSeconds},

    [int]
    ${FilterRememberUserSelectionsDays},

    [int]
    ${FilterTreeMembersMax},

    [int]
    ${FilterSearchResultsMax},

    [int]
    ${ShowDetailsInitialRows},

    [bool]
    ${ShowDetailsMaxRowsDisabled},

    [int]
    ${ShowDetailsMaxRows},

    [bool]
    ${MSMQEnabled},

    [string]
    ${MSMQName},

    [int]
    ${SessionHistoryHours},

    [bool]
    ${AnalyticQueryLoggingEnabled},

    [bool]
    ${TrustedDataSourceLocationsRestricted},

    [bool]
    ${TrustedContentLocationsRestricted},

    [int]
    ${SelectMeasureMaximum},

    [int]
    ${DecompositionTreeMaximum},

    [bool]
    ${ApplicationProxyCacheEnabled},

    [bool]
    ${ApplicationCacheEnabled},

    [int]
    ${ApplicationCacheMinimumHitCount},

    [int]
    ${AnalyticResultCacheMinimumHitCount},

    [int]
    ${ElementCacheSeconds},

    [int]
    ${AnalyticQueryCellMax},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseFailoverServer},

    [pscredential]
    ${DatabaseSQLAuthenticationCredential},

    [bool]
    ${UseEffectiveUserName},

    [string]
    ${DataSourceUnattendedServiceAccountTargetApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPPerformancePointServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateLength(0, 64)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPPerformancePointServiceApplicationTrustedLocation { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateLength(0, 1024)]
    [string]
    ${Url},

    [Parameter(Mandatory=$true)]
    [object]
    ${Type},

    [Parameter(Mandatory=$true)]
    [object]
    ${TrustedLocationType},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [string]
    ${Description},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPPowerPointConversionServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateLength(1, 128)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPPowerPointConversionServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateLength(1, 128)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [switch]
    ${AddToDefaultGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPProfileServiceApplication { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [string]
    ${ProfileDBName},

    [string]
    ${ProfileDBServer},

    [pscredential]
    ${ProfileDBCredentials},

    [string]
    ${ProfileDBFailoverServer},

    [string]
    ${SocialDBName},

    [string]
    ${SocialDBServer},

    [pscredential]
    ${SocialDBCredentials},

    [string]
    ${SocialDBFailoverServer},

    [string]
    ${ProfileSyncDBName},

    [string]
    ${ProfileSyncDBServer},

    [pscredential]
    ${ProfileSyncDBCredentials},

    [string]
    ${ProfileSyncDBFailoverServer},

    [switch]
    ${PartitionMode},

    [Parameter(ParameterSetName='MySiteSettings', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${MySiteHostLocation},

    [Parameter(ParameterSetName='MySiteSettings', ValueFromPipeline=$true)]
    [object]
    ${MySiteManagedPath},

    [Parameter(ParameterSetName='MySiteSettings')]
    [ValidateSet('None','Resolve','Block')]
    [string]
    ${SiteNamingConflictResolution},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPProfileServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [string]
    ${Name},

    [Parameter(ParameterSetName='Application', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceApplication},

    [Parameter(ParameterSetName='Uri', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [uri]
    ${Uri},

    [switch]
    ${DefaultProxyGroup},

    [switch]
    ${PartitionMode},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPProjectServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${ApplicationPool},

    [switch]
    ${Proxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPProjectServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPRequestManagementRuleCriteria { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='StandardParameterSet', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='CustomPropertyParameterSet', Mandatory=$true, Position=0)]
    [string]
    ${Value},

    [Parameter(ParameterSetName='CustomPropertyParameterSet', Mandatory=$true, Position=1)]
    [string]
    ${CustomHeader},

    [Parameter(ParameterSetName='StandardParameterSet', Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${Property},

    [Parameter(ParameterSetName='StandardParameterSet', Position=2)]
    [Parameter(ParameterSetName='CustomPropertyParameterSet', Position=2)]
    [ValidateNotNull()]
    [object]
    ${MatchType},

    [Parameter(ParameterSetName='StandardParameterSet', Position=2)]
    [Parameter(ParameterSetName='CustomPropertyParameterSet', Position=2)]
    [System.Nullable[switch]]
    ${CaseSensitive},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSecureStoreApplication { 
  [CmdletBinding()]
param(
    [object]
    ${Administrator},

    [object]
    ${CredentialsOwnerGroup},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Fields},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(Mandatory=$true)]
    [object]
    ${TargetApplication},

    [object]
    ${TicketRedeemer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSecureStoreApplicationField { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [switch]
    ${Masked},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [object]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSecureStoreServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ApplicationPool},

    [Parameter(Mandatory=$true)]
    [switch]
    ${AuditingEnabled},

    [System.Nullable[int]]
    ${AuditlogMaxSize},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [securestring]
    ${DatabasePassword},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${DatabaseUsername},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${FailoverDatabaseServer},

    [string]
    ${Name},

    [switch]
    ${PartitionMode},

    [switch]
    ${Sharing},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSecureStoreServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${DefaultProxyGroup},

    [string]
    ${Name},

    [Parameter(ParameterSetName='PipeBind', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ParameterSetName='Uri', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${Uri},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSecureStoreTargetApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ApplicationType},

    [string]
    ${ContactEmail},

    [Parameter(Mandatory=$true)]
    [string]
    ${FriendlyName},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [ValidateNotNull()]
    [uri]
    ${SetCredentialsUri},

    [int]
    ${TimeoutInMinutes},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPServiceApplicationPool { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 100)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, Position=1)]
    [object]
    ${Account},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPServiceApplicationProxyGroup { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [AllowEmptyString()]
    [ValidateNotNull()]
    [ValidateLength(0, 100)]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Url},

    [uint32]
    ${Language},

    [object]
    ${Template},

    [string]
    ${Name},

    [string]
    ${Description},

    [object]
    ${QuotaTemplate},

    [string]
    ${OwnerEmail},

    [Parameter(Mandatory=$true)]
    [object]
    ${OwnerAlias},

    [string]
    ${SecondaryEmail},

    [object]
    ${SecondaryOwnerAlias},

    [object]
    ${HostHeaderWebApplication},

    [object]
    ${ContentDatabase},

    [object]
    ${SiteSubscription},

    [object]
    ${AdministrationSiteType},

    [int]
    ${CompatibilityLevel},

    [switch]
    ${OverrideCompatibilityRestriction},

    [switch]
    ${CreateFromSiteMaster},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSiteMaster { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${Template},

    [uint32]
    ${Language},

    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSiteSubscription { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSiteSubscriptionFeaturePack { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPStateServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Database},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPStateServiceApplicationProxy { 
  [CmdletBinding()]
param(
    [string]
    ${Name},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ServiceApplication},

    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPStateServiceDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [ValidateRange(0, 10)]
    [System.Nullable[int]]
    ${Weight},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSubscriptionSettingsServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ApplicationPool},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPSubscriptionSettingsServiceApplicationProxy { 
  [CmdletBinding(DefaultParameterSetName='Uri', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Uri', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Uri},

    [Parameter(ParameterSetName='ServiceApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTranslationServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredential},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [switch]
    ${PartitionMode},

    [switch]
    ${Default},

    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTranslationServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [switch]
    ${DefaultProxyGroup},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [switch]
    ${PartitionMode},

    [Parameter(ParameterSetName='ConnectLocal', Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(ParameterSetName='ConnectRemote', Mandatory=$true)]
    [string]
    ${Uri},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTrustedIdentityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet')]
    [ValidateNotNull()]
    [object]
    ${ImportTrustCertificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ClaimsMappings},

    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SignInUrl},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${IdentifierClaim},

    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [object]
    ${ClaimProvider},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Realm},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet')]
    [switch]
    ${UseWReply},

    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet', Mandatory=$true)]
    [switch]
    ${UseDefaultConfiguration},

    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet')]
    [ValidateSet('EMAIL','USER-PRINCIPAL-NAME','ACCOUNT-NAME')]
    [string]
    ${IdentifierClaimIs},

    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SignOutUrl},

    [Parameter(ParameterSetName='ActiveDirectoryBackedParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RegisteredIssuerName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTrustedRootAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='ManualUpdateCertificateParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTrustedSecurityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [ValidateNotNullOrEmpty()]
    [string]
    ${RegisteredIssuerName},

    [ValidateNotNullOrEmpty()]
    [switch]
    ${IsTrustBroker},

    [Parameter(ParameterSetName='ImportCertificateParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPTrustedServiceTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [Parameter(ParameterSetName='ImportCertificateParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUsageApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0)]
    [string]
    ${Name},

    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 135)]
    [string]
    ${DatabaseServer},

    [ValidateLength(1, 135)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${FailoverDatabaseServer},

    [ValidateLength(1, 128)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='SQLAuthentication')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 128)]
    [string]
    ${DatabaseUsername},

    [Parameter(ParameterSetName='SQLAuthentication')]
    [ValidateNotNull()]
    [securestring]
    ${DatabasePassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${UsageService},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUsageLogFile { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUser { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${UserAlias},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [string]
    ${Email},

    [object]
    ${Group},

    [string[]]
    ${PermissionLevel},

    [string]
    ${DisplayName},

    [switch]
    ${SiteCollectionAdmin},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUserLicenseMapping { 
  [CmdletBinding(DefaultParameterSetName='WindowsAuth', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='WindowsAuth', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SecurityGroup},

    [Parameter(ParameterSetName='FormsAuth', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Role},

    [Parameter(ParameterSetName='FormsAuth', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RoleProviderName},

    [Parameter(ParameterSetName='ClaimsValues', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${OriginalIssuer},

    [Parameter(ParameterSetName='ClaimsValues', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Value},

    [Parameter(ParameterSetName='ClaimsValues', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ClaimType},

    [Parameter(ParameterSetName='ClaimsValues')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ValueType},

    [Parameter(ParameterSetName='TrustIdentity', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Claim},

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${License},

    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUserSettingsProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${DisplayName},

    [Parameter(Mandatory=$true)]
    [string]
    ${AssemblyName},

    [Parameter(Mandatory=$true)]
    [string]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPUserSolutionAllowList { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ListTitle},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPVisioSafeDataProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DataProviderId},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${DataProviderType},

    [string]
    ${Description},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPVisioServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${AddToDefaultGroup},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${ApplicationPool},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPVisioServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Url},

    [uint32]
    ${Language},

    [object]
    ${Template},

    [string]
    ${Name},

    [string]
    ${Description},

    [switch]
    ${AddToQuickLaunch},

    [switch]
    ${UniquePermissions},

    [switch]
    ${AddToTopNav},

    [switch]
    ${UseParentTopNav},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWebApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [string]
    ${ApplicationPool},

    [object]
    ${ApplicationPoolAccount},

    [Alias('ProxyGroup')]
    [object]
    ${ServiceApplicationProxyGroup},

    [switch]
    ${SecureSocketsLayer},

    [string]
    ${HostHeader},

    [uint32]
    ${Port},

    [switch]
    ${AllowAnonymousAccess},

    [string]
    ${Path},

    [string]
    ${Url},

    [ValidateSet('Kerberos','NTLM')]
    [string]
    ${AuthenticationMethod},

    [object]
    ${AuthenticationProvider},

    [object]
    ${AdditionalClaimProvider},

    [string]
    ${SignInRedirectURL},

    [object]
    ${SignInRedirectProvider},

    [object]
    ${UserSettingsProvider},

    [pscredential]
    ${DatabaseCredentials},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWebApplicationAppDomain { 
  [CmdletBinding(DefaultParameterSetName='WebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${AppDomain},

    [object]
    ${Zone},

    [int]
    ${Port},

    [switch]
    ${SecureSocketsLayer},

    [Parameter(Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWebApplicationExtension { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true)]
    [object]
    ${Zone},

    [uint32]
    ${Port},

    [string]
    ${HostHeader},

    [string]
    ${Path},

    [string]
    ${Url},

    [ValidateSet('Kerberos','NTLM')]
    [string]
    ${AuthenticationMethod},

    [switch]
    ${AllowAnonymousAccess},

    [switch]
    ${SecureSocketsLayer},

    [object]
    ${AuthenticationProvider},

    [object]
    ${AdditionalClaimProvider},

    [string]
    ${SignInRedirectURL},

    [object]
    ${SignInRedirectProvider},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWOPIBinding { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    ${FileName},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServerName},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Action},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Extension},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ProgId},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Application},

    [switch]
    ${AllowHTTP},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWOPISuppressionSetting { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    ${Extension},

    [ValidateNotNullOrEmpty()]
    [string]
    ${ProgId},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Action},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWordConversionServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredential},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [switch]
    ${PartitionMode},

    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWorkflowServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${PartitionMode},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWorkManagementServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [switch]
    ${Proxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function New-SPWorkManagementServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${DefaultProxyGroup},

    [Parameter(Mandatory=$true)]
    [string]
    ${Name},

    [object]
    ${ServiceApplication},

    [string]
    ${Uri},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Pause-SPProjectWebInstance { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Publish-SPServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateLength(0, 250)]
    [AllowEmptyString()]
    [string]
    ${Description},

    [ValidateNotNullOrEmpty()]
    [uri]
    ${InfoLink},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Receive-SPServiceApplicationConnectionInfo { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${FarmUrl},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Filter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Register-SPAppPrincipal { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NameIdentifier},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DisplayName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Register-SPWorkflowService { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SPSite},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${WorkflowHostUri},

    [string]
    ${ScopeName},

    [switch]
    ${PartitionMode},

    [switch]
    ${AllowOAuthHttp},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-DatabaseFromAvailabilityGroup { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${AGName},

    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='AllDatabases', Mandatory=$true)]
    [switch]
    ${ProcessAllDatabases},

    [switch]
    ${Force},

    [switch]
    ${KeepSecondaryData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPAccessServicesDatabaseServer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${DatabaseServer},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${DatabaseServerGroup},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPActivityFeedItems { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [bool]
    ${AllItems},

    [int]
    ${ID},

    [string]
    ${SearchText},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPAlternateURL { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPAppDeniedEndpoint { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Endpoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPAppPrincipalPermission { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${AppPrincipal},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Scope},

    [switch]
    ${DisableAppOnlyPolicy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPBusinessDataCatalogModel { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPCentralAdministration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPClaimProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPClaimTypeMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${TrustedIdentityTokenIssuer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPConfigurationDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPContentDeploymentJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPContentDeploymentPath { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPDeletedSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPDiagnosticsPerformanceCounter { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Category},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Counter},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Instance},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${WebFrontEnd},

    [Parameter(ValueFromPipeline=$true)]
    [switch]
    ${DatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPDistributedCacheServiceInstance { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchTopology},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchContentEnrichmentConfiguration { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlContentSource { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlCustomConnector { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlExtension { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlLogReadPermission { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SearchApplication},

    [guid]
    ${Tenant},

    [string]
    ${UserNames},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchCrawlRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchFileFormat { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchLanguageResourcePhrase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [object]
    ${Type},

    [string]
    ${Language},

    [string]
    ${Mapping},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [guid]
    ${SourceId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchLinksDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchMetadataCategory { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchMetadataManagedProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchMetadataMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchQueryAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchQueryDemoted { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchQueryKeyword { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchQueryScope { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Alias('u')]
    [uri]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchQueryScopeRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('u')]
    [uri]
    ${Url},

    [Alias('n')]
    [object]
    ${Scope},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchRankingModel { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchResultItemType { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplicationProxy},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchResultSource { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchSecurityTrimmer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${RemoveData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchServiceApplicationSiteSettings { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [guid]
    ${TenantId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchSiteHitRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchService},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchTenantConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Identity')]
    [guid]
    ${SiteSubscriptionId},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchTenantSchema { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPEnterpriseSearchTopology { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPInfoPathUserAgent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPManagedAccount { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='ChangePassword')]
    [switch]
    ${ChangePassword},

    [Parameter(ParameterSetName='ChangePassword', Mandatory=$true)]
    [securestring]
    ${NewPassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPManagedPath { 
  [CmdletBinding(DefaultParameterSetName='WebApplication', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='HostHeader', Mandatory=$true)]
    [switch]
    ${HostHeader},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPODataConnectionSetting { 
  [CmdletBinding(DefaultParameterSetName='Name', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='Name', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='Identity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPPerformancePointServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPPerformancePointServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPPerformancePointServiceApplicationTrustedLocation { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPPluggableSecurityTrimmer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNull()]
    [guid]
    ${UserProfileApplicationProxyId},

    [Parameter(Mandatory=$true)]
    [int]
    ${PlugInId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPProfileLeader { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPProfileSyncConnection { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplication},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionForestName},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionDomain},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionUserName},

    [Parameter(Mandatory=$true)]
    [securestring]
    ${ConnectionPassword},

    [string]
    ${ConnectionServerName},

    [string]
    ${ConnectionNamingContext},

    [Parameter(Mandatory=$true)]
    [string]
    ${ConnectionSynchronizationOU},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPProjectWebInstanceData { 
  [CmdletBinding(DefaultParameterSetName='web', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='web', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPRoutingMachineInfo { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPRoutingMachinePool { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPRoutingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Database},

    [switch]
    ${DeleteData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSecureStoreApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSecureStoreSystemAccount { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServerScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Database},

    [switch]
    ${DeleteData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [switch]
    ${RemoveData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServiceApplicationPool { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [switch]
    ${RemoveData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServiceApplicationProxyGroup { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPServiceApplicationProxyGroupMember { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [Alias('Proxy')]
    [ValidateNotNull()]
    [object]
    ${Member},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPShellAdmin { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${UserName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${database},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [switch]
    ${DeleteADAccounts},

    [switch]
    ${GradualDelete},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteMaster { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [guid]
    ${SiteId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscription { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionBusinessDataCatalogConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionFeaturePack { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionFeaturePackMember { 
  [CmdletBinding(DefaultParameterSetName='SingleFeatureDefinition', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SingleFeatureDefinition', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${FeatureDefinition},

    [Parameter(ParameterSetName='AllFeatureDefinitions', Mandatory=$true)]
    [switch]
    ${AllFeatureDefinitions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionMetadataConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionProfileConfig { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='Default', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Default', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ParameterSetName='ServiceContext', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteSubscriptionSettings { 
  [CmdletBinding(DefaultParameterSetName='SpecifySiteSubscriptions', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SpecifySiteSubscriptions', Mandatory=$true)]
    [ValidateNotNull()]
    [guid[]]
    ${SiteSubscriptions},

    [Parameter(ParameterSetName='FindAllOrphans', Mandatory=$true)]
    [ValidateSet('True')]
    [switch]
    ${FindAllOrphans},

    [Parameter(ParameterSetName='FindAllOrphans')]
    [ValidateNotNull()]
    [guid[]]
    ${AlternativeSiteSubscriptions},

    [Parameter(ParameterSetName='FindAllOrphans')]
    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteUpgradeSessionInfo { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSiteURL { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSocialItemByDate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [bool]
    ${RemoveTags},

    [bool]
    ${RemoveComments},

    [bool]
    ${RemoveRatings},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [datetime]
    ${EndDate},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [uint32]
    ${Language},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPSolutionDeploymentLock { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Position=0)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPThrottlingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPTranslationServiceJobHistory { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [switch]
    ${IncludeActiveJobs},

    [System.Nullable[datetime]]
    ${BeforeDate},

    [System.Nullable[guid]]
    ${JobId},

    [System.Nullable[guid]]
    ${PartitionId},

    [switch]
    ${AllPartitions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPTrustedIdentityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPTrustedRootAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPTrustedSecurityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPTrustedServiceTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPUsageApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${UsageService},

    [switch]
    ${RemoveData},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPUser { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('UserAlias')]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [object]
    ${Group},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPUserLicenseMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNull()]
    [System.Collections.Generic.List[guid]]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPUserSettingsProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPUserSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPVisioSafeDataProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DataProviderId},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${DataProviderType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Recycle},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWebApplication { 
  [CmdletBinding(DefaultParameterSetName='RemoveWebApp', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='RemoveZoneOfWebApp', Mandatory=$true)]
    [object]
    ${Zone},

    [Parameter(ParameterSetName='RemoveWebApp')]
    [switch]
    ${RemoveContentDatabases},

    [switch]
    ${DeleteIISSite},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWebApplicationAppDomain { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWOPIBinding { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='Identity', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Action},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Extension},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ProgId},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Application},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Server},

    [Parameter(ParameterSetName='Filter')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${WOPIZone},

    [Parameter(ParameterSetName='RemoveAll')]
    [switch]
    ${All},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWOPISuppressionSetting { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='DocTypeAndAction')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Extension},

    [Parameter(ParameterSetName='DocTypeAndAction')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ProgId},

    [Parameter(ParameterSetName='DocTypeAndAction')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Action},

    [Parameter(ParameterSetName='Identity', ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Remove-SPWordConversionServiceJobHistory { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [switch]
    ${IncludeActiveJobs},

    [System.Nullable[datetime]]
    ${BeforeDate},

    [System.Nullable[guid]]
    ${JobId},

    [System.Nullable[guid]]
    ${SubscriptionId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Rename-SPServer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Address')]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Repair-SPManagedAccountDeployment { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Repair-SPProjectWebInstance { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='FindProjectSiteByWebInstance', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${RepairRule},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Repair-SPSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [guid]
    ${RuleId},

    [switch]
    ${RunAlways},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Request-SPUpgradeEvaluationSite { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${NoUpgrade},

    [switch]
    ${Email},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Reset-SPAccessServicesDatabasePassword { 
  [CmdletBinding(DefaultParameterSetName='ResetAllApps', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='ResetSingleApp', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Database},

    [Parameter(ParameterSetName='ResetSingleApp', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='ResetAllApps', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Reset-SPProjectEventServiceSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Reset-SPProjectPCSSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Reset-SPProjectQueueSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Reset-SPSites { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restart-SPAppInstanceJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${AppInstance},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restore-SPDeletedSite { 
  [CmdletBinding(DefaultParameterSetName='DatabaseFromPipebind', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restore-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${Name},

    [Parameter(ParameterSetName='Config', Mandatory=$true)]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='Config', Mandatory=$true)]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='Config')]
    [string]
    ${DatabaseUsername},

    [Parameter(ParameterSetName='Config')]
    [securestring]
    ${DatabasePassword},

    [Parameter(ParameterSetName='Config')]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(ParameterSetName='Full', Mandatory=$true)]
    [string]
    ${TopologyFile},

    [Parameter(Mandatory=$true)]
    [object]
    ${ApplicationPool},

    [Parameter(ParameterSetName='Config', Mandatory=$true)]
    [object]
    ${AdminSearchServiceInstance},

    [Parameter(ParameterSetName='Full')]
    [switch]
    ${KeepId},

    [Parameter(ParameterSetName='Full')]
    [switch]
    ${DeferUpgradeActions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restore-SPEnterpriseSearchServiceApplicationIndex { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [object]
    ${SearchApplication},

    [Parameter(ParameterSetName='RestoreProgress', Mandatory=$true, Position=1)]
    [string]
    ${Handle},

    [Parameter(ParameterSetName='Restore', Mandatory=$true, Position=1)]
    [string]
    ${BackupFolder},

    [Parameter(ParameterSetName='Restore', Position=2)]
    [switch]
    ${AllReplicas},

    [Parameter(ParameterSetName='Restore', Position=3)]
    [switch]
    ${AllowMove},

    [Parameter(Position=4)]
    [int]
    ${Retries},

    [Parameter(Position=5)]
    [int]
    ${RetryPauseSeconds},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restore-SPFarm { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Directory},

    [Parameter(ParameterSetName='DefaultSet', Mandatory=$true)]
    [ValidateSet('New','Overwrite')]
    [string]
    ${RestoreMethod},

    [Parameter(ParameterSetName='DefaultSet')]
    [int]
    ${RestoreThreads},

    [Parameter(ParameterSetName='DefaultSet')]
    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [guid]
    ${BackupId},

    [Parameter(ParameterSetName='DefaultSet')]
    [string]
    ${NewDatabaseServer},

    [Parameter(ParameterSetName='DefaultSet', ValueFromPipeline=$true)]
    [pscredential]
    ${FarmCredentials},

    [string]
    ${Item},

    [Parameter(ParameterSetName='ShowTree', Mandatory=$true)]
    [switch]
    ${ShowTree},

    [switch]
    ${ConfigurationOnly},

    [Parameter(ParameterSetName='DefaultSet')]
    [int]
    ${Percentage},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Restore-SPSite { 
  [CmdletBinding(DefaultParameterSetName='DatabaseFromPipebind', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]
    ${Path},

    [string]
    ${HostHeaderWebApplication},

    [switch]
    ${Force},

    [switch]
    ${GradualDelete},

    [Parameter(ParameterSetName='DatabaseFromPipebind', ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ParameterSetName='DatabaseParameter')]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='DatabaseParameter')]
    [string]
    ${DatabaseServer},

    [switch]
    ${PreserveSiteID},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Resume-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Resume-SPProjectWebInstance { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Resume-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Revoke-SPBusinessDataCatalogMetadataObject { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Right},

    [string]
    ${SettingId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Revoke-SPObjectSecurity { 
  [CmdletBinding(DefaultParameterSetName='RevokeOne')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='RevokeOne', Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(ParameterSetName='RevokeOne', Position=2)]
    [ValidateNotNull()]
    [string[]]
    ${Rights},

    [Parameter(ParameterSetName='RevokeAll', Mandatory=$true)]
    [switch]
    ${All},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAccessServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateRange(1, 255)]
    [int]
    ${ColumnsMax},

    [ValidateRange(1, 200000)]
    [int]
    ${RowsMax},

    [ValidateRange(1, 20)]
    [int]
    ${SourcesMax},

    [ValidateRange(0, 32)]
    [int]
    ${OutputCalculatedColumnsMax},

    [ValidateRange(0, 8)]
    [int]
    ${OrderByMax},

    [switch]
    ${OuterJoinsAllowed},

    [switch]
    ${NonRemotableQueriesAllowed},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${RecordsInTableMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${ApplicationLogSizeMax},

    [ValidateRange(-1, 2073600)]
    [int]
    ${RequestDurationMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerUserMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerAnonymousUserMax},

    [ValidateRange(-1, 2073600)]
    [int]
    ${CacheTimeout},

    [ValidateRange(0, 4096)]
    [int]
    ${SessionMemoryMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${PrivateBytesMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${TemplateSizeMax},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAccessServicesApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateRange(-1, 2073600)]
    [int]
    ${RequestDurationMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerUserMax},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${SessionsPerAnonymousUserMax},

    [ValidateRange(-1, 2073600)]
    [int]
    ${CacheTimeout},

    [ValidateRange(-1, 2147483647)]
    [int]
    ${PrivateBytesMax},

    [ValidateRange(-1, 1440)]
    [int]
    ${RecoveryPointObjective},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAccessServicesDatabaseServer { 
  [CmdletBinding(DefaultParameterSetName='SetCredentialsParameterSet', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='SetServerStateParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetUserDomainParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetCredentialsParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetAvailableForCreateParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetEncryptParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetSecondaryDatabaseServerNameParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SetFailoverParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='SetAvailableForCreateParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetServerStateParameterSet', Mandatory=$true)]
    [Parameter(Mandatory=$true)]
    [Parameter(ParameterSetName='SetCredentialsParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetEncryptParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetSecondaryDatabaseServerNameParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetFailoverParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetUserDomainParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${DatabaseServerGroup},

    [Parameter(ParameterSetName='SetEncryptParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetSecondaryDatabaseServerNameParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetFailoverParameterSet', Mandatory=$true)]
    [Parameter(Mandatory=$true)]
    [Parameter(ParameterSetName='SetCredentialsParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetAvailableForCreateParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetServerStateParameterSet', Mandatory=$true)]
    [Parameter(ParameterSetName='SetUserDomainParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${DatabaseServer},

    [Parameter(ParameterSetName='SetCredentialsParameterSet')]
    [string]
    ${DatabaseServerName},

    [Parameter(ParameterSetName='SetCredentialsParameterSet')]
    [pscredential]
    ${DatabaseServerCredentials},

    [Parameter(ParameterSetName='SetAvailableForCreateParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [bool]
    ${AvailableForCreate},

    [Parameter(ParameterSetName='SetAvailableForCreateParameterSet')]
    [ValidateNotNullOrEmpty()]
    [bool]
    ${Exclusive},

    [Parameter(ParameterSetName='SetEncryptParameterSet', Mandatory=$true)]
    [bool]
    ${Encrypt},

    [Parameter(ParameterSetName='SetEncryptParameterSet', Mandatory=$true)]
    [bool]
    ${TrustServerCertificate},

    [Parameter(ParameterSetName='SetSecondaryDatabaseServerNameParameterSet')]
    [string]
    ${SecondaryDatabaseServerName},

    [Parameter(ParameterSetName='SetFailoverParameterSet', Mandatory=$true)]
    [bool]
    ${Failover},

    [Parameter(ParameterSetName='SetUserDomainParameterSet', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${UserDomain},

    [Parameter(ParameterSetName='SetServerStateParameterSet', Mandatory=$true)]
    [object]
    ${State},

    [Parameter(ParameterSetName='SetServerStateParameterSet', Mandatory=$true)]
    [object]
    ${StateOwner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAccessServicesDatabaseServerGroupMapping { 
  [CmdletBinding(DefaultParameterSetName='SetDatabaseServerGroupMappingParameter', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${DatabaseServerGroup},

    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter')]
    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName')]
    [switch]
    ${CorporateCatalog},

    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter')]
    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName')]
    [switch]
    ${ObjectModel},

    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter')]
    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName')]
    [switch]
    ${RemoteObjectModel},

    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter')]
    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName')]
    [switch]
    ${DeveloperSite},

    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName')]
    [Parameter(ParameterSetName='SetDatabaseServerGroupMappingParameter')]
    [switch]
    ${StoreFront},

    [Parameter(ParameterSetName='ClearDatabaseServerGroupMappingParameterSetName', Mandatory=$true)]
    [switch]
    ${ClearMapping},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAlternateURL { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Url},

    [object]
    ${Zone},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppAcquisitionConfiguration { 
  [CmdletBinding(DefaultParameterSetName='MarketplaceSettingsInWebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [bool]
    ${Enable},

    [Parameter(ParameterSetName='MarketplaceSettingsInWebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='MarketplaceSettingsInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppAutoProvisionConnection { 
  [CmdletBinding()]
param(
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='WebHostCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='WebHostSetup', Mandatory=$true)]
    [Parameter(ParameterSetName='WebHostEndPoint', Mandatory=$true)]
    [object]
    ${ConnectionType},

    [Parameter(ParameterSetName='WebHostSetup', Mandatory=$true)]
    [Parameter(ParameterSetName='WebHostCredential', Mandatory=$true)]
    [string]
    ${Username},

    [Parameter(ParameterSetName='WebHostCredential', Mandatory=$true)]
    [Parameter(ParameterSetName='WebHostSetup', Mandatory=$true)]
    [string]
    ${Password},

    [Parameter(ParameterSetName='WebHostSetup', Mandatory=$true)]
    [Parameter(ParameterSetName='WebHostEndPoint', Mandatory=$true)]
    [string]
    ${EndPoint},

    [Parameter(ParameterSetName='Remove', Mandatory=$true)]
    [switch]
    ${Remove},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppDisablingConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [bool]
    ${Enable},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppDomain { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [AllowEmptyString()]
    [AllowNull()]
    [string]
    ${AppDomain},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppHostingQuotaConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [double]
    ${AppHostingLicenseQuota},

    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [double]
    ${AppInstanceCountQuota},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppManagementDeploymentId { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [guid]
    ${DeploymentId},

    [Parameter(ValueFromPipeline=$true)]
    [Alias('Subscription')]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${AppManagementServiceApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppPrincipalPermission { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${AppPrincipal},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Scope},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Right},

    [switch]
    ${EnableAppOnlyPolicy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppScaleProfile { 
  [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    ${MaxDatabaseSize},

    [ValidateRange(1, 255)]
    [int]
    ${RemoteWebSiteInstanceCount},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppSiteDomain { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppSiteSubscriptionName { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [object]
    ${SiteSubscription},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppStateUpdateInterval { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 32768)]
    [int]
    ${AppStateSyncHours},

    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 32768)]
    [int]
    ${FastAppRevocationHours},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppStoreConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]
    ${Url},

    [Parameter(Mandatory=$true)]
    [bool]
    ${Enable},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAppStoreWebServiceConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [string]
    ${Client},

    [version]
    ${ProxyVersion},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPAuthenticationRealm { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [string]
    ${Realm},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBingMapsBlock { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, HelpMessage='Block Bing Maps in all locales.')]
    [switch]
    ${BlockBingMapsInAllLocales},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBingMapsKey { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, HelpMessage='Enter the Bing Maps API key.')]
    [string]
    ${BingKey},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBrowserCustomerExperienceImprovementProgram { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(ParameterSetName='Farm', Mandatory=$true)]
    [switch]
    ${Farm},

    [Parameter(ParameterSetName='WebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='SiteSubscription', Mandatory=$true)]
    [object]
    ${SiteSubscription},

    [switch]
    ${Enable},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBusinessDataCatalogEntityNotificationWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Web},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBusinessDataCatalogMetadataObject { 
  [CmdletBinding(DefaultParameterSetName='NameValue', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='Display')]
    [string]
    ${DisplayName},

    [Parameter(ParameterSetName='NameValue')]
    [Parameter(ParameterSetName='NameRemove')]
    [ValidateNotNull()]
    [string]
    ${PropertyName},

    [Parameter(ParameterSetName='NameValue')]
    [psobject]
    ${PropertyValue},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='NameRemove')]
    [switch]
    ${Remove},

    [string]
    ${SettingId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBusinessDataCatalogServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${Sharing},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${DatabaseName},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ApplicationPool},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${DatabaseUsername},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [securestring]
    ${DatabasePassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPBusinessDataCatalogThrottleConfig { 
  [CmdletBinding(DefaultParameterSetName='MaxDefault', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='MaxDefault', Mandatory=$true)]
    [int]
    ${Maximum},

    [Parameter(ParameterSetName='MaxDefault', Mandatory=$true)]
    [int]
    ${Default},

    [Parameter(ParameterSetName='Enforcement', Mandatory=$true)]
    [switch]
    ${Enforced},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPCentralAdministration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [int]
    ${Port},

    [switch]
    ${SecureSocketsLayer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPClaimProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [switch]
    ${Enabled},

    [switch]
    ${Default},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPContentDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateRange(1, 2147483647)]
    [int]
    ${MaxSiteCount},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${WarningSiteCount},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Status},

    [Parameter(ValueFromPipeline=$true)]
    [string]
    ${DatabaseFailoverServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPContentDeploymentJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Description},

    [object]
    ${Scope},

    [string]
    ${Schedule},

    [switch]
    ${ScheduleEnabled},

    [switch]
    ${IncrementalEnabled},

    [object]
    ${SqlSnapshotSetting},

    [switch]
    ${HostingSupportEnabled},

    [object]
    ${EmailNotifications},

    [string[]]
    ${EmailAddresses},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPContentDeploymentPath { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Name},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Description},

    [uri]
    ${DestinationCentralAdministrationURL},

    [object]
    ${Authentication},

    [pscredential]
    ${PathAccount},

    [switch]
    ${DeployUserNamesEnabled},

    [object]
    ${DeploySecurityInformation},

    [switch]
    ${EventReceiversEnabled},

    [switch]
    ${CompressionEnabled},

    [switch]
    ${PathEnabled},

    [object]
    ${KeepTemporaryFilesOptions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPCustomLayoutsPage { 
  [CmdletBinding(DefaultParameterSetName='CustomPage', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='CustomPage', Mandatory=$true)]
    [string]
    ${RelativePath},

    [Parameter(ParameterSetName='CustomPage')]
    [Parameter(ParameterSetName='ResetCustomPage')]
    [ValidateRange(14, 15)]
    [int]
    ${CompatibilityLevel},

    [Parameter(ParameterSetName='ResetCustomPage', Mandatory=$true)]
    [switch]
    ${Reset},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDataConnectionFile { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateLength(0, 255)]
    [string]
    ${DisplayName},

    [ValidateLength(0, 255)]
    [string]
    ${Description},

    [ValidateLength(0, 255)]
    [string]
    ${Category},

    [ValidateSet('true','false')]
    [string]
    ${WebAccessible},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDefaultProfileConfig { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(Mandatory=$true)]
    [bool]
    ${MySitesPublicEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDesignerSettings { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${WebApplication},

    [bool]
    ${AllowDesigner},

    [bool]
    ${AllowRevertFromTemplate},

    [bool]
    ${AllowMasterPageEditing},

    [bool]
    ${ShowURLStructure},

    [string]
    ${RequiredDesignerVersion},

    [string]
    ${DesignerDownloadUrl},

    [bool]
    ${AllowCreateDeclarativeWorkflow},

    [bool]
    ${AllowSavePublishDeclarativeWorkflow},

    [bool]
    ${AllowSaveDeclarativeWorkflowAsTemplate},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDiagnosticConfig { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${AllowLegacyTraceProviders},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${AppAnalyticsAutomaticUploadEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${CustomerExperienceImprovementProgramEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${ErrorReportingEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${ErrorReportingAutomaticUploadEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${DownloadErrorReportingUpdatesEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 366)]
    [int]
    ${DaysToKeepLogs},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${LogMaxDiskSpaceUsageEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1000)]
    [int]
    ${LogDiskSpaceUsageGB},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${LogLocation},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1440)]
    [int]
    ${LogCutInterval},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${EventLogFloodProtectionEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 100)]
    [int]
    ${EventLogFloodProtectionThreshold},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1440)]
    [int]
    ${EventLogFloodProtectionTriggerPeriod},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1440)]
    [int]
    ${EventLogFloodProtectionQuietPeriod},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1440)]
    [int]
    ${EventLogFloodProtectionNotifyInterval},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${ScriptErrorReportingEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${ScriptErrorReportingRequireAuth},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateRange(1, 1440)]
    [int]
    ${ScriptErrorReportingDelay},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDiagnosticsProvider { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Enable},

    [ValidateRange(1, 31)]
    [int]
    ${DaysRetained},

    [ValidateRange(1, 9223372036854775807)]
    [long]
    ${MaxTotalSizeInBytes},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPDistributedCacheClientSetting { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ContainerType},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${DistributedCacheClientSettings},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchAdministrationComponent { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [string]
    ${StoragePath},

    [object]
    ${SearchServiceInstance},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchContentEnrichmentConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${ContentEnrichmentConfiguration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchCrawlContentSource { 
  [CmdletBinding(DefaultParameterSetName='NoSchedule', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Alias('n')]
    [string]
    ${Name},

    [Alias('t')]
    [string]
    ${Tag},

    [Alias('s')]
    [string]
    ${StartAddresses},

    [Alias('p')]
    [object]
    ${CrawlPriority},

    [Parameter(ParameterSetName='Weekly')]
    [Parameter(ParameterSetName='RemoveSchedule')]
    [Parameter(ParameterSetName='MonthlyDate')]
    [Parameter(ParameterSetName='Daily', Mandatory=$true)]
    [object]
    ${ScheduleType},

    [Parameter(ParameterSetName='Daily')]
    [Alias('daily')]
    [switch]
    ${DailyCrawlSchedule},

    [Parameter(ParameterSetName='Weekly')]
    [Alias('weekly')]
    [switch]
    ${WeeklyCrawlSchedule},

    [Parameter(ParameterSetName='MonthlyDate')]
    [Alias('monthly')]
    [switch]
    ${MonthlyCrawlSchedule},

    [Parameter(ParameterSetName='RemoveSchedule')]
    [switch]
    ${RemoveCrawlSchedule},

    [Parameter(ParameterSetName='Daily')]
    [Parameter(ParameterSetName='Weekly')]
    [Parameter(ParameterSetName='MonthlyDate')]
    [Alias('start')]
    [System.Nullable[datetime]]
    ${CrawlScheduleStartDateTime},

    [Parameter(ParameterSetName='MonthlyDate')]
    [Parameter(ParameterSetName='Weekly')]
    [Parameter(ParameterSetName='Daily')]
    [Alias('duration')]
    [System.Nullable[int]]
    ${CrawlScheduleRepeatDuration},

    [Parameter(ParameterSetName='MonthlyDate')]
    [Parameter(ParameterSetName='Daily')]
    [Parameter(ParameterSetName='Weekly')]
    [Alias('interval')]
    [System.Nullable[int]]
    ${CrawlScheduleRepeatInterval},

    [Parameter(ParameterSetName='Daily')]
    [Parameter(ParameterSetName='Weekly')]
    [Alias('every')]
    [System.Nullable[int]]
    ${CrawlScheduleRunEveryInterval},

    [Parameter(ParameterSetName='Weekly')]
    [object]
    ${CrawlScheduleDaysOfWeek},

    [Parameter(ParameterSetName='MonthlyDate')]
    [System.Nullable[int]]
    ${CrawlScheduleDaysOfMonth},

    [Parameter(ParameterSetName='MonthlyDate')]
    [Alias('month')]
    [object]
    ${CrawlScheduleMonthsOfYear},

    [System.Nullable[int]]
    ${MaxPageEnumerationDepth},

    [System.Nullable[int]]
    ${MaxSiteEnumerationDepth},

    [object]
    ${BDCApplicationProxyGroup},

    [string[]]
    ${LOBSystemSet},

    [string]
    ${CustomProtocol},

    [System.Nullable[bool]]
    ${EnableContinuousCrawls},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchCrawlDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchCrawlLogReadPermission { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [guid]
    ${Tenant},

    [string]
    ${UserNames},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchCrawlRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Alias('t')]
    [object]
    ${Type},

    [System.Nullable[bool]]
    ${IsAdvancedRegularExpression},

    [System.Nullable[bool]]
    ${CrawlAsHttp},

    [System.Nullable[bool]]
    ${FollowComplexUrls},

    [System.Nullable[int]]
    ${PluggableSecurityTimmerId},

    [System.Nullable[bool]]
    ${SuppressIndexing},

    [System.Nullable[int]]
    ${Priority},

    [string]
    ${ContentClass},

    [object]
    ${AuthenticationType},

    [string]
    ${AccountName},

    [securestring]
    ${AccountPassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchFileFormatState { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [bool]
    ${Enable},

    [Parameter(Position=2)]
    [System.Nullable[bool]]
    ${UseIFilter},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchLinguisticComponentsStatus { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [System.Nullable[bool]]
    ${ThesaurusEnabled},

    [System.Nullable[bool]]
    ${StemmingEnabled},

    [System.Nullable[bool]]
    ${QuerySpellingEnabled},

    [System.Nullable[bool]]
    ${EntityExtractionEnabled},

    [System.Nullable[bool]]
    ${AllEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchLinksDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchMetadataCategory { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Alias('n')]
    [string]
    ${Name},

    [Alias('d')]
    [System.Nullable[bool]]
    ${DiscoverNewProperties},

    [Alias('m')]
    [System.Nullable[bool]]
    ${MapToContents},

    [Alias('auto')]
    [System.Nullable[bool]]
    ${AutoCreateNewManagedProperties},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchMetadataCrawledProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [Alias('im')]
    [System.Nullable[bool]]
    ${IsMappedToContents},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchMetadataManagedProperty { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Alias('n')]
    [string]
    ${Name},

    [Alias('d')]
    [string]
    ${Description},

    [Alias('f')]
    [System.Nullable[bool]]
    ${FullTextQueriable},

    [Alias('r')]
    [System.Nullable[bool]]
    ${Retrievable},

    [Alias('e')]
    [System.Nullable[bool]]
    ${EnabledForScoping},

    [Alias('nn')]
    [System.Nullable[bool]]
    ${NameNormalized},

    [Alias('rp')]
    [System.Nullable[bool]]
    ${RespectPriority},

    [Alias('rd')]
    [System.Nullable[bool]]
    ${RemoveDuplicates},

    [Alias('im5')]
    [Obsolete('This property is replaced by IncludeInAlertSignature.')]
    [System.Nullable[bool]]
    ${IncludeInMd5},

    [Alias('ia')]
    [System.Nullable[bool]]
    ${IncludeInAlertSignature},

    [Alias('sfa')]
    [System.Nullable[bool]]
    ${SafeForAnonymous},

    [Alias('nw')]
    [System.Nullable[bool]]
    ${NoWordBreaker},

    [Alias('u')]
    [System.Nullable[int16]]
    ${UserFlags},

    [Alias('qir')]
    [System.Nullable[bool]]
    ${EnabledForQueryIndependentRank},

    [Alias('def')]
    [System.Nullable[uint32]]
    ${DefaultForQueryIndependentRank},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchMetadataMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [object]
    ${ManagedProperty},

    [object]
    ${CrawledProperty},

    [guid]
    ${Tenant},

    [guid]
    ${SiteCollection},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchPrimaryHostController { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${SearchServiceInstance},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchQueryAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Alias('l')]
    [System.Nullable[float]]
    ${Level},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchQueryKeyword { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Alias('t')]
    [string]
    ${Term},

    [Alias('d')]
    [string]
    ${Definition},

    [Alias('c')]
    [string]
    ${Contact},

    [Alias('s')]
    [System.Nullable[datetime]]
    ${StartDate},

    [Alias('e')]
    [System.Nullable[datetime]]
    ${EndDate},

    [Alias('r')]
    [System.Nullable[datetime]]
    ${ReviewDate},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchQueryScope { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [uri]
    ${Url},

    [Parameter(Mandatory=$true)]
    [Alias('u')]
    [string]
    ${AlternateResultsPage},

    [Alias('n')]
    [string]
    ${Name},

    [Alias('d')]
    [string]
    ${Description},

    [Alias('disp')]
    [System.Nullable[bool]]
    ${DisplayInAdminUI},

    [Alias('type')]
    [System.Nullable[int]]
    ${CompilationType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchQueryScopeRule { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('u')]
    [uri]
    ${Url},

    [Alias('n')]
    [object]
    ${Scope},

    [Alias('f')]
    [string]
    ${FilterBehavior},

    [Alias('ut')]
    [string]
    ${UrlScopeRuleType},

    [Alias('text')]
    [string]
    ${MatchingString},

    [Alias('value')]
    [string]
    ${PropertyValue},

    [Alias('mname')]
    [string]
    ${ManagedPropertyName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchQuerySpellingCorrection { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [object]
    ${SearchApplication},

    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [System.Nullable[bool]]
    ${ContentAlignmentEnabled},

    [System.Nullable[int]]
    ${MaxDictionarySize},

    [System.Nullable[bool]]
    ${DiacriticsInSuggestionsEnabled},

    [System.Nullable[int]]
    ${TermFrequencyThreshold},

    [System.Nullable[bool]]
    ${SecurityTrimmingEnabled},

    [object]
    ${SpellingDictionary},

    [System.Nullable[timespan]]
    ${MaxProcessingTime},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchRankingModel { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Parameter(Mandatory=$true)]
    [string]
    ${RankingModelXML},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchResultItemType { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplicationProxy},

    [Alias('n')]
    [string]
    ${Name},

    [Alias('rule')]
    [object]
    ${Rules},

    [Alias('priority')]
    [System.Nullable[int]]
    ${RulePriority},

    [Alias('dp')]
    [string]
    ${DisplayProperties},

    [Alias('sid')]
    [System.Nullable[guid]]
    ${SourceID},

    [Alias('url')]
    [string]
    ${DisplayTemplateUrl},

    [Parameter(Mandatory=$true)]
    [Alias('o')]
    [object]
    ${Owner},

    [Alias('opt')]
    [System.Nullable[bool]]
    ${OptimizeForFrequentUse},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchResultSource { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SearchApplication},

    [Alias('o')]
    [object]
    ${Owner},

    [string]
    ${Name},

    [string]
    ${Description},

    [string]
    ${QueryTemplate},

    [guid]
    ${ProviderId},

    [string]
    ${RemoteUrl},

    [System.Nullable[bool]]
    ${AutoDiscover},

    [object]
    ${AuthenticationType},

    [string]
    ${UserName},

    [string]
    ${Password},

    [string]
    ${SsoId},

    [System.Nullable[bool]]
    ${MakeDefault},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${ServiceAccount},

    [securestring]
    ${ServicePassword},

    [string]
    ${ContactEmail},

    [string]
    ${ConnectionTimeout},

    [string]
    ${AcknowledgementTimeout},

    [string]
    ${ProxyType},

    [string]
    ${IgnoreSSLWarnings},

    [string]
    ${InternetIdentity},

    [string]
    ${PerformanceLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${FailoverDatabaseServer},

    [string]
    ${DiacriticSensitive},

    [object]
    ${DefaultSearchProvider},

    [string]
    ${VerboseQueryMonitoring},

    [object]
    ${ApplicationPool},

    [object]
    ${AdminApplicationPool},

    [string]
    ${DefaultContentAccessAccountName},

    [securestring]
    ${DefaultContentAccessAccountPassword},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseUsername},

    [securestring]
    ${DatabasePassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${DefaultIndexLocation},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPEnterpriseSearchTopology { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${SearchApplication},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPFarmConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [int]
    ${WorkflowBatchSize},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [int]
    ${WorkflowPostponeThreshold},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [int]
    ${WorkflowEventDeliveryTimeout},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${InstalledProductsRefresh},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [bool]
    ${DataFormWebPartAutoRefreshEnabled},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [bool]
    ${ASPScriptOptimizationEnabled},

    [switch]
    ${ServiceConnectionPointDelete},

    [string]
    ${ServiceConnectionPointBindingInformation},

    [object]
    ${SiteMasterMode},

    [System.Nullable[uint32]]
    ${SiteMasterValidationIntervalInHours},

    [System.Nullable[bool]]
    ${DefaultActivateOnSiteMasterValue},

    [switch]
    ${Force},

    [System.Nullable[switch]]
    ${UserAccountDirectoryPathIsImmutable},

    [System.Nullable[uint32]]
    ${MaxTenantStoreValueLength},

    [System.Nullable[uint32]]
    ${MaxSiteSubscriptionSettingsValueLength},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPInfoPathFormsService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${Identity},

    [ValidateSet('true','false')]
    [string]
    ${AllowUserFormBrowserEnabling},

    [ValidateSet('true','false')]
    [string]
    ${AllowUserFormBrowserRendering},

    [ValidateRange(0, 2147483647)]
    [System.Nullable[int]]
    ${DefaultDataConnectionTimeout},

    [ValidateRange(0, 2147483647)]
    [System.Nullable[int]]
    ${MemoryCacheSize},

    [ValidateRange(0, 2147483647)]
    [System.Nullable[int]]
    ${MaxDataConnectionTimeout},

    [ValidateRange(0, 2147483647)]
    [System.Nullable[int]]
    ${MaxDataConnectionResponseSize},

    [ValidateSet('true','false')]
    [string]
    ${RequireSslForDataConnections},

    [ValidateSet('true','false')]
    [string]
    ${AllowEmbeddedSqlForDataConnections},

    [ValidateSet('true','false')]
    [string]
    ${AllowUdcAuthenticationForDataConnections},

    [ValidateSet('true','false')]
    [string]
    ${AllowUserFormCrossDomainDataConnections},

    [ValidateRange(0, 999999)]
    [System.Nullable[int]]
    ${MaxPostbacksPerSession},

    [ValidateRange(0, 999999)]
    [System.Nullable[int]]
    ${MaxUserActionsPerPostback},

    [ValidateRange(0, 999999)]
    [System.Nullable[int]]
    ${ActiveSessionTimeout},

    [ValidateRange(0, 99999999)]
    [System.Nullable[int]]
    ${MaxSizeOfUserFormState},

    [ValidateSet('true','false')]
    [string]
    ${AllowViewState},

    [ValidateRange(0, 99999999)]
    [System.Nullable[int]]
    ${ViewStateThreshold},

    [ValidateRange(0, 99999999)]
    [System.Nullable[int]]
    ${MaxFormLoadTime},

    [ValidateRange(0, 99999999)]
    [System.Nullable[int]]
    ${MaxDataConnectionRoundTrip},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateLength(0, 255)]
    [string]
    ${Category},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPInfoPathWebServiceProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateSet('true','false')]
    [string]
    ${AllowWebServiceProxy},

    [ValidateSet('true','false')]
    [string]
    ${AllowForUserForms},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPInternalAppStateUpdateInterval { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 32768)]
    [int]
    ${AppStateSyncHours},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPIRMSettings { 
  [CmdletBinding(DefaultParameterSetName='UseServiceDiscovery', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [switch]
    ${IrmEnabled},

    [switch]
    ${SubscriptionScopeSettingsEnabled},

    [Parameter(ParameterSetName='UseServiceDiscovery')]
    [switch]
    ${UseActiveDirectoryDiscovery},

    [Parameter(ParameterSetName='UseSpecifiedCertificateUrl', Mandatory=$true)]
    [uri]
    ${CertificateServerUrl},

    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${ServiceAuthenticationCertificate},

    [ValidateNotNull()]
    [securestring]
    ${CertificatePassword},

    [switch]
    ${UseOauth},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPLogLevel { 
  [CmdletBinding()]
param(
    [string]
    ${TraceSeverity},

    [string]
    ${EventSeverity},

    [string[]]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPManagedAccount { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Schedule},

    [int]
    ${PreExpireDays},

    [int]
    ${EmailNotification},

    [Parameter(ParameterSetName='AutoGeneratePassword')]
    [switch]
    ${AutoGeneratePassword},

    [Parameter(ParameterSetName='NewPasswordAsParameter', Mandatory=$true)]
    [securestring]
    ${Password},

    [Parameter(ParameterSetName='NewPassword')]
    [switch]
    ${SetNewPassword},

    [Parameter(ParameterSetName='NewPassword', Mandatory=$true)]
    [securestring]
    ${NewPassword},

    [Parameter(ParameterSetName='NewPassword', Mandatory=$true)]
    [securestring]
    ${ConfirmPassword},

    [Parameter(ParameterSetName='ExistingPassword')]
    [switch]
    ${UseExistingPassword},

    [Parameter(ParameterSetName='ExistingPassword', Mandatory=$true)]
    [securestring]
    ${ExistingPassword},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPMetadataServiceApplication { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [string]
    ${AdministratorAccount},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [string]
    ${DatabaseName},

    [string]
    ${DatabaseServer},

    [pscredential]
    ${DatabaseCredentials},

    [string]
    ${FailoverDatabaseServer},

    [string]
    ${FullAccessAccount},

    [string]
    ${HubUri},

    [int]
    ${CacheTimeCheckInterval},

    [int]
    ${MaxChannelCache},

    [switch]
    ${DoNotUnpublishAllPackages},

    [Parameter(ParameterSetName='NoQuota', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Quota', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Default', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [string]
    ${ReadAccessAccount},

    [string]
    ${RestrictedAccount},

    [switch]
    ${SyndicationErrorReportEnabled},

    [Parameter(ParameterSetName='NoQuota', Mandatory=$true)]
    [switch]
    ${DisablePartitionQuota},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${GroupsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${TermSetsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${TermsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${LabelsPerPartition},

    [Parameter(ParameterSetName='Quota', Mandatory=$true)]
    [ValidateRange(0, 2147483647)]
    [int]
    ${PropertiesPerPartition},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPMetadataServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]
    ${ContentTypeSyndicationEnabled},

    [switch]
    ${ContentTypePushdownEnabled},

    [switch]
    ${DefaultKeywordTaxonomy},

    [switch]
    ${DefaultProxyGroup},

    [switch]
    ${DefaultSiteCollectionTaxonomy},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPMicrofeedOptions { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [ValidateNotNull()]
    [int]
    ${MaxPostLength},

    [ValidateNotNull()]
    [int]
    ${MaxMentions},

    [ValidateNotNull()]
    [int]
    ${MaxTags},

    [ValidateNotNull()]
    [System.Nullable[bool]]
    ${AsyncRefs},

    [ValidateNotNull()]
    [int]
    ${MaxCacheMs},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPMobileMessagingAccount { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [Alias('ServiceType','AccountType')]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [string]
    ${ServiceName},

    [string]
    ${ServiceUrl},

    [string]
    ${UserId},

    [string]
    ${Password},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPO365LinkSettings { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]
    ${MySiteHostUrl},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${Audiences},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [bool]
    ${RedirectSites},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [bool]
    ${HybridAppLauncherEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPODataConnectionSetting { 
  [CmdletBinding(DefaultParameterSetName='Name', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='Name', Mandatory=$true)]
    [ValidateNotNull()]
    [ValidateLength(0, 246)]
    [string]
    ${Name},

    [ValidateNotNull()]
    [uri]
    ${ServiceAddressURL},

    [ValidateNotNull()]
    [object]
    ${AuthenticationMode},

    [ValidateLength(0, 1024)]
    [ValidateNotNull()]
    [string]
    ${SecureStoreTargetApplicationId},

    [string]
    ${ExtensionProvider},

    [Parameter(ParameterSetName='Identity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPODataConnectionSettingMetadata { 
  [CmdletBinding(DefaultParameterSetName='Name', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceContext},

    [Parameter(ParameterSetName='Name', Mandatory=$true)]
    [ValidateLength(0, 255)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [uri]
    ${ServiceAddressMetadataURL},

    [ValidateNotNull()]
    [object]
    ${AuthenticationMode},

    [ValidateLength(0, 1024)]
    [ValidateNotNull()]
    [string]
    ${SecureStoreTargetApplicationId},

    [Parameter(ParameterSetName='Identity', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPOfficeStoreAppsDefaultActivation { 
  [CmdletBinding(DefaultParameterSetName='AppsForOfficeSettingsInWebApplication', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [bool]
    ${Enable},

    [Parameter(ParameterSetName='AppsForOfficeSettingsInWebApplication', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='AppsForOfficeSettingsInSiteSubscription', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPPassPhrase { 
  [CmdletBinding(DefaultParameterSetName='AcrossFarm', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [securestring]
    ${PassPhrase},

    [Parameter(ParameterSetName='AcrossFarm', Mandatory=$true)]
    [securestring]
    ${ConfirmPassPhrase},

    [Parameter(ParameterSetName='LocalOnly')]
    [switch]
    ${LocalServerOnly},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPPerformancePointSecureDataValues { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ServiceApplication},

    [Parameter(Mandatory=$true)]
    [pscredential]
    ${DataSourceUnattendedServiceAccount},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPPerformancePointServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${ApplicationPool},

    [bool]
    ${CommentsDisabled},

    [int]
    ${CommentsScorecardMax},

    [int]
    ${IndicatorImageCacheSeconds},

    [int]
    ${DataSourceQueryTimeoutSeconds},

    [int]
    ${FilterRememberUserSelectionsDays},

    [int]
    ${FilterTreeMembersMax},

    [int]
    ${FilterSearchResultsMax},

    [int]
    ${ShowDetailsInitialRows},

    [bool]
    ${ShowDetailsMaxRowsDisabled},

    [int]
    ${ShowDetailsMaxRows},

    [bool]
    ${MSMQEnabled},

    [string]
    ${MSMQName},

    [int]
    ${SessionHistoryHours},

    [bool]
    ${AnalyticQueryLoggingEnabled},

    [bool]
    ${TrustedDataSourceLocationsRestricted},

    [bool]
    ${TrustedContentLocationsRestricted},

    [int]
    ${SelectMeasureMaximum},

    [int]
    ${DecompositionTreeMaximum},

    [bool]
    ${ApplicationProxyCacheEnabled},

    [bool]
    ${ApplicationCacheEnabled},

    [int]
    ${ApplicationCacheMinimumHitCount},

    [int]
    ${AnalyticResultCacheMinimumHitCount},

    [int]
    ${ElementCacheSeconds},

    [int]
    ${AnalyticQueryCellMax},

    [string]
    ${SettingsDatabase},

    [string]
    ${DatabaseServer},

    [string]
    ${DatabaseName},

    [pscredential]
    ${DatabaseSQLAuthenticationCredential},

    [string]
    ${DatabaseFailoverServer},

    [bool]
    ${DatabaseUseWindowsAuthentication},

    [string]
    ${DataSourceUnattendedServiceAccountTargetApplication},

    [bool]
    ${UseEffectiveUserName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPPowerPointConversionServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [uint32]
    ${CacheExpirationPeriodInSeconds},

    [uint32]
    ${WorkerProcessCount},

    [uint32]
    ${WorkerKeepAliveTimeoutInSeconds},

    [uint32]
    ${WorkerTimeoutInSeconds},

    [uint32]
    ${MaximumConversionsPerWorker},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProfileServiceApplication { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [string]
    ${Name},

    [object]
    ${ApplicationPool},

    [pscredential]
    ${ProfileDBCredentials},

    [string]
    ${ProfileDBFailoverServer},

    [pscredential]
    ${SocialDBCredentials},

    [string]
    ${SocialDBFailoverServer},

    [pscredential]
    ${ProfileSyncDBCredentials},

    [string]
    ${ProfileSyncDBFailoverServer},

    [Parameter(ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='MySiteSettings', Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${MySiteHostLocation},

    [Parameter(ParameterSetName='MySiteSettings', ValueFromPipeline=$true)]
    [object]
    ${MySiteManagedPath},

    [Parameter(ParameterSetName='MySiteSettings')]
    [ValidateSet('None','Resolve','Block')]
    [string]
    ${SiteNamingConflictResolution},

    [bool]
    ${PurgeNonImportedObjects},

    [bool]
    ${UseOnlyPreferredDomainControllers},

    [bool]
    ${GetNonImportedObjects},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProfileServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [string]
    ${Name},

    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${MySiteHostLocation},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${MySiteManagedPath},

    [ValidateSet('None','Resolve','Block')]
    [string]
    ${SiteNamingConflictResolution},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProfileServiceApplicationSecurity { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${SiteSubscription},

    [ValidateSet('UserACL','MySiteReaderACL')]
    [string]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectDatabaseQuota { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ParameterSetName='settings', Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${Settings},

    [Parameter(ParameterSetName='options', Mandatory=$true)]
    [switch]
    ${Enabled},

    [Parameter(ParameterSetName='options', Mandatory=$true)]
    [ValidateRange(0, 1024000)]
    [int]
    ${ReadOnlyLimit},

    [Parameter(ParameterSetName='options', Mandatory=$true)]
    [ValidateRange(0, 100)]
    [int]
    ${ReadOnlyWarningThreshold},

    [Parameter(ParameterSetName='options', Mandatory=$true)]
    [ValidateRange(0, 1024000)]
    [int]
    ${MaxDbSize},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectEventServiceSettings { 
  [CmdletBinding()]
param(
    [System.Nullable[int]]
    ${NetTcpPort},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectOdataConfiguration { 
  [CmdletBinding()]
param(
    [bool]
    ${UseVerboseErrors},

    [ValidateRange(1, 2147483647)]
    [int]
    ${MaxResultsPerCollection},

    [bool]
    ${AcceptCountRequests},

    [bool]
    ${AcceptProjectionRequests},

    [ValidateRange(1, 2147483647)]
    [int]
    ${DefaultMaxPageSize},

    [switch]
    ${ClearEntityPageSizeOverrides},

    [string]
    ${EntitySetName},

    [ValidateRange(1, 2147483647)]
    [int]
    ${PageSizeOverride},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectPCSSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [System.Nullable[int]]
    ${MaximumIdleWorkersCount},

    [System.Nullable[int]]
    ${MaximumWorkersCount},

    [System.Nullable[int]]
    ${EditingSessionTimeout},

    [System.Nullable[int]]
    ${MaximumSessionsPerUser},

    [System.Nullable[int]]
    ${CachePersistence},

    [System.Nullable[int]]
    ${MinimumMemoryRequired},

    [System.Nullable[int]]
    ${RequestTimeLimits},

    [System.Nullable[int]]
    ${MaximumProjectSize},

    [System.Nullable[int]]
    ${NetTcpPort},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectPermissionMode { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('SharePoint','ProjectServer')]
    [object]
    ${Mode},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectQueueSettings { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [Alias('sa')]
    [object]
    ${ServiceApplication},

    [System.Nullable[int]]
    ${MaxDegreeOfConcurrency},

    [System.Nullable[int]]
    ${MsgRetryInterval},

    [System.Nullable[int]]
    ${MsgRetryLimit},

    [System.Nullable[int]]
    ${SqlRetryInterval},

    [System.Nullable[int]]
    ${SqlRetryLimit},

    [System.Nullable[int]]
    ${SqlCommandTimeout},

    [System.Nullable[int]]
    ${CleanupSuccessAgeLimit},

    [System.Nullable[int]]
    ${CleanupNonSuccessAgeLimit},

    [System.Nullable[int]]
    ${PeriodicTasksInterval},

    [System.Nullable[int]]
    ${QueueTimeout},

    [System.Nullable[int]]
    ${MaxConnections},

    [System.Nullable[int]]
    ${NetTcpPort},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [object]
    ${ApplicationPool},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectUserSync { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Value},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectUserSyncDisabledSyncThreshold { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${Threshold},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectUserSyncFullSyncThreshold { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${Threshold},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPProjectUserSyncOffPeakSyncThreshold { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(Mandatory=$true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${Threshold},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPRequestManagementSettings { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [System.Nullable[switch]]
    ${RoutingEnabled},

    [ValidateNotNull()]
    [System.Nullable[switch]]
    ${ThrottlingEnabled},

    [ValidateNotNull()]
    [object]
    ${RoutingScheme},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPRoutingMachineInfo { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [object]
    ${Availability},

    [ValidateNotNull()]
    [object]
    ${OutgoingScheme},

    [ValidateRange(1, 65535)]
    [ValidateNotNull()]
    [System.Nullable[int]]
    ${OutgoingPort},

    [ValidateNotNull()]
    [switch]
    ${ClearOutgoingPort},

    [ValidateNotNull()]
    [System.Nullable[double]]
    ${StaticWeight},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPRoutingMachinePool { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [object]
    ${MachineTargets},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPRoutingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [object]
    ${Criteria},

    [object]
    ${MachinePool},

    [ValidateNotNull()]
    [System.Nullable[int]]
    ${ExecutionGroup},

    [ValidateNotNull()]
    [System.Nullable[datetime]]
    ${Expiration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPScaleOutDatabaseDataRange { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [object]
    ${Range},

    [byte[]]
    ${NewRangePoint},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPScaleOutDatabaseDataSubRange { 
  [CmdletBinding(DefaultParameterSetName='AttachedDatabase', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AttachedDatabase', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(ParameterSetName='UnattachedDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ConnectionString},

    [Parameter(ParameterSetName='UnattachedDatabase')]
    [switch]
    ${IsAzureDatabase},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Range},

    [byte[]]
    ${SubRangePoint},

    [Parameter(Mandatory=$true)]
    [object]
    ${SubRangeMode},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [switch]
    ${IgnoreSubRangePointOnBoundary},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSecureStoreApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${Administrator},

    [object]
    ${CredentialsOwnerGroup},

    [object]
    ${Fields},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [object]
    ${TargetApplication},

    [object]
    ${TicketRedeemer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSecureStoreDefaultProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [type]
    ${Type},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSecureStoreServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [object]
    ${ApplicationPool},

    [switch]
    ${AuditingEnabled},

    [System.Nullable[int]]
    ${AuditlogMaxSize},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${DatabaseName},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [securestring]
    ${DatabasePassword},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${DatabaseUsername},

    [Parameter(ParameterSetName='NoMinDBSet')]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Sharing},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSecurityTokenServiceConfig { 
  [CmdletBinding(DefaultParameterSetName='SigningCertificateImport', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='SigningCertificateImport')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${ImportSigningCertificate},

    [Parameter(ParameterSetName='SigningCertificateReference')]
    [string]
    ${SigningCertificateThumbprint},

    [Parameter(ParameterSetName='SigningCertificateReference')]
    [string]
    ${SigningCertificateStoreName},

    [Parameter(ParameterSetName='SigningCertificateQueue')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${QueueSigningCertificate},

    [Parameter(ParameterSetName='SigningCertificateReference')]
    [string]
    ${QueueSigningCertificateThumbprint},

    [Parameter(ParameterSetName='SigningCertificateReference')]
    [string]
    ${QueueSigningCertificateStoreName},

    [Parameter(ParameterSetName='SigningCertificateRevoke')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${RevokeSigningCertificate},

    [Parameter(ParameterSetName='RevokeSigningCertificateReference', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RevokeSigningCertificateThumbprint},

    [Parameter(ParameterSetName='RevokeSigningCertificateReference')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${RevokeSigningCertificateStoreName},

    [int]
    ${ServiceTokenLifetime},

    [int]
    ${ServiceTokenCacheExpirationWindow},

    [int]
    ${FormsTokenLifetime},

    [int]
    ${WindowsTokenLifetime},

    [int]
    ${MaxLogonTokenCacheItems},

    [int]
    ${MaxServiceTokenCacheItems},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServer { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Address')]
    [object]
    ${Identity},

    [object]
    ${Status},

    [ValidateSet('Application','ApplicationWithSearch','Custom','DistributedCache','Search','SingleServerFarm','WebFrontEnd','WebFrontEndWithDistributedCache')]
    [object]
    ${Role},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServerScaleOutDatabaseDataRange { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Database},

    [Parameter(Mandatory=$true)]
    [object]
    ${Range},

    [byte[]]
    ${NewRangePoint},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServerScaleOutDatabaseDataSubRange { 
  [CmdletBinding(DefaultParameterSetName='AttachedDatabase', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AttachedDatabase', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Database},

    [Parameter(ParameterSetName='UnattachedDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${ConnectionString},

    [Parameter(ParameterSetName='UnattachedDatabase')]
    [switch]
    ${IsAzureDatabase},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Range},

    [byte[]]
    ${SubRangePoint},

    [Parameter(Mandatory=$true)]
    [object]
    ${SubRangeMode},

    [Parameter(Mandatory=$true)]
    [bool]
    ${IsUpperSubRange},

    [switch]
    ${IgnoreSubRangePointOnBoundary},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [object]
    ${DefaultEndpoint},

    [ValidateNotNull()]
    [object]
    ${ServiceApplicationProxyGroup},

    [ValidateNotNull()]
    [object]
    ${IisWebServiceApplicationPool},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServiceApplicationEndpoint { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='HostName', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${HostName},

    [Parameter(ParameterSetName='ResetHostName', Mandatory=$true)]
    [switch]
    ${ResetHostName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServiceApplicationPool { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Position=1)]
    [object]
    ${Account},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServiceApplicationSecurity { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNull()]
    [object]
    ${ObjectSecurity},

    [switch]
    ${Admin},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPServiceHostConfig { 
  [CmdletBinding(DefaultParameterSetName='SslCertificateImport', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='SslCertificateReference', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='SslCertificateImport', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='SslCertificateReference')]
    [Parameter(ParameterSetName='SslCertificateImport')]
    [Alias('Port')]
    [ValidateRange(1, 65535)]
    [int]
    ${HttpPort},

    [Parameter(ParameterSetName='SslCertificateReference')]
    [Parameter(ParameterSetName='SslCertificateImport')]
    [Alias('SecurePort')]
    [ValidateRange(1, 65535)]
    [int]
    ${HttpsPort},

    [Parameter(ParameterSetName='SslCertificateImport')]
    [Parameter(ParameterSetName='SslCertificateReference')]
    [ValidateRange(1, 65535)]
    [int]
    ${NetTcpPort},

    [Parameter(ParameterSetName='SslCertificateReference', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SslCertificateThumbprint},

    [Parameter(ParameterSetName='SslCertificateReference')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SslCertificateStoreName},

    [Parameter(ParameterSetName='SslCertificateImport')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${ImportSslCertificate},

    [switch]
    ${NoWait},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSessionStateService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [System.Nullable[int]]
    ${SessionTimeout},

    [Parameter(ParameterSetName='AdvancedProvision')]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSite { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${OwnerAlias},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${QuotaTemplate},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${Template},

    [Parameter(ParameterSetName='Default')]
    [string]
    ${Url},

    [Parameter(ParameterSetName='Default')]
    [long]
    ${MaxSize},

    [Parameter(ParameterSetName='Default')]
    [long]
    ${WarningSize},

    [Parameter(ParameterSetName='Default')]
    [string]
    ${SharingType},

    [Parameter(ParameterSetName='Default')]
    [ValidateSet('Unlock','NoAdditions','ReadOnly','NoAccess')]
    [string]
    ${LockState},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${SecondaryOwnerAlias},

    [Parameter(ParameterSetName='Default')]
    [string]
    ${UserAccountDirectoryPath},

    [Parameter(ParameterSetName='SiteSubscription')]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='SiteSubscription')]
    [switch]
    ${Force},

    [object]
    ${AdministrationSiteType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteAdministration { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${OwnerAlias},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${SecondaryOwnerAlias},

    [Parameter(ParameterSetName='Default')]
    [object]
    ${Template},

    [Parameter(ParameterSetName='Default')]
    [ValidateSet('Unlock','NoAdditions','ReadOnly','NoAccess')]
    [string]
    ${LockState},

    [Parameter(ParameterSetName='Default')]
    [long]
    ${MaxSize},

    [Parameter(ParameterSetName='Default')]
    [long]
    ${WarningSize},

    [Parameter(ParameterSetName='SiteSubscription')]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='SiteSubscription')]
    [switch]
    ${Force},

    [object]
    ${AdministrationSiteType},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteSubscriptionConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${UserAccountDirectoryPath},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${FeaturePack},

    [switch]
    ${PassThru},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteSubscriptionEdiscoveryHub { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${SearchScope},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteSubscriptionIRMConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${IrmEnabled},

    [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [uri]
    ${CertificateServerUrl},

    [switch]
    ${PassThru},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteSubscriptionMetadataConfig { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ServiceProxy},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${HubUri},

    [switch]
    ${DoNotUnpublishAllPackages},

    [switch]
    ${SyndicationErrorReportEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteSubscriptionProfileConfig { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ParameterSetName='MySiteSettings', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${MySiteHostLocation},

    [Parameter(ParameterSetName='MySiteSettings', ValueFromPipeline=$true)]
    [object]
    ${MySiteManagedPath},

    [Parameter(ParameterSetName='MySiteSettings')]
    [ValidateSet('None','Resolve','Block')]
    [string]
    ${SiteNamingConflictResolution},

    [string]
    ${SynchronizationOU},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSiteURL { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${Zone},

    [Parameter(Mandatory=$true)]
    [string]
    ${Url},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPStateServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPStateServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('Application')]
    [object]
    ${ServiceApplication},

    [ValidateRange(1, 10)]
    [System.Nullable[int]]
    ${Weight},

    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPSubscriptionSettingsServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${FailoverDatabaseServer},

    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPThrottlingRule { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNull()]
    [object]
    ${Criteria},

    [ValidateRange(0, 10)]
    [ValidateNotNull()]
    [System.Nullable[int]]
    ${Threshold},

    [ValidateNotNull()]
    [System.Nullable[datetime]]
    ${Expiration},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTimerJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Schedule},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTopologyServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [string]
    ${LoadBalancerUrl},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTopologyServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [string]
    ${BadListPeriod},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTranslationServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [string]
    ${DatabaseName},

    [pscredential]
    ${DatabaseCredential},

    [string]
    ${DatabaseServer},

    [string]
    ${FailoverDatabaseServer},

    [System.Nullable[int]]
    ${TimerJobFrequency},

    [System.Nullable[int]]
    ${MaximumTranslationAttempts},

    [System.Nullable[int]]
    ${KeepAliveTimeout},

    [System.Nullable[int]]
    ${MaximumTranslationTime},

    [System.Nullable[int]]
    ${TranslationsPerInstance},

    [System.Nullable[int]]
    ${MaximumSyncTranslationRequests},

    [System.Nullable[int]]
    ${RecycleProcessThreshold},

    [System.Nullable[int]]
    ${TotalActiveProcesses},

    [string]
    ${MachineTranslationClientId},

    [string]
    ${MachineTranslationCategory},

    [switch]
    ${UseDefaultInternetSettings},

    [string]
    ${WebProxyAddress},

    [string]
    ${MachineTranslationAddress},

    [System.Nullable[int]]
    ${JobExpirationDays},

    [System.Nullable[int]]
    ${MaximumItemsPerDay},

    [System.Nullable[int]]
    ${MaximumItemsPerPartitionPerDay},

    [System.Nullable[int]]
    ${MaximumBinaryFileSize},

    [System.Nullable[int]]
    ${MaximumTextFileSize},

    [System.Nullable[int]]
    ${MaximumWordCharacterCount},

    [System.Nullable[bool]]
    ${DisableBinaryFileScan},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [string[]]
    ${AddEnabledFileExtensions},

    [string[]]
    ${RemoveEnabledFileExtensions},

    [switch]
    ${ClearEnabledFileExtensions},

    [switch]
    ${EnableAllFileExtensions},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTranslationServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [System.Nullable[int]]
    ${MaximumGroupSize},

    [System.Nullable[int]]
    ${MaximumItemCount},

    [switch]
    ${DefaultProxyGroup},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTranslationThrottlingSetting { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [System.Nullable[int]]
    ${SiteQuota},

    [System.Nullable[int]]
    ${TenantQuota},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTrustedIdentityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='BasicParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='ImportCertificateParameterSet', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [Parameter(ParameterSetName='ImportCertificateParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ImportTrustCertificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet', Mandatory=$true)]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [object]
    ${ClaimsMappings},

    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SignInUrl},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [object]
    ${ClaimProvider},

    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [string]
    ${Realm},

    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [switch]
    ${UseWReply},

    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [Parameter(ParameterSetName='BasicParameterSet')]
    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [string]
    ${RegisteredIssuerName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTrustedRootAuthority { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='ManualUpdateCertificateParameterSet')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTrustedSecurityTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [string]
    ${RegisteredIssuerName},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [ValidateNotNullOrEmpty()]
    [switch]
    ${IsTrustBroker},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPTrustedServiceTokenIssuer { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [Parameter(ParameterSetName='ImportCertificateParameterSet')]
    [ValidateNotNull()]
    [System.Security.Cryptography.X509Certificates.X509Certificate2]
    ${Certificate},

    [Parameter(ParameterSetName='MetadataEndPointParameterSet')]
    [ValidateNotNull()]
    [uri]
    ${MetadataEndPoint},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPUsageApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [object]
    ${UsageService},

    [ValidateLength(1, 135)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseServer},

    [ValidateLength(1, 128)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseName},

    [ValidateLength(1, 128)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DatabaseUsername},

    [ValidateNotNull()]
    [securestring]
    ${DatabasePassword},

    [switch]
    ${EnableLogging},

    [ValidateLength(1, 135)]
    [string]
    ${FailoverDatabaseServer},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPUsageDefinition { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Enable},

    [ValidateRange(0, 31)]
    [int]
    ${DaysRetained},

    [ValidateRange(0, 31)]
    [int]
    ${DaysToKeepUsageFiles},

    [ValidateRange(1, 9223372036854775807)]
    [long]
    ${MaxTotalSizeInBytes},

    [switch]
    ${UsageDatabaseEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPUsageService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true, HelpMessage='The max space, in GB, that Usage log files should take up.')]
    [ValidateRange(1, 20)]
    [uint32]
    ${UsageLogMaxSpaceGB},

    [Parameter(ValueFromPipeline=$true, HelpMessage='The location where Usage log files are created.')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1, 181)]
    [string]
    ${UsageLogLocation},

    [Parameter(ValueFromPipeline=$true, HelpMessage='The time interval, in minutes, that Usage log files should be cut and start a new one.')]
    [ValidateRange(1, 1440)]
    [uint32]
    ${UsageLogCutTime},

    [Parameter(ValueFromPipeline=$true, HelpMessage='The max usage file size, in KB, that Usage log files should be cut and start a new one.')]
    [ValidateRange(512, 65536)]
    [uint32]
    ${UsageLogMaxFileSizeKB},

    [System.Nullable[bool]]
    ${LoggingEnabled},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPUser { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('UserAlias')]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${Web},

    [object]
    ${Group},

    [string]
    ${DisplayName},

    [switch]
    ${SyncFromAD},

    [string[]]
    ${AddPermissionLevel},

    [string[]]
    ${RemovePermissionLevel},

    [switch]
    ${ClearPermissions},

    [switch]
    ${PassThru},

    [string]
    ${Email},

    [switch]
    ${IsSiteCollectionAdmin},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPVisioExternalData { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${UnattendedServiceAccountApplicationID},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPVisioPerformance { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [long]
    ${MaxDiagramSize},

    [Parameter(Mandatory=$true)]
    [int]
    ${MinDiagramCacheAge},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${MaxDiagramCacheAge},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [int]
    ${MaxRecalcDuration},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [long]
    ${MaxCacheSize},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPVisioSafeDataProvider { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${VisioServiceApplication},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${DataProviderId},

    [Parameter(Mandatory=$true)]
    [int]
    ${DataProviderType},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Description},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPVisioServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [object]
    ${ServiceApplicationPool},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWeb { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${RelativeUrl},

    [string]
    ${Description},

    [object]
    ${Template},

    [Obsolete('This control applies to SharePoint 2007 theming and is no longer functional')]
    [string]
    ${Theme},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWebApplication { 
  [CmdletBinding(DefaultParameterSetName='UpdateGeneralSettings', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='UpdateClaimSettings', Mandatory=$true)]
    [object]
    ${Zone},

    [Parameter(ParameterSetName='UpdateGeneralSettings')]
    [int]
    ${DefaultTimeZone},

    [Parameter(ParameterSetName='UpdateGeneralSettings')]
    [string]
    ${DefaultQuotaTemplate},

    [Parameter(ParameterSetName='UpdateMailSettings', Mandatory=$true)]
    [string]
    ${SMTPServer},

    [Parameter(ParameterSetName='UpdateMailSettings')]
    [switch]
    ${DisableSMTPEncryption},

    [Parameter(ParameterSetName='UpdateMailSettings')]
    [int]
    ${SMTPServerPort},

    [Parameter(ParameterSetName='UpdateMailSettings')]
    [string]
    ${OutgoingEmailAddress},

    [Parameter(ParameterSetName='UpdateMailSettings')]
    [string]
    ${ReplyToEmailAddress},

    [Parameter(ParameterSetName='UpdateGeneralSettings')]
    [Alias('ProxyGroup')]
    [object]
    ${ServiceApplicationProxyGroup},

    [Parameter(ParameterSetName='UpdateClaimSettings')]
    [object]
    ${AuthenticationProvider},

    [Parameter(ParameterSetName='UpdateClaimSettings')]
    [object]
    ${AdditionalClaimProvider},

    [Parameter(ParameterSetName='UpdateClaimSettings')]
    [string]
    ${SignInRedirectURL},

    [Parameter(ParameterSetName='UpdateClaimSettings')]
    [object]
    ${SignInRedirectProvider},

    [Parameter(ParameterSetName='UpdateClaimSettings')]
    [ValidateSet('Kerberos','NTLM')]
    [string]
    ${AuthenticationMethod},

    [switch]
    ${Force},

    [switch]
    ${NotProvisionGlobally},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWebApplicationHttpThrottlingMonitor { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Category},

    [Parameter(Mandatory=$true, Position=2, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Counter},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Instance},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Alias('Upper')]
    [ValidateRange(0, 1.7976931348623157E+308)]
    [double]
    ${UpperLimit},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Alias('Lower')]
    [ValidateRange(0, 1.7976931348623157E+308)]
    [double]
    ${LowerLimit},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Alias('Buckets')]
    [double[]]
    ${HealthScoreBuckets},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${IsDESC},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWOPIBinding { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [switch]
    ${DefaultAction},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWOPIZone { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Zone},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWordConversionServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [string]
    ${DatabaseName},

    [pscredential]
    ${DatabaseCredential},

    [string]
    ${DatabaseServer},

    [System.Nullable[int]]
    ${TimerJobFrequency},

    [System.Nullable[int]]
    ${ConversionTimeout},

    [System.Nullable[int]]
    ${MaximumConversionAttempts},

    [System.Nullable[int]]
    ${KeepAliveTimeout},

    [System.Nullable[int]]
    ${MaximumConversionTime},

    [System.Nullable[int]]
    ${MaximumSyncConversionRequests},

    [System.Nullable[int]]
    ${ConversionsPerInstance},

    [switch]
    ${DisableEmbeddedFonts},

    [switch]
    ${DisableBinaryFileScan},

    [System.Nullable[int]]
    ${RecycleProcessThreshold},

    [System.Nullable[int]]
    ${ActiveProcesses},

    [System.Nullable[int]]
    ${MaximumMemoryUsage},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [string[]]
    ${AddSupportedFormats},

    [string[]]
    ${RemoveSupportedFormats},

    [switch]
    ${ClearSupportedFormats},

    [System.Nullable[int]]
    ${MaximumGroupSize},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWorkflowConfig { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='WebApplication', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='SiteCollection', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${SiteCollection},

    [bool]
    ${EmailNoPermissionParticipantsEnabled},

    [bool]
    ${SendDocumentToExternalParticipants},

    [bool]
    ${DeclarativeWorkflowsEnabled},

    [int]
    ${SingleWorkflowEpisodeTimeout},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWorkManagementServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${ApplicationPool},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(HelpMessage='This value specifies the minimum amount of time between refreshes for a provider for a given user.')]
    [timespan]
    ${MinimumTimeBetweenProviderRefreshes},

    [Parameter(HelpMessage='This value specifies the minimum amount of time between calls to search for a given user.')]
    [timespan]
    ${MinimumTimeBetweenSearchQueries},

    [Parameter(HelpMessage='This value specifies the minimum amount of time between calls into our routine that tries to find new tenants that want to sync EWS tasks.')]
    [timespan]
    ${MinimumTimeBetweenEwsSyncSubscriptionSearches},

    [Parameter(HelpMessage='This value specifies the maximum number of users a service instance will try to sync on a given tenant via EWS per Timer job interval')]
    [uint32]
    ${NumberOfUsersPerEwsSyncBatch},

    [Parameter(HelpMessage='This value specifies the maximum number of users a service instance machine will sync via EWS at one time across all tenants.')]
    [uint32]
    ${NumberOfUsersEwsSyncWillProcessAtOnce},

    [Parameter(HelpMessage='This value specifies the maximum number of tenants the service will try to sync via EWS per Timer job interval')]
    [uint32]
    ${NumberOfSubscriptionSyncsPerEwsSyncRun},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Set-SPWorkManagementServiceApplicationProxy { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]
    ${DefaultProxyGroup},

    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Split-SPScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='NewDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseName},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseServer},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseFailoverServer},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNull()]
    [pscredential]
    ${NewDatabaseCredentials},

    [Parameter(ParameterSetName='ExistingDatabase', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${TargetDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceServiceApplication},

    [int]
    ${SourcePercentage},

    [switch]
    ${MoveLowerHalf},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Split-SPServerScaleOutDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='NewDatabase', Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseName},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseServer},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${NewDatabaseFailoverServer},

    [Parameter(ParameterSetName='NewDatabase')]
    [ValidateNotNull()]
    [pscredential]
    ${NewDatabaseCredentials},

    [Parameter(ParameterSetName='ExistingDatabase', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${TargetDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceDatabase},

    [Parameter(Mandatory=$true)]
    [object]
    ${SourceServiceApplication},

    [int]
    ${SourcePercentage},

    [switch]
    ${MoveLowerHalf},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPAdminJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPAssignment { 
  [CmdletBinding()]
param(
    [switch]
    ${Global},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPContentDeploymentJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [object]
    ${Identity},

    [switch]
    ${WaitEnabled},

    [string]
    ${DeploySinceTime},

    [switch]
    ${TestEnabled},

    [string]
    ${UseSpecificSnapshot},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPDiagnosticsSession { 
  [CmdletBinding()]
param(
    [guid]
    ${CorrelationId},

    [switch]
    ${Dashboard},

    [ValidateSet('High','Medium','Monitorable','Unexpected','Verbose','VerboseEx','None')]
    [string]
    ${TraceLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPEnterpriseSearchServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [switch]
    ${IncludeCustomServerRole},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Start-SPTimerJob { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPAssignment { 
  [CmdletBinding()]
param(
    [switch]
    ${Global},

    [Parameter(Position=0, ValueFromPipeline=$true)]
    [object]
    ${SemiGlobal},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPDiagnosticsSession { 
  [CmdletBinding()]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPDistributedCacheServiceInstance { 
  [CmdletBinding()]
param(
    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [switch]
    ${Graceful},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPEnterpriseSearchServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [ValidateRange(0, 1440)]
    [System.Nullable[int]]
    ${TimeLeft},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPService { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [switch]
    ${IncludeCustomServerRole},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPServiceInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Stop-SPTaxonomyReplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${Credential},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Suspend-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Suspend-SPStateServiceDatabase { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Name')]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Sync-SPProjectPermissions { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='SPMode', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='PSMode', Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [uri]
    ${Url},

    [Parameter(ParameterSetName='SPMode', Position=1)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Full','Incremental')]
    [object]
    ${Type},

    [Parameter(ParameterSetName='PSMode', Position=1)]
    [switch]
    ${SyncPWASite},

    [Parameter(ParameterSetName='PSMode', Position=2)]
    [switch]
    ${SyncProjectSites},

    [Parameter(ParameterSetName='PSMode', Position=3)]
    [switch]
    ${Async},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='ContentDatabaseById')]
param(
    [Parameter(ParameterSetName='ContentDatabaseByName', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [Parameter(ParameterSetName='ContentDatabaseByName', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [ValidateNotNull()]
    [object]
    ${ServerInstance},

    [ValidateNotNull()]
    [pscredential]
    ${DatabaseCredentials},

    [switch]
    ${ShowRowCounts},

    [switch]
    ${ShowLocation},

    [Parameter(ParameterSetName='ContentDatabaseById', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${ExtendedCheck},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPInfoPathFormTemplate { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [string]
    ${Path},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPO365LinkSettings { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [uri]
    ${MySiteHostUrl},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPProjectServiceApplication { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Position=1, ValueFromPipeline=$true)]
    [object]
    ${Rule},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPProjectWebInstance { 
  [CmdletBinding()]
param(
    [Parameter(ParameterSetName='FindProjectSiteByWebInstance', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='FindProjectSiteByWebInstance', Position=1, ValueFromPipeline=$true)]
    [object]
    ${Rule},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Test-SPSite { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [guid]
    ${RuleId},

    [switch]
    ${RunAlways},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPAppInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPDataConnectionFile { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPFeature { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${Force},

    [int]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPHelpCollection { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Name},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPSolution { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='OneWebApplication', Mandatory=$true)]
    [object]
    ${WebApplication},

    [string]
    ${Time},

    [switch]
    ${Local},

    [Parameter(ParameterSetName='AllWebApplication', Mandatory=$true)]
    [switch]
    ${AllWebApplications},

    [uint32]
    ${Language},

    [string]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPUserSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Uninstall-SPWebPartPack { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [uint32]
    ${Language},

    [string]
    ${CompatibilityLevel},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Unpublish-SPServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPAppCatalogConfiguration { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Site},

    [switch]
    ${SkipWebTemplateChecking},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPAppInstance { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${App},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPDistributedCacheSize { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [uint32]
    ${CacheSizeInMB},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPFarmEncryptionKey { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [switch]
    ${Resume},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPHelp { 
  [CmdletBinding()]
param(
    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPInfoPathAdminFileUrl { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)]
    [uri]
    ${Find},

    [Parameter(Mandatory=$true)]
    [uri]
    ${Replace},

    [switch]
    ${Scan},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPInfoPathFormTemplate { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPInfoPathUserFileUrl { 
  [CmdletBinding(DefaultParameterSetName='WebApp', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='WebApp', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='ContentDB', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${ContentDatabase},

    [Parameter(ParameterSetName='Site', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [uri]
    ${Find},

    [Parameter(Mandatory=$true)]
    [uri]
    ${Replace},

    [switch]
    ${Scan},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPProfilePhotoStore { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${MySiteHostLocation},

    [bool]
    ${CreateThumbnailsForImportedPhotos},

    [bool]
    ${NoDelete},

    [uri]
    ${OldBaseUri},

    [uri]
    ${NewBaseUri},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPRepopulateMicroblogFeedCache { 
  [CmdletBinding(DefaultParameterSetName='Default')]
param(
    [Parameter(ParameterSetName='Default', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='FollowableList', Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ParameterSetName='FollowableList', Mandatory=$true, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Default', ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${SiteSubscription},

    [Parameter(ParameterSetName='Default')]
    [ValidateNotNull()]
    [string]
    ${AccountName},

    [Parameter(ParameterSetName='Default')]
    [ValidateNotNull()]
    [string]
    ${SiteUrl},

    [Parameter(ParameterSetName='FollowableList', Mandatory=$true)]
    [ValidateNotNull()]
    [guid]
    ${SiteId},

    [Parameter(ParameterSetName='FollowableList', Mandatory=$true)]
    [ValidateNotNull()]
    [guid]
    ${WebId},

    [Parameter(ParameterSetName='FollowableList', Mandatory=$true)]
    [ValidateNotNull()]
    [guid]
    ${ListId},

    [Parameter(ParameterSetName='FollowableList', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${ListRootFolderUrl},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPRepopulateMicroblogLMTCache { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${ProfileServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPSecureStoreApplicationServerKey { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Passphrase},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPSecureStoreCredentialMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${Principal},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [securestring[]]
    ${Values},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPSecureStoreGroupCredentialMapping { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [securestring[]]
    ${Values},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPSecureStoreMasterKey { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Passphrase},

    [Parameter(Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${ServiceApplicationProxy},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [string]
    ${LiteralPath},

    [string]
    ${Time},

    [switch]
    ${CASPolicies},

    [switch]
    ${GACDeployment},

    [switch]
    ${FullTrustBinDeployment},

    [switch]
    ${Local},

    [switch]
    ${Force},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPUserSolution { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Mandatory=$true)]
    [object]
    ${Site},

    [Parameter(Mandatory=$true)]
    [object]
    ${ToSolution},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Update-SPWOPIProofKey { 
  [CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    ${ServerName},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPAppManagementServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(ParameterSetName='AppManagementSvcAppById', Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ParameterSetName='AppManagementSvcAppByName')]
    [string]
    ${Name},

    [guid[]]
    ${DatabaseIds},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPContentDatabase { 
  [CmdletBinding(DefaultParameterSetName='ContentDatabaseById', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='ContentDatabaseByName', Mandatory=$true)]
    [ValidateNotNull()]
    [object]
    ${WebApplication},

    [Parameter(ParameterSetName='ContentDatabaseByName', Mandatory=$true)]
    [ValidateNotNull()]
    [string]
    ${Name},

    [ValidateNotNull()]
    [object]
    ${ServerInstance},

    [switch]
    ${UseSnapshot},

    [Parameter(ParameterSetName='ContentDatabaseById', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(Position=1)]
    [switch]
    ${ForceDeleteLock},

    [switch]
    ${SkipIntegrityChecks},

    [Alias('NoB2BSiteUpgrade')]
    [switch]
    ${SkipSiteUpgrade},

    [switch]
    ${AllowUnattached},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPEnterpriseSearchServiceApplication { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPEnterpriseSearchServiceApplicationSiteSettings { 
  [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPFarm { 
  [CmdletBinding(DefaultParameterSetName='FarmById', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]
    ${ServerOnly},

    [switch]
    ${SkipDatabaseUpgrade},

    [Alias('NoB2BSiteUpgrade')]
    [switch]
    ${SkipSiteUpgrade},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPProfileServiceApplication { 
  [CmdletBinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [object]
    ${Identity},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPSingleSignOnDatabase { 
  [CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SSOConnectionString},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    ${SecureStoreConnectionString},

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [securestring]
    ${SecureStorePassphrase},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPSite { 
  [CmdletBinding(DefaultParameterSetName='SPSiteById', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(ParameterSetName='SPSiteById', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [object]
    ${Identity},

    [switch]
    ${VersionUpgrade},

    [switch]
    ${QueueOnly},

    [switch]
    ${Email},

    [switch]
    ${Unthrottled},

    [byte]
    ${Priority},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 


function Upgrade-SPSiteMapDatabase { 
  [CmdletBinding(DefaultParameterSetName='DefaultSet', SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [guid]
    ${DatabaseId},

    [Parameter(ValueFromPipeline=$true)]
    [object]
    ${AssignmentCollection})

 
 } 
