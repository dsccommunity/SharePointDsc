# Description

**Type:** Distributed

This resource sets the client callable settings for the web application.
It can set the proxy libraries and specific properties for the client
callable settings.
The resource can for example be used to increase the timeout for client
code, and to enable the tenant administration functionality.

Tenant administration functionality enables client code to work with
the namespace Microsoft.Online.SharePoint.Client.Tenant from the
assembly with the same name. This enables client code to create site
collection, list all site collections, and more.

In order to use the tenant administration client code a site collection
within the web application needs to be designated as a tenant
administration site collection. This can be done using the SPSite
resource setting the AdministrationSiteType to TenantAdministration.
Use this site collection when creating a client side connection.

NOTE:
Proxy library used for enabling tenant administration:

**SharePoint 2013** (Requires mininum April 2014 Cumulative Update):
Microsoft.Online.SharePoint.Dedicated.TenantAdmin.ServerStub
, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c

**SharePoint 2016**:
Microsoft.Online.SharePoint.Dedicated.TenantAdmin.ServerStub
, Version=16.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c

In both version set the SupportAppAuthentication property to true.
