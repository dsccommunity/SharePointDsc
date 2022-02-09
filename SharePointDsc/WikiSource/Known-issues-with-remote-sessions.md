Due to the way that SharePointDsc uses a "remote" session to the local computer to impersonate a user for PowerShell 4 support (documented at "[Remote sessions and the InstallAccount variable](Remote-sessions-and-the-InstallAccount-variable)") there are a couple of known scenarios that do not work with this approach. The known scenarios are:

## Updating SharePoint Designer settings in SPDesignerSettings

The work around to this is to remove the InstallAccount property and instead us PsDscRunAsCredential (documented in the same link as above). This approach does require PowerShell 5 to work however, so if it is not possible to install PowerShell 5 then the above scenarios will not work and can not be used.
