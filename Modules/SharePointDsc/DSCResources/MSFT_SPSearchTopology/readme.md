# Description

This resource is responsible for provisioning a search topology in to the
current farm. It allows the configuration to dictate the search topology roles
that the current server should be running. Any combination of roles can be
specified and the topology will be upaded to reflect the current servers new
roles. If this is the first server to apply topology to a farm, then at least
one search index must be provided. To this end, the FirstPartitionIndex,
FirstPartitionDirectory and FirstPartitionServers allow configuring where the
first index partition will belong. This will behave the same as the
SPSearchIndexPartition resource.

Note that for the search topology to apply correctly, the path specified for
FirstPartitionDirectory needs to exist on the server that is executing this
resource. For example, if the below example was executed on "Server1" it would
also need to ensure that it was able to create the index path at I:\. If no
disk labeled I: was available on server1, this would fail, even though it will
not hold an actual index component.
