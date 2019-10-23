# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to create or remove a SPTrustedSecurityTokenIssuer in
a SharePoint farm.

It requires to specify either a MetadataEndPoint or a certificate.

The certificate can be specified by setting either parameter
SigningCertificateThumbPrint or SigningCertificateFilePath, but not both.

The SigningCertificateThumbPrint must be the thumbprint of the signing
certificate stored in the certificate store LocalMachine\My of the server

The SigningCertificateFilePath must be the file path to the public key of
the signing certificate.

Properties RegisteredIssuerNameIdentifier and RegisteredIssuerNameRealm
compose the RegisteredIssuerName. If RegisteredIssuerNameRealm is ommitted,
it will be set with the realm of the farm.

The default value for the Ensure parameter is Present. When not specifying this
parameter, the token issuer is created.
