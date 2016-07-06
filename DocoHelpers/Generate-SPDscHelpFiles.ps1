param
(
    [parameter(Mandatory = $true)] 
    [System.String] 
    $OutPutPath
)

$repoDir = Join-Path $PSScriptRoot "..\" -Resolve
Import-Module (Join-Path $PSScriptRoot "MofHelper.psm1")

Get-ChildItem -Path "$repoDir\modules\SharePointDsc\**\*.schema.mof" -Recurse | `
    ForEach-Object {
        $mofFileObject = $_ 

        $descriptionPath = Join-Path -Path $_.DirectoryName -ChildPath "readme.md"
        if (Test-Path -Path $descriptionPath)
        {
            $result = (Get-MofSchemaObject $_.FullName) | Where-Object { 
                ($_.ClassName -eq $mofFileObject.Name.Replace(".schema.mof", "")) `
                    -and ($null -ne $_.FriendlyName)  
            }
            Write-Verbose -Message "Generating help document for $($result.FriendlyName)"

            $output = ".NAME" + [Environment]::NewLine
            $output += "    $($result.FriendlyName)"
            $output += [Environment]::NewLine + [Environment]::NewLine

            $descriptionContent = Get-Content -Path $descriptionPath -Raw
            $descriptionContent = $descriptionContent.Replace("**Description**", ".DESCRIPTION")
            $descriptionContent = $descriptionContent -replace "\n", "`n    "

            $output += $descriptionContent
            $output += [Environment]::NewLine 

            foreach ($property in $result.Attributes) {
                $output += ".PARAMETER $($property.Name)" + [Environment]::NewLine
                $output += "    $($property.State) - $($property.DataType)"
                $output += [Environment]::NewLine
                
                if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true) 
                {
                    $output += "    Allowed values: "
                    $property.ValueMap | ForEach-Object {
                        $output += $_ + ", "
                    }
                    $output = $output.TrimEnd(" ")
                    $output = $output.TrimEnd(",")
                    $output +=  [Environment]::NewLine
                }
                $output += "    " + $property.Description 
                $output += [Environment]::NewLine + [Environment]::NewLine
            }

            $examplesPath = ("$repoDir\modules\SharePointDsc\Examples\Resources" + `
                                "\$($result.FriendlyName)\*.ps1")
            $exampleFiles = Get-ChildItem -Path $examplesPath

            if ($null -ne $exampleFiles)
            {
                foreach ($exampleFile in $exampleFiles)
                {
                    $exampleContent = Get-Content -Path $exampleFile.FullName -Raw
                    $exampleContent = $exampleContent -replace "<#"
                    $exampleContent = $exampleContent -replace "#>"

                    $output += $exampleContent 
                    $output += [Environment]::NewLine
                }
            }

            $outputPath = Join-Path $OutPutPath "about_$($result.FriendlyName).help.txt"
            $output | Out-File -FilePath $outputPath -Encoding utf8 -Force
        }
    }
