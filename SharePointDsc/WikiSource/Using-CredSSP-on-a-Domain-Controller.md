When you are trying to use the resources that require CredSSP, you can run into issues when deploying to a single server which is also a domain controller.

> **NOTE:** Installing SharePoint on a domain controller should not be done in Production scenarios!

Even though you configured CredSSP as required, you can run into the following error message:
```
Test-WSMan : <f:WSManFault xmlns:f="http://schemas.microsoft.com/wbem/wsman/1/wsmanfault" Code="2150859172" Machine="server1.domain.com"><f:Message>The WinRM client cannot process the request. A computer policy does not allow the delegation of the user credentials to the target computer because the computer is not trusted. The identity of the t
arget computer can be verified if you configure the WSMAN service to use a valid certificate using the following command: winrm set winrm/config/service @{CertificateThumbprint="&lt;thumbprint&gt;"}  Or you can check the Event Viewer for an event that specifies that the following SPN could not be created: WSMAN/&lt;computerFQDN&gt;. If you find
 this event, you can manually create the SPN using setspn.exe .  If the SPN exists, but CredSSP cannot use Kerberos to validate the identity of the target computer and you still want to allow the delegation of the user credentials to the target computer, use gpedit.msc and look at the following policy: Computer Configuration -&gt; Administrativ
e Templates -&gt; System -&gt; Credentials Delegation -&gt; Allow Fresh Credentials with NTLM-only Server Authentication.  Verify that it is enabled and configured with an SPN appropriate for the target computer. For example, for a target computer name "myserver.domain.com", the SPN can be one of the following: WSMAN/myserver.domain.com or WSMA
N/*.domain.com. Try the request again after these changes.  </f:Message></f:WSManFault>
At line:1 char:1
+ Test-WSMan -Authentication Credssp -ComputerName Server1 -Credential  ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (Server1:String) [Test-WSMan], InvalidOperationException
    + FullyQualifiedErrorId : WsManError,Microsoft.WSMan.Management.TestWSManCommand
```

You can resolve this issue by configuring Service Principal Names in Active Directory for the server:
```
setspn -S wsman/server1.domain.com server1
setspn -S wsman/server1 server1
```

After configuring these SPNs, CredSSP will run as expected again!
