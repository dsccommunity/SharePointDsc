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

<#

.SYNOPSIS

Get-SPDscConfigDBConnectionEncryption returns the current Value for the DatabaseConnectionEncryption and DatabaseServerCertificateHostName.

.DESCRIPTION

Get-SPDscConfigDBConnectionEncryption returns the current Value for the DatabaseConnectionEncryption and DatabaseServerCertificateHostName.

.EXAMPLE

Get-SPDscConfigDBConnectionEncryption

#>
function Get-SPDscConfigDBConnectionEncryption
{
    param
    (
    )

    Write-Verbose -Message "Getting SQL Connection String from registry to extract Database Connection Encryption and Database Server Certificate Hostname"

    $installedVersion = Get-SPDscInstalledProductVersion

    $getSPFarmConnectionString = @{
        Key         = "hklm:SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\$($installedVersion.FileMajorPart).0\Secure\ConfigDB"
        Value       = 'dsn'
        ErrorAction = 'SilentlyContinue'
    }
    $connectionString = Get-SPDscRegistryKey @getSPFarmConnectionString
    $sqlConnectionString = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new($connectionString)

    # DatabaseConnectionEncryption
    $databaseConnectionEncryptionValue = if ([Microsoft.Data.SqlClient.SqlConnectionEncryptOption]::Mandatory -eq $sqlConnectionString.Encrypt)
    {
        'Mandatory'
    }
    elseif ([Microsoft.Data.SqlClient.SqlConnectionEncryptOption]::Optional -eq $sqlConnectionString.Encrypt)
    {
        'Optional'
    }
    elseif ([Microsoft.Data.SqlClient.SqlConnectionEncryptOption]::Strict -eq $sqlConnectionString.Encrypt)
    {
        'Strict'
    }
    else
    {
        $null
    }
    $return = [PSCustomObject]@{
        DatabaseConnectionEncryption      = $databaseConnectionEncryptionValue
        DatabaseServerCertificateHostName = $sqlConnectionString.HostNameInCertificate
    }
    return $return
}

<#

.SYNOPSIS

Get-SPDscCentralAdminSecureBinding returns the secure binding to manage for the Central
Administration HTTPS endpoint.

.DESCRIPTION

Get-SPDscCentralAdminSecureBinding selects, from a zone's SecureBindings collection, the binding
that matches the target host header and port. Central Administration normally has a single secure
binding, so when no explicit match is found (for example an IP-based binding with no host header)
the first binding is returned. Returns $null when there are no secure bindings.

.PARAMETER SecureBindings

The SecureBindings collection of the zone's IIS settings.

.PARAMETER HostHeader

The target host header.

.PARAMETER Port

The target port.

.EXAMPLE

Get-SPDscCentralAdminSecureBinding -SecureBindings $bindings -HostHeader "admin.contoso.com" -Port 443

#>
function Get-SPDscCentralAdminSecureBinding
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter()]
        [System.Object]
        $SecureBindings,

        [Parameter(Mandatory = $true)]
        [System.String]
        $HostHeader,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Port
    )

    # Normalise to an array: when the Default zone has a single secure binding, the
    # SecureBindings property is passed through as a single object rather than a collection, so
    # indexing with [0] would return $null (or index into a hashtable). Wrapping with @() makes
    # both the single-binding and multi-binding cases behave consistently.
    $bindings = @($SecureBindings)
    if ($bindings.Count -eq 0)
    {
        return $null
    }

    $match = $bindings | Where-Object -FilterScript {
        $_.HostHeader -eq $HostHeader -and $_.Port -eq $Port
    } | Select-Object -First 1

    if ($null -ne $match)
    {
        return $match
    }

    return $bindings[0]
}

<#

.SYNOPSIS

Test-SPDscCentralAdminBindingMatch indicates whether a secure binding already carries the
desired certificate and settings.

.DESCRIPTION

Test-SPDscCentralAdminBindingMatch returns $true when the supplied secure binding is bound to
the certificate identified by Thumbprint and, when specified, matches the desired SNI and legacy
encryption settings. It guards against a cert-less binding so that reading Certificate.Thumbprint
on a $null certificate does not throw.

.PARAMETER Binding

The secure binding object to evaluate. May be $null (returns $false).

.PARAMETER Thumbprint

The thumbprint the binding is expected to carry.

.PARAMETER UseServerNameIndication

When specified, the expected Server Name Indication (SNI) setting of the binding.

.PARAMETER AllowLegacyEncryption

When specified, the expected legacy encryption setting of the binding.

.EXAMPLE

Test-SPDscCentralAdminBindingMatch -Binding $binding -Thumbprint "AB12..." -UseServerNameIndication $true

#>
function Test-SPDscCentralAdminBindingMatch
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Object]
        $Binding,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [Parameter()]
        [System.Boolean]
        $UseServerNameIndication,

        [Parameter()]
        [System.Boolean]
        $AllowLegacyEncryption
    )

    if ($null -eq $Binding -or $null -eq $Binding.Certificate -or $Binding.Certificate.Thumbprint -ne $Thumbprint)
    {
        return $false
    }
    if ($PSBoundParameters.ContainsKey('UseServerNameIndication') -and `
            $Binding.UseServerNameIndication -ne $UseServerNameIndication)
    {
        return $false
    }
    if ($PSBoundParameters.ContainsKey('AllowLegacyEncryption') -and `
        (-not $Binding.DisableLegacyTls) -ne $AllowLegacyEncryption)
    {
        return $false
    }
    return $true
}

<#

.SYNOPSIS

Set-SPDscCentralAdministrationCertificate binds a managed certificate to the Central
Administration HTTPS binding on the Default zone.

.DESCRIPTION

