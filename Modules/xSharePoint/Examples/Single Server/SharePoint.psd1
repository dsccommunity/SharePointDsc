@{
    AllNodes = @(
		@{
			NodeName = "*"
		},
		@{ 
		    NodeName = "sharepoint1"
			ServiceRoles = @{
				WebFrontEnd = $true
				DistributedCache = $true
				SearchFrontEnd = $true
				SearchBackEnd = $true
				AppServer = $true
			}
	    }
    )
	NonNodeData = @{
		DomainDetails = @{
			DomainName = "contoso.local"
			NetbiosName = "DSC"
		}
		SQLServer = @{
			ContentDatabaseServer = "sql1.contoso.local"
			SearchDatabaseServer = "sql1.contoso.local"
			ServiceAppDatabaseServer = "sql1.contoso.local"
			FarmDatabaseServer = "sql1.contoso.local"
		}
		SharePoint = @{
			Farm = @{
				ConfigurationDatabase = "SP_Config"
				Passphrase = "ExamplePassphase!"
				AdminContentDatabase = "SP_AdminContent"
			}
			DiagnosticLogs = @{
				Path = "L:\ULSLogs"
				MaxSize = 10
				DaysToKeep = 7
			}
			UsageLogs = @{
				DatabaseName = "SP_Usage"
				Path = "L:\UsageLogs"
			}
			StateService = @{
				DatabaseName = "SP_State"
			}
			WebApplications = @(
				@{
					Name = "SharePoint Sites"
				    DatabaeName = "SP_Content_01"
					Url = "http://sites.sharepoint.contoso.local"
					Authentication = "NTLM"
					Anonymous = $false
					AppPool = "SharePoint Sites"
					AppPoolAccount = "DSC\svcSPWebApp"
					SuperUser = "DSC\svcSPSuperUser"
					SuperReader = "DSC\svcSPReader"
					UseHostNamedSiteCollections = $true
					ManagedPaths = @(
						@{
							Path = "teams"
							Explicit = $false
						},
						@{
							Path = "personal"
							Explicit = $false
						}
					)
					SiteCollections = @(
						@{
							Url = "http://sites.sharepoint.contoso.local"
							Owner = "DSC\svcSPFarm"
							Name = "Team Sites"
							Template = "STS#0"
						},
						@{
							Url = "http://my.sharepoint.contoso.local"
							Owner = "DSC\svcSPFarm"
							Name = "My Sites"
							Template = "SPSMSITEHOST#0"
						}
					)
				}
			)
			UserProfileService = @{
				MySiteUrl = "http://my.sharepoint.contoso.local"
				ProfileDB = "SP_UserProfiles"
				SocialDB = "SP_Social"
				SyncDB = "SP_ProfileSync"
			}
			SecureStoreService = @{
				DatabaseName = "SP_SecureStore"
			}
			ManagedMetadataService = @{
				DatabaseName = "SP_ManagedMetadata"
			}
			BCSService = @{
				DatabaseName = "SP_BCS"
			}
			Search = @{
				DatabaseName = "SP_Search"
				IndexRootPath = "I:\SearchPartitions"
			}
		}
	}
}