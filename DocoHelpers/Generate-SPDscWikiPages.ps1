param
(
    [parameter(Mandatory = $false)] 
    [System.String] 
    $OutPutPath = "C:\temp"
)

$repoDir = Join-Path $PSScriptRoot "..\" -Resolve
Import-Module (Join-Path $PSScriptRoot "MofHelper.psm1")

Get-ChildItem "$repoDir\modules\SharePointDsc\**\*.schema.mof" -Recurse | `
    ForEach-Object { 
        $mofFileObject = $_
        $result = (Get-MofSchemaObject $_.FullName) | Where-Object { 
            ($_.ClassName -eq $mofFileObject.Name.Replace(".schema.mof", "")) `
                -and ($null -ne $_.FriendlyName)  
        }

        $descriptionPath = Join-Path -Path $_.DirectoryName -ChildPath "description.md"
        if (Test-Path -Path $descriptionPath)
        {
            Write-Output "Generating wiki page for $($result.FriendlyName)"
            
            $output = "**Parameters**" + [Environment]::NewLine + [Environment]::NewLine
            $output += "| Parameter | Attribute | DataType | Description | Allowed Values |" 
            $output += [Environment]::NewLine
            $output += "| --- | --- | --- | --- | --- |" + [Environment]::NewLine
            foreach ($property in $result.Attributes) 
            {
                $output += ("| **$($property.Name)** | $($property.State) | " + `
                            "$($property.DataType) | $($property.Description) | ")
                if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true) 
                {
                    $property.ValueMap | ForEach-Object {
                        $output += $_ + ", "
                    }
                    $output = $output.TrimEnd(" ")
                    $output = $output.TrimEnd(",")
                }
                $output += "|" + [Environment]::NewLine
            }


            $descriptionContent = Get-Content -Path $descriptionPath -Raw
            $output += [Environment]::NewLine + $descriptionContent + [Environment]::NewLine


            $examplesPath = ("$repoDir\modules\SharePointDsc\Examples\Resources" + `
                                    "\$($result.FriendlyName)\*.ps1")
            $exampleFiles = Get-ChildItem -Path $examplesPath

            if ($null -ne $exampleFiles)
            {
                $output += "**Examples**" + [Environment]::NewLine + [Environment]::NewLine
                $exampleCount = 1
                foreach ($exampleFile in $exampleFiles)
                {
                    $exampleContent = Get-Content -Path $exampleFile.FullName -Raw
                    $helpStart = $exampleContent.IndexOf("<#")
                    $helpEnd = $exampleContent.IndexOf("#>") + 2
                    $help = $exampleContent.Substring($helpStart, $helpEnd - $helpStart)
                    $helpOriginal = $help
                    $help = $help.Replace("    ", "")
                    $exampleContent = $exampleContent -replace $helpOriginal, $help
                    $exampleContent = $exampleContent -replace "<#"
                    $exampleContent = $exampleContent -replace "#>"
                    $exampleContent = $exampleContent.Replace(".EXAMPLE", `
                                                              "***Example $exampleCount***`n")

                    $output += $exampleContent 
                    $output += [Environment]::NewLine

                    $exampleCount ++
                }
            }
            $output | Out-File -FilePath (Join-Path $OutPutPath "$($result.FriendlyName).md") `
                               -Encoding utf8 -Force
        }
        
    }
