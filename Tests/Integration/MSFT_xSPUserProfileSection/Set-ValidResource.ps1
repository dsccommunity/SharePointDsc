#
# Set_ValidResource.ps1
#
Configuration WorkManagementServiceApp
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSharePoint
    $cred = get-credential
    Node  "localhost"
    { 
        xSPUserProfileSection PersonalInformationSection
        {
            Name = "PersonalInformationSection"
            UserProfileService = "User Profile Service Application"
            DisplayName = "Personal Information"
            DisplayOrder =5000
            PsDscRunAsCredential = $cred
        }
    }
}
$ConfigData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowDomainUser = $true
                PSDscAllowPlainTextPassword = $true
            }
        )
    }
WorkManagementServiceApp -ConfigurationData $ConfigData

Remove-DscConfigurationDocument -Stage Current, Pending, Previous -Verbose
Start-DscConfiguration .\WorkManagementServiceApp -ComputerName "localhost" -Wait -Verbose