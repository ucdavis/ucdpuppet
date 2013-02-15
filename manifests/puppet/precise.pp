class ucdpuppet::puppet::precise inherits ucdpuppet::puppet::params {
  package { puppet: ensure=>latest }
  service { puppet: ensure=>running, 
						subscribe => [
													File["/etc/default/puppet"],
													File["/etc/puppet/puppet.conf"],
												]
					}

	file { "/etc/default/puppet":
			source => "puppet:///modules/ucdpuppet/puppet/precise/etc_default_puppet",
			mode	 => 0644,
			owner  => root,
      group  => root,
	}

	file { "/etc/puppet/puppet.conf":
			content => template("ucdpuppet/puppet/precise/puppet.conf.erb")
	}
						
}
