function Confirm-UserIsDBOwner
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String]
        $User,

        [Parameter()]
        [PSCredential]
        $DatabaseCredentials
    )

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    # If we specified SQL credentials then try to use them
    if ($PSBoundParameters.ContainsKey("DatabaseCredentials") -and `
            [System.String]::IsNullOrEmpty($DatabaseCredentials) -eq $false)
    {
        $marshal = [Runtime.InteropServices.Marshal]
        $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=master"
        $checkUser = $DatabaseCredentials.UserName
    }
    else # Just use Windows integrated auth
    {
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=master"
        $checkUser = $User
    }

    try
    {
        $connection.Open()
        $command.Connection = $connection

        $command.CommandText = @"
USE [{0}]

SELECT DP1.name AS DatabaseRoleName,
   isnull (DP2.name, 'No members') AS DatabaseUserName
 FROM sys.database_role_members AS DRM
 RIGHT OUTER JOIN sys.database_principals AS DP1
   ON DRM.role_principal_id = DP1.principal_id
 LEFT OUTER JOIN sys.database_principals AS DP2
   ON DRM.member_principal_id = DP2.principal_id
WHERE DP1.type = 'R' AND DP2.name = '{1}' AND DP1.name = 'db_owner'
"@ -f $Database, $checkUser

        $result = ($command.ExecuteScalar() -eq "db_owner")
    }
    catch
    {
        throw "Error while running SQL query: $($_.Exception.InnerException.Message)"
        $result = $false
    }
    finally
    {
        if ($connection.State -eq "Open")
        {
            $connection.Close()
            $connection.Dispose()
        }
    }

    return $result
}

function Set-UserAsDBOwner
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SQLServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [Parameter(Mandatory = $true)]
        [System.String]
        $User,

        [Parameter()]
        [PSCredential]
        $DatabaseCredentials
    )

    $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
    $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"

    # If we specified SQL credentials then try to use them
    $sqlauth = $false
    if ($PSBoundParameters.ContainsKey("DatabaseCredentials") -and `
            [System.String]::IsNullOrEmpty($DatabaseCredentials) -eq $false)
    {
        $sqlauth = $true
        $marshal = [Runtime.InteropServices.Marshal]
        $dbCredentialsPlainPassword = $marshal::PtrToStringAuto($marshal::SecureStringToBSTR($DatabaseCredentials.Password))
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=False;User ID=$($DatabaseCredentials.Username);Password=$dbCredentialsPlainPassword;Database=master"
    }
    else # Just use Windows integrated auth
    {
        $connection.ConnectionString = "Server=$SQLServer;Integrated Security=SSPI;Database=master"
    }

    try
    {
        $connection.Open()
        $command.Connection = $connection

        $sql = @"
USE [{0}]

DECLARE @NewUserName sysname;

SET @NewUserName = '{1}';

/* Users are typically mapped to logins, as OP's question implies,
so make sure an appropriate login exists. */
IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = @NewUserName) BEGIN
    /* Syntax for SQL server login.  See BOL for domain logins, etc. */
    DECLARE @LoginSQL as varchar(500);
    SET @LoginSQL = 'CREATE LOGIN ['+ @NewUserName + '] {2}';
    EXEC (@LoginSQL);
END

/* Create the user for the specified login. */
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = @NewUserName) BEGIN
    DECLARE @UserSQL as varchar(500);
    SET @UserSQL = 'CREATE USER [' + @NewUserName + '] FOR LOGIN [' + @NewUserName + ']';
    EXEC (@UserSQL);
END

IF NOT EXISTS
    (SELECT DP1.name AS DatabaseRoleName,
       isnull (DP2.name, 'No members') AS DatabaseUserName
     FROM sys.database_role_members AS DRM
     RIGHT OUTER JOIN sys.database_principals AS DP1
       ON DRM.role_principal_id = DP1.principal_id
     LEFT OUTER JOIN sys.database_principals AS DP2
       ON DRM.member_principal_id = DP2.principal_id
    WHERE DP1.type = 'R' AND DP2.name = @NewUserName AND DP1.name = 'db_owner')
BEGIN
    DECLARE @roleSQL as varchar(500);
    SET @roleSQL = 'ALTER ROLE db_owner ADD MEMBER [' + @NewUserName + ']';
    EXEC (@roleSQL);
END
"@

        if ($sqlauth -eq $true)
        {
            # Using SQL Auth
            $options = "WITH PASSWORD = ''{0}'', CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF" -f $DatabaseCredentials.GetNetworkCredential().Password
            $checkUser = $DatabaseCredentials.UserName
        }
        else
        {
            # Using Windows Integrated Auth
            $options = "FROM WINDOWS"
            $checkUser = $User
        }

        $command.CommandText = $sql -f $Database, $checkUser, $options
        $null = $command.ExecuteNonQuery()
    }
    catch
    {
        throw "Error while running SQL query: $($_.Exception.InnerException.Message)"
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

Export-ModuleMember -Function *
