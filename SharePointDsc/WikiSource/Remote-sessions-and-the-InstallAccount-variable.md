# PowerShell 4

In PowerShell 4, by default the normal behavior of the [local configuration manager](https://technet.microsoft.com/en-us/library/dn249922.aspx) in DSC is to execute configuration elements in the context of the local system account.
This presents an issue in a SharePoint environment as all access to SharePoint databases and resources is managed by allowing the appropriate service accounts permission to do so, and these service accounts are domain accounts, not local machine accounts.

To get around this for the resources that manipulate SharePoint content, we need to impersonate another account to execute the commands.
This is achieved through the use of the parameter "InstallAccount", which is present in almost all of the resources in the SharePointDsc module.
The InstallAccount parameter represents the account that is responsible for the creation and management of all SharePoint resources in the farm.
It is likely to be a highly privileged account (which may include local administrator rights - so do not use an account that is also used to run services or components anywhere in SharePoint, use a dedicated account instead).

The impersonation is managed through the use of the Invoke-Command cmdlet in PowerShell, in conjunction with creating an appropriate "remote" session through New-PSSession.
Each session that is created this way will always target "localhost" as opposed to a genuinely remote computer, but it gives us the opportunity to control the authentication for that session.
In the SharePointDsc module, we authenticate as the InstallAccount, and we specify that CredSSP is used as the authentication mechanism.

To enable CredSSP, there is some configuration that needs to take place first, and there are two methods of doing this.

## Option 1: Manually configure CredSSP

You can manually configure CredSSP through the use of some PowerShell cmdlet's (and potentially group policy to configure the allowed delegate computers). Some basic instructions can be found at [https://technet.microsoft.com/en-us/magazine/ff700227.aspx](https://technet.microsoft.com/en-us/magazine/ff700227.aspx).

### Option 2: Configure CredSSP through a DSC resource

It is possible to use a DSC resource to configure your CredSSP settings on a server, and include this in all of your SharePoint server configurations.
This is done through the use of the [xCredSSP](https://github.com/PowerShell/xCredSSP) resource. The below example shows how this can be used.

    xCredSSP CredSSPServer { Ensure = "Present"; Role = "Server" } 
    xCredSSP CredSSPClient { Ensure = "Present"; Role = "Client"; DelegateComputers = $CredSSPDelegates }

In the above example, $CredSSPDelegates can be a wildcard name (such as "*.contoso.com" to allow all servers in the contoso.com domain), or a list of specific servers (such as "server1", "server 2" to allow only specific servers).

## PowerShell 5

PowerShell 5 offers a different approach to how impersonation is done. With WMF 5 installed, all DSC resources (not just those in SharePointDsc) can add a parameter called PsDscRunAsCredential.
This property tells the LCM to run that specific resource with the credential that is supplied instead of the local system account.
This removes the need to have InstallAccount on SharePointDsc resources. However, instead of removing it, logic was added that would allow you to use either InstallAccount or PsDscRunAsCredential.
The SharePointDsc resources will detect if they are running as the local system account or not and will only use a "remote" session as described above where it is needed.

Also note that some resources in SharePointDsc still use the above described remote session technique to simulate other others regardless of whether or not PsDscRunAsCredential is used.
An example of this is [SPUserProfileSyncService](SPUserProfileSyncService) which uses this approach to run as the farm account value.

An example of how to use this property in PowerShell 5 is shown below:

    SPCacheAccounts SetCacheAccounts
    {
        WebAppUrl            = "http://sharepoint.contoso.com"
        SuperUserAlias       = "DEMO\svcSPSuperUser"
        SuperReaderAlias     = "DEMO\svcSPReader"
        PsDscRunAsCredential = $InstallAccount
    }
