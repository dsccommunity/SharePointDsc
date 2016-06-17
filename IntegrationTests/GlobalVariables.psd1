@{
    ActiveDirectory = @{
        DomainName  = "dsc.lab"
        NetbiosName = "DSC"
        ServiceAccounts = @{
            Setup = @{
                Username = "svcSPSetup"
                Password = "SharePoint1!"
            }
            Farm = @{
                Username = "svcSPFarm"
                Password = "SharePoint1!"
            }
            WebApp = @{
                Username = "svcSPWebApps"
                Password = "SharePoint1!"
            }
            ServiceApp = @{
                Username = "svcSPServiceApps"
                Password = "SharePoint1!"
            }
            SuperUser = @{
                Username = "svcSPSuper"
                Password = "SharePoint1!"
            }
            SuperReader = @{
                Username = "svcSPReader"
                Password = "SharePoint1!"
            }
            Crawler = @{
                Username = "svcSPCrawl"
                Password = "SharePoint1!"
            }
        }
    }
    SQL = @{
        DatabaseServer = "localhost"
    }
    SharePoint = @{
        BinaryPath = "C:\Binaries\SharePoint"
    }
}