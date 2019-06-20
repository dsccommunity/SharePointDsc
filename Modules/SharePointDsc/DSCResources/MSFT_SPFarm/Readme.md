# Description

**Type:** Specific
**Requires CredSSP:** No

This resource is used to create a new SharePoint farm and allow servers to
join that farm. It will detect the presence of the configuration database
on the SQL server as a first step, and if it does not exist then the farm
will be created. If the database does exist, the server will join that
configuration database. Once the config DB has been created, the
resource will install local help collections, secure resources and activate
features.

If the central admin site is to be running on the local server, the
RunCentralAdmin property should be set to true. In the event that the central
admin site has not been provisioned, this resource will first create it,
otherwise it will simply start the central admin service instance on the
local server.

The passphrase is passed as a Credential object.The username of this
credential is ignored, only the value of the password is used as the farm
passphrase.

The port of the Central Admin website can be set by using the
CentralAdministrationPort property. If this is not defined, the site will be
provisioned on port 9999 unless the CentralAdministrationUrl property is
specified and begins with https, in which case it will default to port 443.
However, this setting will not impact existing deployments that already have
Central Admin provisioned on another port. Also, when a farm is created, the
current behavior is to not enroll the server as a cache server (which is the
default behavior of SharePoint). This means you need to use
SPDistributedCacheService on at least one server in the farm to designate it
as a cache server.

CentralAdministrationAuth can be specified as "NTLM" or "KERBEROS". If not
specified, it defaults to NTLM. If using Kerberos, make sure to have
appropriate SPNs setup for Farm account and Central Administration URI.

To provision Central Admin as an SSL web application, specify a value for
the CentralAdministrationUrl property that begins with https:// followed
by the vanity host name or server name you wish to use to access CA.
(e.g. https://admin.sharepoint.contoso.com). This parameter does not
currently support HTTP.

DeveloperDashboard can be specified as "On", "Off" and (only when using
SharePoint 2013) to "OnDemand".

NOTE:
When using SharePoint 2016 and later and enabling the Developer Dashboard,
please make sure you also provision the Usage and Health service application
to make sure the Developer Dashboard works properly.
