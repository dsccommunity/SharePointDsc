# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is responsible for configuring the distributed cache client
settings. It only accepts Ensure='Present' as a key. The resource can
configure the following cache components:
- All SharePoint versions:
    - DistributedLogonTokenCache
    - DistributedViewStateCache
    - DistributedAccessCache
    - DistributedActivityFeedCache
    - DistributedActivityFeedLMTCache
    - DistributedBouncerCache
    - DistributedDefaultCache
    - DistributedSearchCache
    - DistributedSecurityTrimmingCache
    - DistributedServerToAppServerAccessTokenCache.
- SharePoint 2016 and above
    - DistributedFileLockThrottlerCache
    - DistributedSharedWithUserCache
    - DistributedUnifiedGroupsCache
    - DistributedResourceTallyCache
    - DistributedHealthScoreCache
- SharePoint 2019 and above
    - DistributedDbLevelFailoverCache
    - DistributedEdgeHeaderCache
    - DistributedFileStorePerformanceTraceCache
    - DistributedSPAbsBlobCache
    - DistributedSPCertificateValidatorCache
    - DistributedSPOAuthTokenCache
    - DistributedStopgapCache
    - DistributedUnifiedAppsCache
    - DistributedUnifiedAuditCache

More information: https://learn.microsoft.com/en-us/sharepoint/administration/manage-the-distributed-cache-service
