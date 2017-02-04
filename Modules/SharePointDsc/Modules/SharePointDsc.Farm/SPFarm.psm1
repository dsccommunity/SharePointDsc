<#

.SYNOPSIS

Get-SPDSCConfigDBStatus is used to determine the state of a configuration database

.DESCRIPTION

Get-SPDSCConfigDBStatus will determine two things - firstly, if the config database
exists, and secondly if the user executing the script has appropriate permissions
to the instance to create the database. These values are used by the SPFarm resource
to determine what actions to take in it's set method.

.PARAMETER SQLServer

The name of the SQL server to check against

.PARAMETER Database

The name of the database to validate as the configuration database

.EXAMPLE

Get-SPDSCConfigDBStatus -SQLServer sql.contoso.com -Database SP_Config

#>
function Get-SPDSCConfigDBStatus
{
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $Database
    )

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlServer"
    $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;" #TODO: Add database name here to connect to master
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    try 
    {
        $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name
        $connection.Open()
        $command.Connection = $connection

        #TODO: Do a query against the master database to determine if the config DB exists
        $configDBexists = $false

        $serverRolesToCheck = @("dbcreator", "securityadmin")
        $hasPermissions = $false
        foreach ($serverRole in $serverRolesToCheck)
        {
            $command.CommandText = "SELECT IS_SRVROLEMEMBER('$serverRole')"
            $reader = $command.ExecuteReader()
            $reader.Read()

            #TODO: Validate that this works
            if ($objSQLDataReader.GetValue(0) -eq 0)
            {
                Write-Verbose -Message "$currentUser does not have '$serverRole' role on server '$SQLServer'"
                $hasPermissions = $false
            }
        }

        return @{
            DatabaseExists = $configDBexists
            ValidPermissions = $hasPermissions
        }
    }
    finally
    {
        if ($connection.State -eq "Open") 
        {
            $connection.Close()
            $connection.Dispose()
        }
    }
}
