@{
    AllNodes    = @(
        @{
            NodeName             = "*"
            PsDscAllowDomainUser = $true
        },
        @{
            NodeName        = "SPSrv1"
            Thumbprint      = "<THUMBPRINT>"
            CertificateFile = "<CERTFILE>"
            Role            = "SharePoint"
            Subrole         = "SPFE" # SharePoint Role only
            IPAddress       = @{
                Content = "192.168.0.120"
                Apps    = "192.168.0.45"
            }
        },
        @{
            NodeName        = "SPSrv2"
            Thumbprint      = "<THUMBPRINT>"
            CertificateFile = "<CERTFILE>"
            Role            = "SharePoint"
            Subrole         = "SPFE" # SharePoint Role only
            IPAddress       = @{
                Content = "192.168.0.121"
                Apps    = "192.168.0.46"
            }
        },
        @{
            NodeName        = "SPSrv3"
            Thumbprint      = "<THUMBPRINT>"
            CertificateFile = "<CERTFILE>"
            Role            = "SharePoint"
            Subrole         = "SPBE", "SearchFE", "SearchBE" # SharePoint Role only
        },
        @{
            NodeName        = "SPSrv4"
            Thumbprint      = "<THUMBPRINT>"
            CertificateFile = "<CERTFILE>"
            Role            = "SharePoint"
            Subrole         = "SPBE", "SearchFE", "SearchBE" # SharePoint Role only
        }
    )
    NonNodeData = @{
        BuildingBlock              = @{
            Version = '1.0.0'
        }
        InstallPaths               = @{
            InstallFolder      = '\\server\SPSources\2019'
            CertificatesFolder = '\\server\SPCertificates'
        }

        Certificates               = @{
            Portal     = @{
                File         = 'portal.contoso.local.pfx'
                Thumbprint   = '<certificate_thumbprint>'
                FriendlyName = '*.portal.contoso.local'
            }
            PortalApps = @{
                File         = 'portal.contosoapps.local.pfx'
                Thumbprint   = '<certificate_thumbprint>'
                FriendlyName = '*.portal.contosoapps.local'
            }
        }

        DomainDetails              = @{
            DomainName   = 'contoso.local'
            NetbiosName  = 'contoso'
            DBServerCont = 'DBSrv'
            DBServerInfr = 'DBSrv'
            DBServerSear = 'DBSrv'
            DBSAUserName = 'SA'
        }

        Logging                    = @{
            ULSLogPath           = 'D:\Logs\ULS'
            ULSMaxSizeInGB       = 30               # 1-1000 GB, default 1000
            ULSDaysToKeep        = 14               # 1-366 days, default 14
            IISLogPath           = 'D:\Logs\IIS'
            UsageLogPath         = 'D:\Logs\Usage'
            UsagePerLogInMinutes = 5                # 1-1440 minutes, default 5
            UsageMaxLogSizeInMB  = 1                # 1-64 MB, default 1
        }

        SharePoint                 = @{
            ProductKey     = '<Product_Key>'
            InstallPath    = 'C:\Program Files\Microsoft Office Servers\16.0'
            DataPath       = 'C:\Program Files\Microsoft Office Servers\16.0\Data'
            CUFileName     = 'sts2019-kb4484472-fullfile-x64-glb.exe'
            CULangFileName = 'wssloc2019-kb4484471-fullfile-x64-glb.exe'
            ProvisionApps  = $true
        }

        FarmConfig                 = @{
            ConfigDBName           = 'SP_Config'
            AdminContentDBName     = 'SP_AdminContent'
            SuperReader            = 'CONTOSO\svc_cachesr'
            SuperUser              = 'CONTOSO\svc_cachesu'
            OutgoingEmail          = @{
                SMTPServer = 'smtp.contoso.local'
                From       = 'noreply@contoso.local'
                ReplyTo    = 'noreply@contoso.local'
                UseTLS     = $true
                Port       = 25
            }
            SearchSettings         = @{
                PerformanceLevel = 'Maximum'
                ContactEmail     = 'sharepointagora@contoso.local'
            }
            AppsSettings           = @{
                AppDomain          = 'portal.contosoapps.local'
                Prefix             = 'app'
                AllowAppPurchases  = $false
                AllowAppsForOffice = $false
            }
            PasswordChangeSchedule = @{
                Day  = "tue"         # "mon", "tue", "wed", "thu", "fri", "sat", "sun"
                Hour = 7             # Between 00 and 23
            }
        }

        CentralAdminSite           = @{
            WebAppName   = 'SharePoint Central Administration V4'
            PhysicalPath = 'C:\inetpub\wwwroot\wss\VirtualDirectories\9334'
            AppPool      = 'SharePoint Central Administration V4'
            SiteURL      = 'spca.portal.contoso.local'
            Certificate  = 'Portal'
        }

        ActiveDirectory            = @{
            UserOU   = 'OU=Service Accounts,DC=contoso,DC=local'
            SPAdmins = @{
                Name        = 'SPBEHEER'
                Description = 'SharePoint Administrators'
                Members     = @('spadmin', 'svc_setup')
            }
        }

        ManagedAccounts            = @{
            Farm     = 'CONTOSO\svc_farm'
            Services = 'CONTOSO\svc_service'
            Search   = 'CONTOSO\svc_service'
            UpsSync  = 'CONTOSO\svc_adsync'
            AppPool  = 'CONTOSO\svc_webapp'
        }

        ServiceAccounts            = @{
            SuperReader   = 'CONTOSO\svc_cachesr'
            SuperUser     = 'CONTOSO\svc_cachesu'
            ContentAccess = 'CONTOSO\svc_content'
        }

        ApplicationPools           = @{
            ServiceApplicationPools = @{
                Name = 'Service Applications'
            }
        }

        ServiceApplications        = @{
            AppManagement          = @{
                Name   = 'App Management Service Application'
                DBName = 'SP_AppManagement'
            }
            BCSService             = @{
                Name   = 'BCS Service Application'
                DBName = 'SP_BCS'
            }
            ManagedMetaDataService = @{
                Name                    = 'Managed Metadata Service Application'
                DBName                  = 'SP_MMS'
                TermStoreAdministrators = @('CONTOSO\svc_farm')
            }
            SearchService          = @{
                Name                        = 'Search Service Application'
                DBName                      = 'SP_Search'
                DefaultContentAccessAccount = 'CONTOSO\svc_content'
                IndexPartitionRootDirectory = 'D:\SPIndex'
                SearchCenterUrl             = 'https://search.portal.contoso.local/Pages'
            }
            SecureStore            = @{
                Name   = 'Secure Store Service Application'
                DBName = 'SP_SecureStore'
            }
            StateService           = @{
                Name   = 'State Service Application'
                DBName = 'SP_State'
            }
            SubscriptionSettings   = @{
                Name   = 'Subscription Settings Service Application'
                DBName = 'SP_SubscriptionSettings'
            }
            UsageAndHealth         = @{
                Name   = 'Usage and Health Service Application'
                DBName = 'SP_UsageAndHealth'
            }
            UserProfileService     = @{
                Name                      = 'User Profile Service Application'
                MySiteHostLocation        = 'https://mysite.portal.contoso.local'
                ProfileDBName             = 'SP_UPA_Profile'
                SocialDBName              = 'SP_UPA_Social'
                SyncDBName                = 'SP_UPA_Sync'
                UserProfileSyncConnection = @{
                    Name           = 'Contoso AD'
                    Forest         = 'contoso.local'
                    UseSSL         = $false
                    Port           = 389
                    IncludedOUs    = @('DC=contoso,DC=local')
                    ExcludedOUs    = @()
                    Force          = $false
                    ConnectionType = 'ActiveDirectory'
                }
            }
        }

        TrustedIdentityTokenIssuer = @{
            Realm = 'urn:sharepoint:dev'
        }

        WebApplications            = @{
            Content = @{
                Name                        = 'SharePoint Content Web Application'
                ApplicationPool             = 'Content'
                ApplicationPoolAccount      = 'CONTOSO\svc_webapp'
                DatabaseName                = 'SP_Content_01'
                Url                         = 'https://root.portal.contoso.local'
                Port                        = '443'
                Protocol                    = 'HTTPS'
                Certificate                 = 'Portal'
                CertificateStoreName        = 'My'
                BlobCacheFolder             = 'D:\BlobCache'
                BlobCacheSize               = 10      # 10-1000 GB, default 10
                BlobCacheFileTypes          = '\.(gif|jpg|png|css|js)$'
                OwnerAlias                  = 'CONTOSO\svc_farm'
                PathBasedRootSiteCollection = @{
                    Url             = 'https://root.portal.contoso.local'
                    Name            = 'Root'
                    Template        = 'STS#0'
                    Language        = '1043'
                    ContentDatabase = 'SP_Content_01'
                }
                HostNamedSiteCollections    = @(
                    @{
                        Url             = 'https://appcatalog.portal.contoso.local'
                        Name            = 'AppCatalog'
                        Template        = 'APPCATALOG#0'
                        Language        = '1043'
                        ContentDatabase = 'SP_Content_01'
                    },
                    @{
                        Url             = 'https://mysite.portal.contoso.local'
                        Name            = 'MySite'
                        Template        = 'SPSMSITEHOST#0'
                        Language        = '1043'
                        ContentDatabase = 'SP_Content_01'
                    },
                    @{
                        Url             = 'https://search.portal.contoso.local'
                        Name            = 'Search Center'
                        Template        = 'SRCHCEN#0'
                        Language        = '1043'
                        ContentDatabase = 'SP_Content_01'
                    }
                )
            }
            Apps    = @{
                Name                        = 'SharePoint Apps Web Application'
                ApplicationPool             = 'Content'
                ApplicationPoolAccount      = 'CONTOSO\svc_webapp'
                DatabaseName                = 'SP_Apps_Content_01'
                Url                         = 'https://root.portal.contosoapps.local'
                Port                        = '443'
                Protocol                    = 'HTTPS'
                Certificate                 = 'PortalApps'
                CertificateStoreName        = 'My'
                BlobCacheFolder             = 'D:\BlobCache'
                BlobCacheSize               = 10      # 10-1000 GB, default 10
                BlobCacheFileTypes          = '\.(gif|jpg|png|css|js)$'
                OwnerAlias                  = 'CONTOSO\svc_farm'
                PathBasedRootSiteCollection = @{
                    Url             = 'https://root.portal.contosoapps.local'
                    Name            = 'Root'
                    Template        = 'STS#0'
                    Language        = '1043'
                    ContentDatabase = 'SP_Apps_Content_01'
                }
            }
        }
    }
}
