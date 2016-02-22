function Get-MofSchemaObject() {
    param(
        [Parameter(Mandatory=$True)]
        [string]$fileName
    )
    $contents = Get-Content $fileName

    $results = @()

    $currentResult = @{
        ClassVersion = $null
        FriendlyName = $null
        ClassName = $null
        Attributes = @()
        Documentation = $null
    }

    $currentComment = ""
    $currentlyInCommentBlock = $false
    foreach($textLine in $contents) {
        if ($textLine.StartsWith("/*")) {
            $currentlyInCommentBlock = $true
        } elseif($textLine.StartsWith("*/")) {
            $currentlyInCommentBlock = $false
            $currentResult.Documentation = $currentComment
        } elseif($currentlyInCommentBlock -eq $true) {
            $currentComment += $textLine + [Environment]::NewLine
        } elseif ($textLine -match "ClassVersion" -or $textLine -match "FriendlyName") {
            if ($textLine -match "ClassVersion(`"*.`")") {
                $start = $textLine.IndexOf("ClassVersion(`"") + 14
                $end = $textLine.IndexOf("`")", $start)
                $currentResult.ClassVersion = $textLine.Substring($start, $end - $start)
            }

            if ($textLine -match "FriendlyName(`"*.`")") {
                $start = $textLine.IndexOf("FriendlyName(`"") + 14
                $end = $textLine.IndexOf("`")", $start)
                $currentResult.FriendlyName = $textLine.Substring($start, $end - $start)
            }
        } elseif ($textLine -match "class ") {
            $start = $textLine.ToLower().IndexOf("class ") + 6
            $end = $textLine.IndexOf(" ", $start)
            if ($end -eq -1) {
                $end = $textLine.Length
            }
            $currentResult.ClassName = $textLine.Substring($start, $end - $start)
        } elseif ($textLine.Trim() -eq "{" -or [string]::IsNullOrEmpty($textLine.Trim())) {
        } elseif ($textLine.Trim() -eq "};") {
            $results += $currentResult
            $currentResult = @{
                ClassVersion = $null
                FriendlyName = $null
                ClassName = $null
                Attributes = @()
                Documentation = $null
            }
        } else {
            $attributeValue = @{
                State = $null
                EmbeddedInstance = $null
                ValueMap = $null
                DataType = $null
                Name = $null
                Description = $null
                IsArray = $false
            }

            $start = $textLine.IndexOf("[") + 1
            $end = $textLine.IndexOf("]", $start)
            $metadataEnd = $end
            $metadata = $textLine.Substring($start, $end - $start)
            $metadataObjects = $metadata.Split(",")
            $attributeValue.State = $metadataObjects[0]

            $metadataObjects | ForEach-Object {
                if ($_.Trim().StartsWith("EmbeddedInstance")) {
                    $start = $textLine.IndexOf("EmbeddedInstance(`"") + 18
                    $end = $textLine.IndexOf("`")", $start)
                    $attributeValue.EmbeddedInstance = $textLine.Substring($start, $end - $start)
                }
                if ($_.Trim().StartsWith("ValueMap")) {
                    $start = $textLine.IndexOf("ValueMap{") + 9
                    $end = $textLine.IndexOf("}", $start)
                    $valueMap = $textLine.Substring($start, $end - $start)
                    $attributeValue.ValueMap = $valueMap.Replace("`"", "").Split(",")
                }
                if ($_.Trim().StartsWith("Description")) {
                    $start = $textLine.IndexOf("Description(`"") + 13
                    $end = $textLine.IndexOf("`")", $start)
                    $attributeValue.Description = $textLine.Substring($start, $end - $start)
                }
            }
        
            $nonMetadata = $textLine.Replace(";","").Substring($metadataEnd + 1)

            $nonMetadataObjects =  $nonMetadata.Split(" ")
            $attributeValue.DataType = $nonMetadataObjects[1]
            $attributeValue.Name = $nonMetadataObjects[2]

            if ($attributeValue.Name.EndsWith("[]") -eq $true) {
                $attributeValue.Name = $attributeValue.Name.Replace("[]", "")
                $attributeValue.IsArray = $true
            }

            $currentResult.Attributes += $attributeValue
        }
    }
    return $results
}

function Assert-MofSchemaScriptParameters() {
    param(
        [Parameter(Mandatory=$True)]
        [string]$mofFileName
    )
    $hasErrors = $false
    $mofSchemas = Get-MofSchemaObject -fileName $mofFileName
    $mofData = $mofSchemas | Where-Object { $_.ClassName -eq (Get-Item $mofFileName).Name.Replace(".schema.mof", "") }
    $psFile = $mofFileName.Replace(".schema.mof", ".psm1")

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($psFile, [ref] $tokens, [ref] $errors)
    $functions = $ast.FindAll( {$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)

    $functions | ForEach-Object {
        if ($_.Name -like "*-TargetResource") {
            $function = $_
            $astTokens = $null
            $astErrors = $null
            $functionAst = [System.Management.Automation.Language.Parser]::ParseInput($_.Body, [ref] $astTokens, [ref] $astErrors)

            $parameters = $functionAst.FindAll( {$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $true)

            foreach ($mofParameter in $mofData.Attributes) {

                if ($mofParameter.IsArray -eq $true) {
                    $t = "t"
                }
                # Check the parameter exists
                $paramToCheck = $parameters | Where-Object { $_.Name.ToString() -eq "`$$($mofParameter.Name)" }

                if ($null -eq $paramToCheck) {
                    $hasErrors = $true
                    Write-Warning "File $psFile is missing parameter $($mofParameter.Name) from the $($_.Name) method"
                }

                $parameterAttribute = $paramToCheck.Attributes | ? { $_.TypeName.ToString() -eq "parameter" } -ErrorAction SilentlyContinue

                if (($mofParameter.State -eq "Key" -or $mofParameter.State -eq "Required")) {

                    if (-not $parameterAttribute) {
                        $hasErrors = $true
                        Write-Warning "File $psFile has parameter $($mofParameter.Name) that is not marked as mandatory (has no parameter attribute) in the $($function.Name) method"
                    } else {
                        $isMandatoryInScript = [bool]::Parse(($parameterAttribute.NamedArguments | ? { $_.ArgumentName -eq "Mandatory" }).Argument.VariablePath.ToString())
                            
                        if ($isMandatoryInScript -eq $false) {
                            $hasErrors = $true
                            Write-Warning "File $psFile has parameter $($mofParameter.Name) that is not marked as mandatory in the $($function.Name) method"
                        }
                    }
                }

                if ($mofParameter.State -eq "Write") {
                    if ($null -ne $parameterAttribute) {
                        $isMandatoryInScript = [bool]::Parse(($parameterAttribute.NamedArguments | ? { $_.ArgumentName -eq "Mandatory" }).Argument.VariablePath.ToString())
                        if ($isMandatoryInScript -eq $true) {
                            $hasErrors = $true
                            Write-Warning "File $psFile has parameter $($mofParameter.Name) that is marked as mandatory in the $($function.Name) method and it should not be"
                        }
                    }
                }

                if ($null -ne $mofParameter.ValueMap) {
                    $validateSetAttribute = ($paramToCheck.Attributes | ? { $_.TypeName.ToString() -eq "ValidateSet" })

                    if (-not $validateSetAttribute) { 
                        $hasErrors = $true
                        Write-Warning "File $psFile has parameter $($mofParameter.Name) that is missing a ValidateSet attribute in the $($function.Name) method"
                    } else {
                        $psValidateSetParams = $validateSetAttribute.PositionalArguments | % { $_.Value.ToString() }

                        $mofParameter.ValueMap | ForEach-Object {
                            if ($psValidateSetParams -notcontains $_) {
                                $hasErrors = $true
                                Write-Warning "File $psFile has parameter $($mofParameter.Name) that does not have '$_' in its validateset parameter for $($function.Name) method"
                            }
                        }

                        $psValidateSetParams | ForEach-Object {
                            if ($mofParameter.ValueMap -notcontains $_) {
                                $hasErrors = $true
                                Write-Warning "File $psFile has parameter $($mofParameter.Name) that contains '$_' in the $($function.Name) function which is not in the valuemap in the schema"
                            }
                        }
                    }
                }

                if ($mofParameter.EmbeddedInstance -eq $null) {
                    if (($paramToCheck.Attributes | ? { $_.TypeName.ToString() -match $mofParameter.DataType }) -eq $null) {
                        $hasErrors = $true
                        Write-Warning "File $psFile has parameter $($mofParameter.Name) in function $($function.Name) that does not match the data type of the schema"
                    }

                    if ($mofParameter.IsArray -eq $true) {
                        if (($paramToCheck.Attributes | ? { $_.TypeName.ToString() -match $mofParameter.DataType -and $_.TypeName.IsArray -eq $true }) -eq $null) {
                            $hasErrors = $true
                            Write-Warning "File $psFile has parameter $($mofParameter.Name) in function $($function.Name) that is marked as an array in the schema but is not an array in the PowerShell module"
                        }

                    }
                } else {
                    switch ($mofParameter.EmbeddedInstance) {
                        "MSFT_Credential" {
                            if (($paramToCheck.Attributes | ? { $_.TypeName.ToString() -match "PSCredential" }) -eq $null) {
                                $hasErrors = $true
                                Write-Warning "File $psFile has parameter $($mofParameter.Name) in function $($function.Name) that does not match the data type of the schema"
                            }
                        }
                    }
                }            
            }
        }
    }

    return (!$hasErrors)
}

function Get-ParseErrors {
    param(
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$fileName
    )    

    $tokens = $null 
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($fileName, [ref] $tokens, [ref] $errors)
    return $errors
}

Export-ModuleMember *
