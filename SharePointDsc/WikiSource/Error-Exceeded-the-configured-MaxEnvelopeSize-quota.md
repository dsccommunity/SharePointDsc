When deploying DSC configurations, you may run into the following issue when executing Start-DscConfiguration:

    VERBOSE: Perform operation 'Invoke CimMethod' with following parameters, ''methodName' = SendConfigurationApply,'className' = MSFT_DSCLocalConfigurationManager,'namespaceName' = root/Microsoft/Windows/DesiredStateConfiguration'.
    The WinRM client sent a request to the remote WS-Management service and was notified that the request size exceeded the configured MaxEnvelopeSize quota.
    + CategoryInfo : LimitsExceeded: [root/Microsoft/...gurationManager:String] [], CimException
    + FullyQualifiedErrorId : HRESULT 0x80338111
    + PSComputerName : [servername]
    VERBOSE: Operation 'Invoke CimMethod' complete.
    VERBOSE: Time taken for configuration job to complete is 0.648 seconds

## Solution
The solution for this issue is to increase the maximum envelope size, by running the following command in an elevated PowerShell session:

    Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value 2048

**Note:** The default value is MaxEnvelopeSizeKB is 500

**Note 2:** When your computer is configured to use the Public network profile, the Set-Item cmdlet might throw the following error:

    Set-Item : WinRM firewall exception will not work since one of the network connection types on this machine is set to Public. Change the network connection type to either Domain or Private and try again.

Change the network profile to Domain or Private in order to change the setting.

## More information
More information about the MaxEnvelopeSize can be found at:
* https://msdn.microsoft.com/en-us/library/cc251449.aspx
* https://msdn.microsoft.com/en-us/library/aa384372%28VS.85%29.aspx
