@{
    AllNodes = @(
            @{
                    NodeName     = "*"
                    Role = ""
              },
             @{
                    NodeName     = "*"
                    Role = ""
              }           
    )
    Configuration = @{
        Environment = "Dev"
        Version = "3.99.60"
        Install = @{
            SPVersion = "2013"
            ##ConfigFile = "config-AutoSPInstaller.xml" <-- If exists get data and populate properties below
            InstallDir = ""
            DataDir = ""
            PIDKey = ""
            SKU = ""
            OfflineInstall = $false
            PauseAfterInstall = $false
            RemoteInstall = @{
                Enable = $false
                ParallelInstall = $false
            }
            
            AutoAdminLogon = @{
                Enable = $false
                Password = ""
            }
            Disable = @{
                LoopbackCheck = $true
                UnusedServices = $true
                IEEnhancedSecurity = $true
                CertificateRevoactionListCheck = $false
            }
        }
        Farm = @{
            Passphrase = ""
            Account = @{
                AddToLocalAdminsDuringSetup = $true
                LeaveInLocalAdmins = $false
                Username = "CONTOSO\SP_Farm"
                Password = ""
            }
            CentralAdmin = @{
                Provision="localhost"
                Database = "Content_CentralAdmin"
                Port = "2013"
                UseSSL = $false
            }
            Database = @{
                DBServer = ""
                DBAlias = @{
                    DBInstance = "SERVER\INSTANCE"
                    DBPort = ""
                }
                DBPrefix = "AutoSPInstaller"
                ConfigDB = "Config"
            }
            Services = @{
                SandboxCodeService = @{
                    Start = $false
                }
                ClaimsToWindowsTokenService = @{
                    Start = $false
                    UpdateAccount = $false
                }
                SMTP = @{
                    Install = $false
                }
                OutgoingEmail = @{
                    Configure = $true
                    SMTPServer = ""
                    EmailAddress = ""
                    ReplyToEmail = ""
                }
                IncomingEmail = @{
                    Start = @("localhost")
                }
                DistributedCache = @{
                    Start = @("localhost")
                }
                WorkflowTimer = @{
                    Start = @("localhost")
                }
                FoundationWebApplication = @{
                    Start = @("localhost")
                }
            }
            ServerRoles = @{
                WebFrontEnd = @{
                    Provision = $false
                }
                WebFrontEndWithDistributedCache = @{
                    Provision = $false
                }
                Application = @{
                    Provision = $false
                }
                ApplicationWithSearch = @{
                    Provision = $false
                }
                DistributedCache = @{
                    Provision = $false
                }
                Search = @{
                    Provision = $false
                }
                Custom = @{
                    Provision = $false
                }
                SingleServerFarm = @{
                    Provision = $false
                }
            }
            ManagedAccounts = @(
                @{ 
                    CommonName = "spservice"
                    Username = "CONTOSO\SP_Services"
                    Password = ""
                },
                @{
                    CommonName = "Portal"
                    Username = "CONTOSO\SP_PortalAppPool"
                    Password = ""
                },
                @{
                    CommonName = "MySiteHost"
                    Username = "CONTOSO\SP_ProfilesAppPool"
                    Password = ""
                },
                @{
                    CommonName = "SearchService"
                    Username = "CONTOSO\SP_SearchService"
                    Password = ""
                }
            )

            ObjectCacheAccounts = @{
                SuperUser = "CONTOSO\SP_CacheSuperUser"
                SuperReader = "CONTOSO\SP_CacheSuperReader"
            }

            Logging = @{
                IISLogs = @{
                    Compress = $true
                    Path = ""
                }
                ULSLogs = @{
                    LogLocation = ""
                    LogDiskSpaceUsageGB = ""
                    DaysToKeepLogs = 90
                    LogCutInterval = 30
                }
                UsageLogs = @{
                    Compress = $true
                    UsageLogDir = ""
                    UsageLogMaxSpaceGB = ""
                    UsageLogCutTime = ""
                }
            }

        }  
        WebApplications = @{
            AddURLsToHOSTS = $true
            WebApplications = @(
                @{
                    Name = "Portal Home"
                    Type="Portal"
                    ApplicationPool = "portal.contoso.com"
                    Url = "http://portal.contoso.com"
                    Port = 80
                    UseHostHeader = $false
                    GrantCurrentUserFullControl = $true
                    UseClaims = $true
                    UseBasicAuthentication = $false
                    UseOnlineWebPartCatalog = $false
                    Database = @{
                        Name = "Content_Portal"
                        DBServer = ""
                        DBAlias = @{
                            Create = $false
                            DBInstance = "SERVIER\INSTANCE"
                            DBPort = ""
                        }
                    }
                    ManagedPaths = @(
                        @{ 
                            relativeUrl = "help"
                            explicit = $true
                        }
                    )
                    SiteCollections = @(
                        @{ 
                            Name = "Portal Home"
                            Description = "Portal Home Site"
                            HostNameSiteCollection = $false
                            OWner = ""
                            CustomDatabase = ""
                            SearchUrl = "http://portal.contoso.com/search"
                            Template = "STS#0"
                            LCID = 1033
                            Locale = "en-us"
                            Time24 = $false
                        }
                    )
                    
                },
                @{
                    Name = "MySite Host"
                    Type="MySiteHost"
                    ApplicationPool = "mysites.contoso.com"
                    Url = "http://mysites.contoso.com"
                    Port = 80
                    UseHostHeader = $false
                    AddURLToLocalIntranetZone = $true
                    GrantCurrentUserFullControl = $true
                    UseClaims = $true
                    UseBasicAuthentication = $false
                    UseOnlineWebPartCatalog = $false
                    Database = @{
                        Name = "Content_MySites"
                        DBServer = ""
                        DBAlias = @{
                            Create = $false
                            DBInstance = "SERVIER\INSTANCE"
                            DBPort = ""
                        }
                    }
                    ManagedPaths = @(
                        @{ 
                            relativeUrl = "personal"
                            explicit = $false
                        }
                    )
                    SiteCollections = @(
                        @{ 
                            Name = "My Sites Host"
                            Description = "My Sites Host Site"
                            SiteUrl = "http://mysites.contoso.com"
                            HostNameSiteCollection = $false
                            OWner = ""
                            CustomDatabase = ""
                            SearchUrl = "http://portal.contoso.com/search"
                            Template = "SPSMSITEHOST#0"
                            LCID = 1033
                            Locale = "en-us"
                            Time24 = $false
                        }
                    )
                    
                }
            )
        }
        <#
            ... MORE LATEr.. But the idea would be to createa  function that would crawl the XML,
            and just convert it to a psd1 data file. THen no matter how the XML changes we could
            generate a new psd1 file and make Configuration updates as needed.

        #>
        ##    AddURLsToHOSTS = $true


        
    }
}