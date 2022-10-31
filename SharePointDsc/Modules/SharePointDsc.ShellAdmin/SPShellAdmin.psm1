function Get-SPDscDatabaseOwnerList
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $sqlInstances
    )

    $databaseOwners = $sqlInstances | ForEach-Object {
        $connection = New-Object -TypeName "System.Data.SqlClient.SqlConnection"
        $command = New-Object -TypeName "System.Data.SqlClient.SqlCommand"
        $connection.ConnectionString = "Server=$_;Integrated Security=SSPI;Database=master"

        try
        {
            $connection.Open()
            $command.Connection = $connection

            $command.CommandText = 'SELECT suser_sname(owner_sid) AS Owner, Name FROM sys.databases'

            $reader = $command.ExecuteReader()
            $results = @()
            while ($reader.Read())
            {
                $results += [PSCustomObject]@{
                    Database = $reader[1]
                    Owner    = $reader[0]
                }
            }
        }
        catch
        {
            throw "Error while running SQL query: $($_.Exception.InnerException.Message)"
            $results = $null
        }
        finally
        {
            if ($connection.State -eq "Open")
            {
                $connection.Close()
                $connection.Dispose()
            }
        }

        return $results
    }

    return $databaseOwners
}

Export-ModuleMember -Function *
