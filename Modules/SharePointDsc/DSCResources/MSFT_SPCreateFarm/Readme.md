# Description

This resource is used to provision a new SharePoint farm. It should only be
used on the first server in the farm to create the configuration database, all
servers to join the farm after the first server creates the configuration
database should use SPJoinFarm. Once the config DB has been created, the
resource will install local help collections, secure resources, activate
features and provision the central admin site.

The passphrase is passed as a Credential object.The username of this
credential is ignored, only the value of the password is used as the farm
passphrase.

The port of the Central Admin website can be set by using the
CentralAdministrationPort property, if this is not defined the site will be
provisioned on port 9999. However this setting will not impact existing
deployments that already have Central Admin provisioned on another port. Also
when a farm is created, the current behavior is to not enroll the server as a
cache server (which is the default behavior of SharePoint). This means you
need to use SPDistributedCacheService on at least one server in the farm to
designate it as a cache server.

CentralAdministrationAuth can be specified as "NTLM" or "KERBEROS". If not
specified, it defaults to NTLM. If using Kerberos, make sure to have
appropriate SPNs setup for Farm account and Central Administration URI.
