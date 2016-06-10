function Invoke-xSharePointIntegrationTests() { 
    param()

    $repoDir = Join-Path $PSScriptRoot "..\" -Resolve

    $global:xSPIntegrationGlobals = Import-LocalizedData -FileName GlobalVariables.psd1 -BaseDirectory $PSScriptRoot

    # Pre-create and store all the credentials for service accounts
    $CredentialPool = @{}
    $global:xSPIntegrationGlobals.ActiveDirectory.ServiceAccounts.Keys | ForEach-Object {
        $credentialData = $global:xSPIntegrationGlobals.ActiveDirectory.ServiceAccounts.$_
        $SecurePassword = ConvertTo-SecureString $credentialData.Password -AsPlainText -Force 
        $Credential = New-Object System.Management.Automation.PSCredential ("$($global:xSPIntegrationGlobals.ActiveDirectory.NetbiosName)\$($credentialData.Username)", $SecurePassword)
        $CredentialPool.Add($_, $Credential) 
    }
    $Global:xSPFarmPassphrase = New-Object System.Management.Automation.PSCredential ("passphrase", (ConvertTo-SecureString "SharePoint156!" -AsPlainText -Force))
    $global:xSPIntegrationCredPool = $CredentialPool

    $global:xSPIntegrationConfigData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowDomainUser = $true
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
    

    # Run preflight checks
    $preflightTests = Invoke-Pester "$repoDir\IntegrationTests" -Tag "Preflight" -PassThru

    if ($preflightTests.FailedCount -gt 0) {
        throw "Preflight tests have failed!"
        return
    }
    
    # Setup test sequence
    $testSequence = @("Farm", "WebApp", "Site")
    $testResults = @{}
    
    # Execute Pre, main and Post tests for each sequence object
    $testSequence | ForEach-Object {
        Write-Verbose "Starting tests for 'Pre$_'"
        $testResults.Add("Pre$_", (Invoke-Pester "$repoDir\IntegrationTests" -Tag "Pre$_" -PassThru))
        
        Write-Verbose "Starting tests for '$_'"
        $testResults.Add("$_", (Invoke-Pester "$repoDir\IntegrationTests" -Tag "$_" -PassThru))
        
        Write-Verbose "Starting tests for 'Post$_'"
        $testResults.Add("Post$_", (Invoke-Pester "$repoDir\IntegrationTests" -Tag "Post$_" -PassThru))
    }
    
    # Output the results
    $testResults.Keys | ForEach-Object {
        $result = $testResults.$_
        if ($result.FailedCount -gt 0) { $colour = "Red" } else { $colour = "Green" }
        Write-Host "$_ - Passed: $($result.PassedCount) Failed: $($result.FailedCount)" -ForegroundColor $colour 
        $result.TestResult | Where-Object { $_.Passed -ne $true }
    }
}