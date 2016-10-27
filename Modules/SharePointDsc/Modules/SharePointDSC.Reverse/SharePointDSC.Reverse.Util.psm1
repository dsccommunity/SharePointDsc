<## This function receives the path to a DSC module, and a parameter name. It then returns the type associated with the parameter (int, string, etc.). #>
function Get-DSCParamType
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] [System.String] $FilePath,
        [parameter(Mandatory = $true)] [System.String] $ParamName
    )

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref] $tokens, [ref] $errors)
    $functions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
    
    $functions | ForEach-Object {

        if ($_.Name -eq "Get-TargetResource") 
        {
            $function = $_
            $functionAst = [System.Management.Automation.Language.Parser]::ParseInput($_.Body, [ref] $tokens, [ref] $errors)

            $parameters = $functionAst.FindAll( {$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $parameters | ForEach-Object {
                if($_.Name.Extent.Text -eq $ParamName)
                {
                    $attributes = $_.Attributes
                    $attributes | ForEach-Object{
                        if($_.TypeName.FullName -like "System.*")
                        {
                            return $_.TypeName.FullName
                        }
                    }                    
                }
            }
        }
     }
     return $null
 }

<## This function loops through a HashTable and returns a string that combines all the Key/Value pairs into a DSC param block. #>
function Get-DSCBlock
{
    [CmdletBinding()]
    param(
        [System.Collections.Hashtable] $Params,
        [System.String] $ModulePath
    )

    $dscBlock = ""
    $foundInstallAccount = $false
    $Params.Keys | % { 
        $paramType = Get-DSCParamType -FilePath $ModulePath -ParamName "`$$_"

        $value = $null
        if($paramType -eq "System.String")
        {
            $value = "`"" + $Params.Item($_) + "`""
        }
        elseif($paramType -eq "System.Boolean")
        {
            $value = "`$" + $Params.Item($_)
        }
        elseif($paramType -eq "System.Management.Automation.PSCredential" -and $_ -ne "InstallAccount")
        {
            $value = "`$CredsFarmAccount #`"" + ($Params.Item($_)).Username + "`""
        }
        else
        {
            if($_ -eq "InstallAccount")
            {
                $value = "`$CredsFarmAccount"
                $foundInstallAccount = $true
            }
            else
            {
                $value = $Params.Item($_)
            }
        }
        $dscBlock += "            " + $_  + " = " + $value + ";`r`n"
    }

    if(!$foundInstallAccount)
    {
        $dscBlock += "            PsDscRunAsCredential=`$CredsFarmAccount;`r`n"
    }
    
    return $dscBlock
}

<## This function generates an empty hash containing fakes values for all input parameters of a Get-TargetResource function. #>
function Get-DSCFakeParameters{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)] [System.String] $FilePath,
        [parameter(Mandatory = $false)] [System.Management.Automation.PSCredential] $FarmAccount
    )

    $params = @{}

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref] $tokens, [ref] $errors)
    $functions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
    
    $functions | ForEach-Object {

        if ($_.Name -eq "Get-TargetResource") 
        {
            $function = $_
            $functionAst = [System.Management.Automation.Language.Parser]::ParseInput($_.Body, [ref] $tokens, [ref] $errors)

            $parameters = $functionAst.FindAll( {$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)
            $parameters | ForEach-Object {   
                $paramName = $_.Name.Extent.Text             
                $attributes = $_.Attributes
                $found = $false

                <# Loop once to figure out if there is a validate Set to use. #>
                $attributes | ForEach-Object{
                    if($_.TypeName.FullName -eq "ValidateSet")
                    {
                        $params.Add($paramName.Replace("`$", ""), $_.PositionalArguments[0].ToString().Replace("`"", ""))
                        $found = $true
                    }
                }
                $attributes | ForEach-Object{
                    if(!$found)
                    {
                        if($_.TypeName.FullName -eq "System.String")
                        {
                            $params.Add($paramName.Replace("`$", ""), "*")
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.UInt32")
                        {
                            $params.Add($paramName.Replace("`$", ""), 0)
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.Management.Automation.PSCredential")
                        {
                            $params.Add($paramName.Replace("`$", ""), $FarmAccount)                            
                            $found = $true
                        }
                        elseif($_.TypeName.FullName -eq "System.Management.Automation.Boolean" -or $_.TypeName.FullName -eq "System.Boolean")
                        {
                            $params.Add($paramName.Replace("`$", ""), $true)
                            $found = $true
                        }
                    }
                }
            }
        }
     }
     return $params
}

<## This function receives a user name and returns the "Display Name" for that user. This function is primarly used to identify the Farm (System) account. #>
function Check-Credentials([string] $userName)
{
    if($userName -eq $Script:spCentralAdmin.ApplicationPool.ProcessAccount.Name)
    {
        return "`$CredsFarmAccount"
    }
    else
    {
        $userNameParts = $userName.Split('\')
        if($userNameParts.Length -gt 1)
        {
            return "`$Creds" + $userNameParts[1]
        }
        return "`$Creds" + $userName
    }
    return $userName
}

<## This function defines variables of type Credential for the resulting DSC Configuraton Script. Each variable declared in this method will result in the user being prompted to manually input credentials when executing the resulting script. #>
function Set-ObtainRequiredCredentials
{
    # Farm Account
    $localspFarmAccount = $Global:spCentralAdmin.ApplicationPool.ProcessAccount.Name
    $requiredCredentials = @($localspFarmAccount)
    $managedAccounts = Get-SPManagedAccount
    foreach($managedAccount in $managedAccounts)
    {
        $requiredCredentials += $managedAccounts.UserName
    }

    $spServiceAppPools = Get-SPServiceApplicationPool
    foreach($spServiceAppPool in $spServiceAppPools)
    {
        $requiredCredentials += $spServiceAppPools.ProcessAccount.Name
    }

    $requiredCredentials = $requiredCredentials | Select -Unique

    foreach($account in $requiredCredentials)
    {
        $accountName = $account
        if($account -eq $localspFarmAccount)
        {
            $accountName = "FarmAccount"
        }
        else
        {
            $accountParts = $accountName.Split('\')
            if($accountParts.Length -gt 1)
            {
                $accountName = $accountParts[1]
            }
        }
        $Script:dscConfigContent += "    `$Creds" + $accountName + "= Get-Credential -UserName `"" + $account + "`" -Message `"Credentials for " + $account + "`"`r`n"
    }

    $Script:dscConfigContent += "`r`n"
}
