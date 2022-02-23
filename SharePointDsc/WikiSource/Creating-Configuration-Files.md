PowerShell DSC allows for a single configuration file to be applied to a server to describe
what is should 'look like' - what services will run, what products are installed, and how
they are configured.
In the context of deploying a SharePoint farm this gives us a number of options for how to
go about deploying the farm with a number of different configurations based on roles, with
a number of components that are common across all deployments.

## Things every configuration is likely to have

When describing a configuration for a SharePoint Server, there are a number of common
components that are likely to exist in every configuration.
Namely the components related to the installation of the product -
_[SPInstallPreReqs](SPInstallPreReqs)_ and _[SPInstall](SPInstall)_.

It is also important to understand how the SharePointDsc resources impersonate and communicate
with the SharePoint PowerShell cmdlet's.
For PowerShell 5 (which we recommend) you should use the PsDscRunAsCredential property to specify
 the account a resource should run as.
However for PowerShell 4 this is not an option, and the InstallAccount option is to be used in
that situation, which relies on creating a local PowerShell session that uses CredSSP authentication.
This means you are likely to want to use the xCredSSP resources also (see _[Remote sessions and
the InstallAccount variable](Remote-sessions-and-the-InstallAccount-variable)_) for more information
on this).
There are also a limited number of scenario's in SharePointDsc that will always use this CredSSP
approach (such as provisioning the user profile sync service) so it is recommended that even if
you use PowerShell 5 and PsDscRunAsCredential, you should still configure the CredSSP settings.

## Creating a single server deployment

The single server deployment is the most straightforward - you will have one configuration file
that will describe all of the components that you want to have on that server.
This is not likely to be a production deployment, but more a development or testing server.
The specifics of what you put in to this configuration are largely up to what you want this server
to be running, but you will always include _[SPFarm](SPFarm)_ to create the farm, and
_[SPDistributedCacheService](SPDistributedCacheService)_ to enable the distributed cache service
in the farm.
The rest can be as little or as detailed as you need it to be in order to achieve your desired
configuration.

## Expanding the model out to multiple servers

When we begin to explore scenarios that include more than one server, the implementation of our
configuration changes significantly.
There can no longer be a single configuration that applies to all servers, you need to start
looking at what "roles" a server will fulfill within your farm.
Common roles would include "application server", or "front end server", perhaps in a large
deployment you might have a "distributed cache server" or a "search server".
The individual roles you have within your architecture will dictate the number of unique
configurations that you need to create.

For example, consider a farm that has the following architecture:

- 2x Web Front End Servers
- 2x Application Servers

This is a typical "small" SharePoint deployment, as it separates out the services to the two layers to
handle the different workloads, and still provides redundancy through having at least 2 servers in
each "role".
In this case, I would need to have two configurations, one for the front ends and one for the
application servers.
Each configuration would describe what a server in that role would look like, since I would expect
all of my front end servers to have the same services and configuration applied, and again for the
application servers.
Then if I decide I need to scale out to accommodate more load and add a new front end server, I would
just apply the same configuration to it based on its role.

## Understanding the need for a "farm server" configuration

Continuing with the above example of a small server farm, we have two configurations for each role.
There is a need for a third configuration though, and this is referred to as a "farm" configuration.
This configuration is planned to be applied to one server only (and typically this will be a back end
application server, so its configuration will be very similar to the other application server).
There are some differences though, the farm configuration will:

- Be responsible for creating the farm
- Also be responsible for provisioning and configuring logical components in the farm

It is important to understand the difference between a logical component and a physical component in
our configurations.
For example, a SharePoint web application is a logical component in a SharePoint farm - you create it
on one server, configure it from one server, but all the other servers in the farm know about it.
The physical component for a web application is the IIS website, which exists on specific servers and
can be configured per server (such as making changes to bindings).
So I would use my "farm server" configuration to provision logical components like web applications and
service applications, and my individual role configurations to validate the components that apply to a
server specifically as opposed to something that exists logically within the farm.

The other factor here is around how the DSC is going to be run from every server - if I have a SharePoint
web application that exists in a large server from (let's assume 10 servers), I don't need all 10 servers
checking for it every 30 minutes.
Even if it was just a handful of front end servers, it is still unnecessary for them all to be managing
this when it does not map directly to a physical thing that has to happen on each server.
This means that the farm server configuration will likely be much larger than any other role
configuration, but it also provides more flexibility in the implementation as all logical components are
in one spot on one server.

As an example, checkout the FarmDeployment folder in the repository. This folder contains a DSC configuration and several accompanying scripts that combined can be used to prepare and configure a SharePoint farm, in various setups. The configuration also configure other settings related to SharePoint, like disabling SSLv3. See [Instructions](Instructions) for more information.

## Examples

The module also contains an Examples directory in which several examples are available:

- Examples for each of the SharePointDsc resources
- A single server deployment, where all SharePoint components are deployed to one server
- A small farm deployment, with an application and a front end server

These examples demonstrate the concepts discussed here and can be used as as starting point for your own
configurations.
