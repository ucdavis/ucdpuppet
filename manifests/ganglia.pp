# mcast_if is optional
class ucdpuppet::ganglia (
	$clustername = 'UCDPuppet ClusterName',
	$clusterowner = 'UCDPuppet ClusterOwner',
	$clusterlatlong = '42 42 42',
	$clusterurl = 'http://lawrit.lawr.ucdavis.edu',
	$clusterlocation = 'UC Davis',
	$udp_mcast_addr = '239.2.11.71',
	$gmetad = 'false',
	$frontend = 'false',
	) {

	#Class['ucdpuppet::ganglia'] -> Class['ucdpuppet::apache'] # svn server with WebDAV requires apache

	case $operatingsystem {
		Ubuntu:	{
			case $lsbdistcodename {
				precise: { 
					class { 'ucdpuppet::ganglia::precise': 
						clustername => $clustername,
						clusterowner => $clusterowner,
						clusterlatlong => $clusterlatlong, 
						clusterurl => $clusterurl,
						clusterlocation => $clusterlocation,
						udp_mcast_addr => $udp_mcast_addr,
						gmetad => $gmetad,
						frontend => $frontend,
					}
				}
			}
		}
	}
}
