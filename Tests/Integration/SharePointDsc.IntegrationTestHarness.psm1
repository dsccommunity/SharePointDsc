function Invoke-SPDscIntegrationTest() { 
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    param()

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\" -Resolve

    $global:SPDscIntegrationGlobals = Import-LocalizedData -FileName GlobalVariables.psd1 `
                                                           -BaseDirectory $PSScriptRoot

    # Pre-create and store all the credentials for service accounts
    $CredentialPool = @{}
    $global:SPDscIntegrationGlobals.ActiveDirectory.ServiceAccounts.Keys | ForEach-Object -Process {
        $credentialData = $global:SPDscIntegrationGlobals.ActiveDirectory.ServiceAccounts.$_
        $username = "$($global:SPDscIntegrationGlobals.ActiveDirectory.NetbiosName)\$($credentialData.Username)"
        $SecurePassword = ConvertTo-SecureString $credentialData.Password -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential `
                                 -ArgumentList ($username, $SecurePassword)
        $CredentialPool.Add($_, $Credential) 
    }

    $passphrase = ConvertTo-SecureString "SharePoint156!" -AsPlainText -Force
    $Global:SPDscFarmPassphrase = New-Object -TypeName System.Management.Automation.PSCredential `
                                             -ArgumentList ("passphrase", $passphrase)
    $global:SPDscIntegrationCredPool = $CredentialPool

    $global:SPDscIntegrationConfigData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowDomainUser = $true
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
    
    # Run preflight checks
    $preflightTests = Invoke-Pester "$repoDir\Tests\Integration" -Tag "Preflight" -PassThru

    if ($preflightTests.FailedCount -gt 0) {
        throw "Preflight tests have failed!"
        return
    }
    
    # Setup test sequence
    $testSequence = @("Farm", "ServiceApp", "WebApp", "Site", "PostDeploy")
    $testResults = @{}
    
    # Execute Pre, main and Post tests for each sequence object
    $testSequence | ForEach-Object -Process {
        Write-Verbose "Starting tests for 'Pre$_'"
        $testResults.Add("Pre$_", (Invoke-Pester "$repoDir\Tests\Integration" -Tag "Pre$_" -PassThru))
        
        Write-Verbose "Starting tests for '$_'"
        $testResults.Add("$_", (Invoke-Pester "$repoDir\Tests\Integration" -Tag "$_" -PassThru))
        
        Write-Verbose "Starting tests for 'Post$_'"
        $testResults.Add("Post$_", (Invoke-Pester "$repoDir\Tests\Integration" -Tag "Post$_" -PassThru))
    }
    
    # Output the results
    $testResults.Keys | ForEach-Object -Process {
        $result = $testResults.$_
        Write-Output -InputObject "$_ - Passed: $($result.PassedCount) Failed: $($result.FailedCount)"
        $result.TestResult | Where-Object { $_.Passed -ne $true }
    }
}
