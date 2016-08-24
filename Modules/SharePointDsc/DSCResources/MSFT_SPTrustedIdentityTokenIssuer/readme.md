**Description**

This resource is used to create or remove SPTrustedIdentityTokenIssuer in a SharePoint 
farm. 

The SigningCertificateThumbPrint must match the thumbprint of a certificate in the 
store LocalMachine\My of the server that will run this resource. Once the 
SPTrustedIdentityTokenIssuer is successfully created, the certificate can be safely 
deleted from this store as it won't be needed by SharePoint.

ClaimsMappings is an array of HashTables that host parameters for New-SPClaimTypeMapping 
cmdlet. Required properties are Name and IncomingClaimType. It's not necessary to specify 
property LocalClaimType if it's identical to IncomingClaimType.

The IdentifierClaim property must match an IncomingClaimType element in ClaimsMappings array.

The ClaimProviderName property can be set to specify a custom claims provider. It must be 
already installed in the SharePoint farm and returned by cmdlet Get-SPClaimProvider.
