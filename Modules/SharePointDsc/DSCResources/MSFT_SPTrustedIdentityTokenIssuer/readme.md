# Description

This resource is used to create or remove SPTrustedIdentityTokenIssuer in a
SharePoint farm.

The SigningCertificateThumbPrint must be either the thumbprint of the signing 
certificate stored in the certificate store LocalMachine\My of the server, 
or the file path to the public key of the certificate.

ClaimsMappings is an array of MSFT_SPClaimTypeMapping to use with cmdlet
New-SPClaimTypeMapping. Each MSFT_SPClaimTypeMapping requires properties Name
and IncomingClaimType. Property LocalClaimType is not required if its value is
identical to IncomingClaimType.

The IdentifierClaim property must match an IncomingClaimType element in
ClaimsMappings array.

The ClaimProviderName property can be set to specify a custom claims provider.
It must be already installed in the SharePoint farm and returned by cmdlet
