@{
    ActiveDirectory = @{
        DomainName  = "dsc.lab"
        NetbiosName = "DSC"
        ServiceAccounts = @{
            Setup = @{
                Username = "svcSPSetup"
                Password = "SharePoint156!"
            }
            Farm = @{
                Username = "svcSPFarm"
                Password = "SharePoint156!"
            }
            WebApp = @{
                Username = "svcSPWebApps"
                Password = "SharePoint156!"
            }
            ServiceApp = @{
                Username = "svcSPServiceApps"
                Password = "SharePoint156!"
            }
            SuperUser = @{
                Username = "svcSPSuper"
                Password = "SharePoint156!"
            }
            SuperReader = @{
                Username = "svcSPReader"
                Password = "SharePoint156!"
            }
            Crawler = @{
                Username = "svcSPCrawl"
                Password = "SharePoint156!"
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