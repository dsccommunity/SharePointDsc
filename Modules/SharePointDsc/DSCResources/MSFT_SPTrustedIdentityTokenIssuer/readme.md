**Description**

This resource is used to create or remove SPTrustedIdentityTokenIssuer in a SharePoint 
farm. 

The SigningCertificateThumbPrint must match the thumbprint of a certificate in the 
store LocalMachine\My of the server that will run this resource. Once the 
SPTrustedIdentityTokenIssuer is successfully created, the certificate can be safely 
deleted from this store as it won't be needed by SharePoint.

ClaimsMappings is a JSON array that hosts parameters for cmdlet New-SPClaimTypeMapping.
Array name is Mappings that contains an array of key/value pairs. Each entry requires
keys Name and IncomingClaimType. Key LocalClaimType is not required if its value is 
identical to IncomingClaimType.

The IdentifierClaim property must match an IncomingClaimType element in ClaimsMappings array.

The ClaimProviderName property can be set to specify a custom claims provider. It must be 
already installed in the SharePoint farm and returned by cmdlet Get-SPClaimProvider.
