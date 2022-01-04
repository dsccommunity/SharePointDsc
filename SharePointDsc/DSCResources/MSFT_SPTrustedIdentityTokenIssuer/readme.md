# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to create or remove SPTrustedIdentityTokenIssuer in a
SharePoint farm.

In SharePoint 2013 / 2016 / 2019, it can only be a SAML trust.
In SharePoint Subscription, it can be a SAML trust or an OIDC trust.

For a SAML trust, the specific mandatory parameters are Realm, SignInUrl, 
and either SigningCertificateThumbPrint or SigningCertificateFilePath.

Either parameter SigningCertificateThumbPrint or SigningCertificateFilePath
must be set. If specifying both SigningCertificateThumbPrint and
SigningCertificateFilePath, the certificate thumbprint will be verified
with the specified SigningCertificateThumbPrint. If the thumbprints doesn't
match an exception will be thrown.

The SigningCertificateThumbPrint must be the thumbprint of the signing
certificate stored in the certificate store LocalMachine\My of the server

Note that the private key of the certificate must not be available in the
certiificate store because SharePoint does not accept it.

The SigningCertificateFilePath must be the file path to the public key of
the signing certificate.

For an OIDC trust, the specific mandatory parameters are 
AuthorizationEndPointUri, DefaultClientIdentifier and SignOutUrl.

The ClaimsMappings property is an array of MSFT_SPClaimTypeMapping to use
with cmdlet New-SPClaimTypeMapping. Each MSFT_SPClaimTypeMapping requires
properties Name and IncomingClaimType. Property LocalClaimType is not
required if its value is identical to IncomingClaimType.

The IdentifierClaim property must match an IncomingClaimType element in
ClaimsMappings array.

The ClaimProviderName property can be set to specify a custom claims provider.
It must be already installed in the SharePoint farm and returned by cmdlet

The default value for the Ensure parameter is Present. When not specifying this
parameter, the token issuer is created.
