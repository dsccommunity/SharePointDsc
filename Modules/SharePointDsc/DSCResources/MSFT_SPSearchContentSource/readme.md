# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource will deploy and configure a content source in a specified search
service application.

The CrawlSetting is used to control crawl scope.  SharePoint sources can utilize
CrawlVirtualServers to crawl the entire server and all site collections on the server
or CrawlSites to crawl only particular site collections.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the content source is created.
