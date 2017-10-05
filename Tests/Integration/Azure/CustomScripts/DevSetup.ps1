$packageProviderName = "ChocolateyGet"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-PackageProvider -Name $packageProviderName
Import-PackageProvider -Name $packageProviderName

$packages = @(
    "visualstudiocode"
    "nodejs"
    "git"
    "Git-Credential-Manager-for-Windows"
    "poshgit"
)

$packages | ForEach-Object -Process {
    Install-Package -Name $_ -ProviderName $packageProviderName -Confirm:$false -Force
}
