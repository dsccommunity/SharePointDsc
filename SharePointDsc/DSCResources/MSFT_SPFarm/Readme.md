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
The port number in CentralAdministrationPort and CentralAdministrationUrl must
match if both parameters are specified. It is not recommended to include port
number 80 and 443 in the CentralAdministrationUrl parameter. This will
automatically follow the URL shceme http (80) and https (443) specified.
CentralAdministrationPort is an optional parameter and can be omitted if the
port is specified in CentralAdministrationUrl, or if default ports for
http/https is used (no port is required to be specified).
However, this setting will not impact existing deployments that already have
Central Admin provisioned on another port. Also, when a farm is created, the
current behavior is to not enroll the server as a cache server (which is the
default behavior of SharePoint). This means you need to use
SPDistributedCacheService on at least one server in the farm to designate it
as a cache server.

CentralAdministrationAuth can be specified as "NTLM" or "KERBEROS". If not
specified, it defaults to NTLM. If using Kerberos, make sure to have
appropriate SPNs setup for Farm account and Central Administration URI.

To provision Central Admin on a vanity URL instead of the default
http(s)://servername:port, use the CentralAdministrationUrl parameter.
Central Admin will be provisioned as an SSL web application if this URL
begins with HTTPS, and will default to port 443.

DeveloperDashboard can be specified as "On", "Off" and (only when using
SharePoint 2013) to "OnDemand".

ApplicationCredentialKey is used to set the application credential key on the
local server, which is used by certain features to encrypt and decrypt passwords.
The application credential key will only be set during initial farm creation and
when joining the farm. The ApplicationCredentialKey needs to be the same on each
server in the farm. ApplicationCredentialKey is only supported for SharePoint 2019.

NOTE:
When using SharePoint 2016 and later and enabling the Developer Dashboard,
please make sure you also provision the Usage and Health service application
to make sure the Developer Dashboard works properly.

NOTE2:
Since v4.4 the resource supports the use of precreated databases.
