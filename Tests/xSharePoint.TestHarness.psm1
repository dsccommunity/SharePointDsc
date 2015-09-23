function Invoke-xSharePointTests() {
    $repoDir = Join-Path $PSScriptRoot "..\" -Resolve

    $testCoverageFiles = @()
    Get-ChildItem "$repoDir\modules\xSharePoint\**\*.psm1" -Recurse | ForEach-Object { $testCoverageFiles += $_.FullName }

    $results = Invoke-Pester -Script @(
        @{
            'Path' = $repoDir
            'Parameters' = @{ 
                'SharePointCmdletModule' = (Join-Path $repoDir "\Tests\Stubs\SharePoint\15.0.4693.1000\Microsoft.SharePoint.PowerShell.psm1")
            }
        },
        @{
            'Path' = $repoDir
            'Parameters' = @{ 
                'SharePointCmdletModule' = (Join-Path $repoDir "\Tests\Stubs\SharePoint\16.0.4316.1217\Microsoft.SharePoint.PowerShell.psm1") 
            }
        }
    ) -CodeCoverage $testCoverageFiles -PassThru
}

function Write-xSharePointStubFiles() {
    param
    (
        [parameter(Mandatory = $true)] [System.String] $SharePointStubPath,
        [parameter(Mandatory = $true)] [System.String] $DCacheStubPath
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell 

    $SPStubContent = ((Get-Command | Where-Object { $_.Source -eq "Microsoft.SharePoint.PowerShell" } )  |  ForEach-Object -Process {
       $signature = $null
       $command = $_
       $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $command
       $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)  
       foreach ($line in $definition -split "`n")
       {
           if ($line.Trim() -eq 'begin')
           {
               break
           }
           $signature += $line
       }
       "function $($command.Name) { `n  $signature `n } `n"
    }) | Out-String

    foreach ($line in $SPStubContent.Split([Environment]::NewLine)) {
        $line = $line.Replace("[System.Nullable``1[[Microsoft.Office.Server.Search.Cmdlet.ContentSourceCrawlScheduleType, Microsoft.Office.Server.Search.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line.Replace("[System.Collections.Generic.List``1[[Microsoft.SharePoint.PowerShell.SPUserLicenseMapping, Microsoft.SharePoint.PowerShell, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]], mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]", "[object]")
        $line = $line -replace "\[System.Nullable\[Microsoft.*]]", "[System.Nullable[object]]"
        $line = $line -replace "\[Microsoft.*.\]", "[object]"
        
        $line | Out-File $SharePointStubPath -Encoding utf8 -Append
    }
   

    Use-CacheCluster

    $dcacheStubContent = ((Get-Command | Where-Object { $_.Source -match "DistributedCache*" } )  |  ForEach-Object -Process {
        $signature = $null
        $command = $_
        $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $command 
        $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)
        foreach ($line in $definition -split "`n")
        {
            if ($line.Trim() -eq 'begin')
            {
                break
            }
            $signature += $line
        }
        "function $($command.Name) { `n  $signature `n } `n"
    }) | Out-String

   foreach ($line in $dcacheStubContent.Split([Environment]::NewLine)) {
        $line = $line -replace "\[System.Nullable\[Microsoft.*]]", "[System.Nullable[object]]"
        $line = $line -replace "\[Microsoft.*.\]", "[object]"
        
        $line | Out-File $DCacheStubPath -Encoding utf8 -Append
   }
}