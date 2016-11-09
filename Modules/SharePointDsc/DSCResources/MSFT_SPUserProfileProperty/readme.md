# Description

This resource will create a property in a user profile service application. It
creates, update or delete a property using the parameters that are passed in to
it.

The parameter DisplayOrder is absolute. ie.: If you want it to be placed as the
5th field of section Bla, which has propertyName value of 5000 then your
DisplayOrder needs to be 5005. If no DisplayOrder is added then SharePoint
adds it as the last property of section X.

Length is only relevant if Field type is "String".

This Resource doesn't currently support removing existing user profile
