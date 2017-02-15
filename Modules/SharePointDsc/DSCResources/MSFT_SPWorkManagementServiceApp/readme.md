# Description

This resource is used to provision and manage an instance of the Work
Management Services Service Application. It will identify an instance of the
work management service application through the application display name.
Currently the resource will provision the app if it does not yet exist, and
will change the application pool associated to the app if it does not match
the configuration.

Remarks

- Parameters MinimumTimeBetweenEwsSyncSubscriptionSearches,
  MinimumTimeBetweenProviderRefreshes, MinimumTimeBetweenSearchQueries are in
  minutes.
