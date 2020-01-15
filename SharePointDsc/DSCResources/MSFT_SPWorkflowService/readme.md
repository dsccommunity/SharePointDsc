# Description

**Type:** Distributed
**Requires CredSSP:** No

This resource is used to register the SharePoint Server
against a Workflow Manager Instance.

Requirements:
Provide the url of the Workflow Manager instance to
connect to.
Scope name is optional and defaults to SharePoint.
If scope name is not specified any configured scope name is
allowed by this resource.

Remarks

Change or configuration drift for AllowOAuthHttp is not detected
by this resource.
