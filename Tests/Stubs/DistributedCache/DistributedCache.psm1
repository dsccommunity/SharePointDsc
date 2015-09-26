function Use-CacheCluster() {

}

function Get-CacheHost() {

}

function Get-AFCacheHostConfiguration() {
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]
    ${ComputerName},

    [Parameter(ParameterSetName='Default', Mandatory=$true)]
    [uint32]
    ${CachePort})
}