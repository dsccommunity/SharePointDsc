#
# xSharePoint.psm1
#
function Read-SPFarm{
	$spFarm = Get-SPFarm
	$spServers = $spFarm.Servers
	
}
