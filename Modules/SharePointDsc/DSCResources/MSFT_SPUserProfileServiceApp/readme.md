# Description

This resource will provision an instance of the user profile service to the
farm. It creates the required databases using the parameters that are passed
in to it (although these are only used during the initial provisioning). The
farm account is used during the provisioning of the service only (in the set
method), and the install account is used in the get and test methods. This is
done to ensure that the databases are created with the correct schema owners
and allow the user profile sync service to operate correctly.
