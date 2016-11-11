# Description

This resource is responsible for ensuring the installation of all SharePoint
prerequisites. It makes use of the PrerequisiteInstaller.exe file that is part
of the SharePoint binaries, and will install the required Windows features as
well as additional software. The OnlineMode boolean will tell the prerequisite
installer which mode to run in, if it is online you do not need to list any
other parameters for this resource. If you do not use online mode, you must
include all other parameters to specify where the installation files are
located. These additional parameters map directly to the options passed to
prerequisiteinstaller.exe. For installations with no connectivity to Windows
Update, use the SXSpath parameter to specify the path to the SXS store of your
Windows Server install media.

Additionally, the process of installing the prerequisites on a Windows Server
usually results in 2-3 restarts of the system being required. To ensure the
DSC configuration is able to restart the server when needed, ensure the below
settings for the local configuration manager are included in your DSC file.

    LocalConfigurationManager
    {
        RebootNodeIfNeeded = $true
    }
