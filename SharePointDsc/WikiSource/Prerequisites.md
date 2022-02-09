To run PowerShell DSC, you need to have PowerShell 4.0 or higher (which is included in Windows Management Framework 4.0 or higher).
This version of PowerShell is shipped with Windows Server 2012 R2, and Windows 8.1 or higher.

To use DSC on earlier versions of Windows, install the Windows Management Framework 4.0.

However it is strongly recommended that PowerShell 5.0 (or above) is used, as it adds support for the PsDscRunAsCredential parameter and has overall better performance and troubleshooting capabilities.

The logic behind this is explained on the page "[Remote sessions and the InstallAccount variable](Remote-sessions-and-the-InstallAccount-variable)" page.

[PowerShell 5.1](https://www.microsoft.com/en-us/download/details.aspx?id=54616) includes significant improvements in Desired State Configuration and PowerShell Script Debugging.
