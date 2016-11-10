# Description

This resource is used to create or remove SPTrustedIdentityTokenIssuer in a
SharePoint farm.

The SigningCertificateThumbPrint must match the thumbprint of a certificate in
the store LocalMachine\My of the server that will run this resource.
Note that the private key of the certificate must not be available in the
certiificate store because SharePoint does not accept it.
Once the SPTrustedIdentityTokenIssuer is successfully created, the certificate
can be safely deleted from the certificate store as it won't be needed by
SharePoint.

ClaimsMappings is an array of MSFT_SPClaimTypeMapping to use with cmdlet
New-SPClaimTypeMapping. Each MSFT_SPClaimTypeMapping requires properties Name
and IncomingClaimType. Property LocalClaimType is not required if its value is
identical to IncomingClaimType.

The IdentifierClaim property must match an IncomingClaimType element in
ClaimsMappings array.

The ClaimProviderName property can be set to specify a custom claims provider.
It must be already installed in the SharePoint farm and returned by cmdlet
