When working on Windows Server 2012R2 or any server without PowerShell 5.0. It's recommended to first upgrade PowerShell to v5.1.

> [Download Windows Management Framework 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

If PowerShell is not regularly used or not connected to the internet like in many secure environments or servers you may need to switch PowerShell from using TLS 1.0 to TLS 1.2, so it can download the modules.
More information is published by the PowerShell Product Group in this [TLS1.2 and PowerShell](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/) support article.
Line 16 shows how to install a new version of Powershell Get.

> To mitigate this chance we have released a minor update to PowerShellGet which will allow you to continue to interact with the PowerShell Gallery.

To install SharePointDsc, run the following commands:

1. Open PowerShell as Administrator
1. Run `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`
1. Run `Register-PSRepository -Default`
1. Run `Install-Module -Name SharePointDSC`
1. Run `Install-Module ReverseDsc` (only if you want to export configurations)

## Installing in a secure environment

>If you followed steps above and received no errors you now have SharePoint DSC installed on your Machine and you can skip the next 2 steps.

1. If your server is not connected to the internet you should have received an error in the previous steps.
2. Run `Save-Module -Name SharePointDSC,ReverseDsc -Path C:\Temp` on the machine connected to the Internet. This will download the modules to the specified folder.
3. Alternatively you can also install the module on the local machine, but this is not necessary: `Install-Module -Name SharePointDSC,ReverseDsc` on the machine connected to the Internet. Type `[A]` for All.
4. Manually copy the SharePointDsc and ReverseDsc folders from `C:\Temp` (from step 2) or `C:\Program Files\WindowsPowerShell\Modules` (from step 3) folders. You can optionally zip the folders.
5. Copy / Unzip the folders to the target machine into the Modules folder at `C:\Program Files\WindowsPowerShell`

## Testing if the module is Installed

You can use the Verb `Get-InstalledModule` to see All modules you have installed.
You can also use this block specifically.

    Get-InstalledModule SharePointDSC ,ReverseDSC
