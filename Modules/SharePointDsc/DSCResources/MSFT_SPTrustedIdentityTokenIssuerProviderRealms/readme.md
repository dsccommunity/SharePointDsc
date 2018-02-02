This resource is used to add or remove provider realms to SPTrustedIdentityTokenIssuer in a
SharePoint farm.

IssuerName is the name for SPTrustedIdentityTokenIssuer

ProviderRealms is array of MSFT_SPProviderRealm with format 
				@{
					Key = "<url>"
					Value = "<urn>"
				}

The default value for the Ensure parameter is Present.