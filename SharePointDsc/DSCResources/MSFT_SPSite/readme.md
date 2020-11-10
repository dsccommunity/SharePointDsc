# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource will provision a site collection to the current farm, based on
the settings that are passed through. These settings map to the New-SPSite
cmdlet and accept the same values and types.

When the site collection exists, not all parameters are checked for being
in the desired state. The following parameters are checked:
QuotaTemplate, OwnerAlias, SecondaryOwnerAlias, AdministrationSiteType

Since the title of the site collection can be changed by the site collection
owner and can result in a conflict between the owner and DSC. Therefore the
resource is only using the Name parameter during site creation.

NOTE:
When creating Host Header Site Collections, do not use the HostHeader
parameter in SPWebApplication. This will set the specified host header on your
IIS site and prevent the site from listening for the URL of the Host Header
Site Collection.
If you want to change the IIS website binding settings, please use the xWebsite
resource in the xWebAdministration module.

NOTE2:
The CreateDefaultGroups parameter is only used for creating default site
groups. It will not remove or change the default groups if they already exist.

NOTE3:
AdministrationSiteType is used in combination with the resource
SPWebAppClientCallableSettings. The required proxy library must be configured
before the administration site type has any effect.
