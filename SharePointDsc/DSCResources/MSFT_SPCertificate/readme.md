# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to manage SSL certificate in the Certificate Management
solution build into SharePoint Server Subscription Edition. With this resource
you can import new certificates and remove certificates from the store.

**IMPORTANT:** Certificate PFX files are protected by either a password
or an ACL. So when trying to import the PFX file, you either have to grant
the PsDscRunAsCredential permissions to import the PFX (specify the account
when exporting the certificate to a PFX) or specify the used password via
the CertificatePassword parameter.

This resource does not check what option you used and will fail importing
the certicate when not using the correct option!

Exporting a certificate to PFX and using a password: https://docs.microsoft.com/en-us/powershell/module/pki/export-pfxcertificate?view=windowsserver2019-ps#example-1
Exporting a certificate to PFX and using ACL protection: https://docs.microsoft.com/en-us/powershell/module/pki/export-pfxcertificate?view=windowsserver2019-ps#example-4