Set-SPDscCentralAdministrationCertificate resolves a certificate from SharePoint Certificate
Management (the EndEntity store) by thumbprint and binds it to the Central Administration web
application HTTPS binding using Set-SPWebApplication. It is only usable on SharePoint Server
Subscription Edition.

If the certificate is not present in Certificate Management the function writes a warning and
skips the bind (without throwing), leaving the HTTPS binding cert-less so that a dependent
SPCertificate resource can import the certificate after the farm exists; the binding then
converges on a later pass. Because a freshly imported certificate can be transiently non-bindable,
the bind is retried a bounded number of times and verified against the resulting binding
thumbprint.

.PARAMETER Thumbprint

The thumbprint of the managed certificate to bind.

.PARAMETER HostHeader

The host header of the Central Administration HTTPS binding.

.PARAMETER Port

The port of the Central Administration HTTPS binding.

.PARAMETER UseServerNameIndication

Specifies whether Server Name Indication (SNI) is enabled on the binding.

.PARAMETER AllowLegacyEncryption

Specifies whether legacy (TLS 1.0/1.1) encryption is allowed on the binding.

.EXAMPLE

Set-SPDscCentralAdministrationCertificate -Thumbprint "AB12..." -HostHeader "admin.contoso.com" -Port 443 -UseServerNameIndication $true

#>
function Set-SPDscCentralAdministrationCertificate
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Thumbprint,

        [Parameter(Mandatory = $true)]
        [System.String]
        $HostHeader,

        [Parameter(Mandatory = $true)]
        [System.UInt32]
        $Port,

        [Parameter()]
        [System.Boolean]
        $UseServerNameIndication,

        [Parameter()]
        [System.Boolean]
        $AllowLegacyEncryption
    )

    $cert = Get-SPCertificate -Thumbprint $Thumbprint -Store 'EndEntity' -ErrorAction SilentlyContinue
    if ($null -eq $cert)
    {
        # The certificate is not in Certificate Management yet. This is expected on the first
        # convergence pass of a brand-new farm, where SPCertificate (which depends on SPFarm)
        # imports the certificate only after the farm exists. Rather than failing the whole
        # configuration run, skip the bind and leave the HTTPS binding cert-less. Test-TargetResource
        # keeps reporting the drift, so the binding converges on a later pass once the certificate
        # has been imported.
        Write-Warning -Message ("No certificate found in SharePoint Certificate Management with " + `
                "thumbprint '$Thumbprint'. Skipping the Central Administration certificate binding " + `
                "for now. Make sure the certificate is imported (for example using the SPCertificate " + `
                "resource); the binding will be applied on a subsequent configuration pass.")
        return
    }

    $maxAttempts = 3
    $delaySeconds = 10

    $hasSni = $PSBoundParameters.ContainsKey('UseServerNameIndication')
    $hasLegacy = $PSBoundParameters.ContainsKey('AllowLegacyEncryption')

    $matchParams = @{
        Thumbprint = $Thumbprint
    }
    if ($hasSni)
    {
        $matchParams.Add('UseServerNameIndication', $UseServerNameIndication)
    }
    if ($hasLegacy)
    {
        $matchParams.Add('AllowLegacyEncryption', $AllowLegacyEncryption)
    }

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++)
    {
        $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication -eq $true
        }

        # Central Administration normally has a single secure binding; prefer the one matching the
        # target host header and port, and fall back to the first entry otherwise.
        $binding = Get-SPDscCentralAdminSecureBinding `
            -SecureBindings $ca.GetIisSettingsWithFallback('Default').SecureBindings `
            -HostHeader $HostHeader -Port $Port

        # Idempotence: skip the (re)bind when the binding already matches the desired settings. This
        # keeps a Set triggered by an unrelated property drift from re-applying the binding.
        if (Test-SPDscCentralAdminBindingMatch -Binding $binding @matchParams)
        {
            Write-Verbose -Message ("Central Administration HTTPS binding is already bound to " + `
                    "certificate '$Thumbprint'.")
            return
        }

        $setParams = @{
            Identity           = $ca
            Zone               = 'Default'
            Port               = $Port
            HostHeader         = $HostHeader
            SecureSocketsLayer = $true
            Certificate        = $cert
        }
        if ($hasSni)
        {
            $setParams.Add('UseServerNameIndication', $UseServerNameIndication)
        }
        if ($hasLegacy)
        {
            $setParams.Add('AllowLegacyEncryption', $AllowLegacyEncryption)
        }

        Set-SPWebApplication @setParams | Out-Null

        # Verify the binding actually carries the desired thumbprint. Right after an import the
        # certificate can be transiently non-bindable, so retry a bounded number of times.
        $ca = Get-SPWebApplication -IncludeCentralAdministration | Where-Object -FilterScript {
            $_.IsAdministrationWebApplication -eq $true
        }
        $binding = Get-SPDscCentralAdminSecureBinding `
            -SecureBindings $ca.GetIisSettingsWithFallback('Default').SecureBindings `
            -HostHeader $HostHeader -Port $Port
        if (Test-SPDscCentralAdminBindingMatch -Binding $binding @matchParams)
        {
            Write-Verbose -Message ("Central Administration HTTPS binding is now bound to " + `
                    "certificate '$Thumbprint'.")
            return
        }

        if ($attempt -lt $maxAttempts)
        {
            Write-Verbose -Message ("The Central Administration certificate binding has not taken " + `
                    "effect yet (attempt $attempt/$maxAttempts). Waiting $delaySeconds seconds " + `
                    "before retrying...")
            Start-Sleep -Seconds $delaySeconds
        }
    }

    throw ("Failed to bind certificate '$Thumbprint' to the Central Administration HTTPS " + `
            "binding after $maxAttempts attempts.")
}
