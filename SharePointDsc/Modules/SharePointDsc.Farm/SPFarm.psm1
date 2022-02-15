<#

.SYNOPSIS

Get-SPDscConfigDBStatus is used to determine the state of a configuration database

.DESCRIPTION

Get-SPDscConfigDBStatus will determine two things - firstly, if the config database
exists, and secondly if the user executing the script has appropriate permissions
to the instance to create the database. These values are used by the SPFarm resource
to determine what actions to take in it's set method.

.PARAMETER SQLServer

The name of the SQL server to check against

.PARAMETER Database

The name of the database to validate as the configuration database

.EXAMPLE

Get-SPDscConfigDBStatus -SQLServer sql.contoso.com -Database SP_Config

#>
function Get-SPDscConfigDBStatus
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $Database,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
    # If we specified SQL credentials then try to use them
    if ($PSBoundParameters.ContainsKey("DatabaseCredentials"))
    {
        $marshal = [Runtime.InteropServices.Marshal]
        $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=Master"
    }
    else # Just use Windows integrated auth
    {
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=Master"
    }
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    try
    {
        $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name
        $connection.Open()
        $command.Connection = $connection

        $command.CommandText = "SELECT COUNT(*) FROM sys.databases WHERE name = '$Database'"
        $configDBexists = ($command.ExecuteScalar() -eq 1)

        $serverRolesToCheck = @("dbcreator", "securityadmin")
        $hasPermissions = $true
        foreach ($serverRole in $serverRolesToCheck)
        {
            $command.CommandText = "SELECT IS_SRVROLEMEMBER('$serverRole')"
            if ($command.ExecuteScalar() -eq "0")
            {
                Write-Verbose -Message "$currentUser does not have '$serverRole' role on server '$SQLServer'"
                $hasPermissions = $false
            }
        }

        $configDBempty = $false
        if ($configDBexists -eq $true)
        {
            # Checking if ConfigDB contains any tables
            $connection.ChangeDatabase($Database)
            $command.CommandText = "SELECT COUNT(*) FROM sys.tables"
            $configDBempty = ($command.ExecuteScalar() -eq 0)
        }

        $connection.ChangeDatabase('TempDB')

        # Added $Database just in case multiple farms are added at once.
        Write-Verbose -Message "Testing lock for $Database"
        $command.CommandText = "SELECT COUNT([name]) FROM sys.tables WHERE [name] = '##SPDscLock$Database'"
        $lockExists = ($command.ExecuteScalar() -eq 1)

        return @{
            DatabaseExists   = $configDBexists
            DatabaseEmpty    = $configDBempty
            ValidPermissions = $hasPermissions
            Locked           = $lockExists
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

<#

.SYNOPSIS

Get-SPDscSQLInstanceStatus is used to determine the state of the SQL instance

.DESCRIPTION

Get-SPDscSQLInstanceStatus will determine the state of the MaxDOP setting. This
value is used by the SPFarm resource to determine if the SQL instance is ready
for SharePoint deployment.

.PARAMETER SQLServer

The name of the SQL server to check against

.EXAMPLE

Get-SPDscConfigDBStatus -SQLServer sql.contoso.com

#>
function Get-SPDscSQLInstanceStatus
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
    # If we specified SQL credentials then try to use them
    if ($PSBoundParameters.ContainsKey("DatabaseCredentials"))
    {
        $marshal = [Runtime.InteropServices.Marshal]
        $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=Master"
    }
    else # Just use Windows integrated auth
    {
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=Master"
    }
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    try
    {
        $currentUser = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name
        $connection.Open()
        $command.Connection = $connection

        $command.CommandText = "SELECT value_in_use FROM sys.configurations WHERE name = 'max degree of parallelism'"
        $maxDOPCorrect = ($command.ExecuteScalar() -eq 1)

        return @{
            MaxDOPCorrect = $maxDOPCorrect
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

<#

.SYNOPSIS

Add-SPDscConfigDBLock is used to create a lock to tell other servers that the
config DB is currently provisioning

.DESCRIPTION

Add-SPDscConfigDBLock will create an empty database with the same name as the
config DB but suffixed with "_Lock". The presences of this database will
indicate to other servers that the config database is in the process of being
provisioned as the database is removed at the end of the process.

.PARAMETER SQLServer

The name of the SQL server to check against

.PARAMETER Database

The name of the database to validate as the configuration database

.EXAMPLE

$lockConnection = Add-SPDscConfigDBLock -SQLServer sql.contoso.com -Database SP_Config

#>
function Add-SPDscConfigDBLock
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $Database,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials
    )

    Write-Verbose -Message "Creating lock for database $Database"

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
    # If we specified SQL credentials then try to use them
    if ($PSBoundParameters.ContainsKey("DatabaseCredentials"))
    {
        $marshal = [Runtime.InteropServices.Marshal]
        $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=Master"
    }
    else # Just use Windows integrated auth
    {
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=TempDB"
    }
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    try
    {
        $connection.Open()
        $command.Connection = $connection

        # Added $Database just in case multiple farms are added at once.
        $command.CommandText = "CREATE TABLE [##SPDscLock$Database] (Locked BIT)"
        $null = $command.ExecuteNonQuery()
    }
    finally
    {
        # cannot close the connection here, that would destroy the ##lock table
    }

    return $connection
}

<#

.SYNOPSIS

Remove-SPDscConfigDBLock will remove the lock created by the
Add-SPDscConfigDBLock command.

.DESCRIPTION

Remove-SPDscConfigDBLock will remove the lock created by the
Add-SPDscConfigDBLock command.

.PARAMETER SQLServer

The name of the SQL server to check against

.PARAMETER Database

The name of the database to validate as the configuration database

.EXAMPLE

Remove-SPDscConfigDBLock -SQLServer sql.contoso.com -Database SP_Config -Connection $lockConnection

#>
function Remove-SPDscConfigDBLock
{
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [String]
        $Database,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $DatabaseCredentials,

        [Parameter(Mandatory = $true)]
        [System.Data.SqlClient.SqlConnection]
        $Connection
    )

    Write-Verbose -Message "Removing lock for database $Database"

    if ($Connection.State -ne "Open")
    {
        $conn = New-Object -TypeName "System.Data.SqlClient.SqlConnection"

        # If we specified SQL credentials then try to use them
        if ($PSBoundParameters.ContainsKey("DatabaseCredentials"))
        {
            $marshal = [Runtime.InteropServices.Marshal]
            $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
            $conn.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=Master"
        }
        else # Just use Windows integrated auth
        {
            $conn.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=TempDB"
        }
    }
    else
    {
        $conn = $Connection
    }

    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"
    $command.Connection = $conn

    try
    {
        if ($conn.State -ne "Open")
        {
            $conn.Open()
        }

        $command.CommandText = "DROP TABLE [##SPDscLock$Database]"
        $null = $command.ExecuteNonQuery()
    }
    finally
    {
        if ($conn.State -eq "Open")
        {
            $conn.Close()
            $conn.Dispose()
        }
    }
}
