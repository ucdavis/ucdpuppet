class ucdpuppet::ganglia::precise ( $clustername,$clusterowner,$clusterlatlong,$clusterurl,$clusterlocation,$udp_mcast_addr,$gmetad,$frontend ) {
  package { ganglia-monitor: ensure=>latest }
  service { ganglia-monitor: ensure=>running, 
						subscribe => [
													File["/etc/ganglia/gmond.conf"],
												]
					}

	file { "/etc/ganglia/gmond.conf":
			content => template("ucdpuppet/ganglia/precise/gmond.conf.erb")
	}

	if $gmetad == 'True' {
		package { gmetad: ensure=>latest }
		service { gmetad: ensure=>running,
							subscribe => [
														File["/etc/ganglia/gmetad.conf"],
													]
					 }

		file { "/etc/ganglia/gmetad.conf": content => template("ucdpuppet/ganglia/precise/gmetad.conf.erb") }

	}

	if $frontend == 'True' {
 		Class['ucdpuppet::ganglia::precise'] -> Class['ucdpuppet::apache']
		package { ganglia-webfrontend: ensure=>latest }
		
		file { "/etc/apache2/sites-enabled/ganglia-webfrontend.conf": 
					ensure => link,
					target => '/etc/ganglia-webfrontend/apache.conf',
		}

	}
						
}
