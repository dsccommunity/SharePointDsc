<#
.EXAMPLE
    This module will install AppFabric Cumulative Update 7. The binaries for
    AppFabric Update in this scenario are stored at C:\SPAppFabricUpdate.
    The build version will be '1.0.4657.2' after installation. The CuExeName
    is the default name from https://www.microsoft.com/en-us/download/details.aspx?id=49171.
#>

    Configuration Example 
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc

        node localhost {
            SPInstallAppFabricUpdate InstallAppFabricCU7
            {
                BinaryDir  = "C:\SPAppFabricUpdate"
                Build = '1.0.4657.2' #CU 07
                CuExeName = 'AppFabric-KB3092423-x64-ENU.exe'
            }
        }

    }
