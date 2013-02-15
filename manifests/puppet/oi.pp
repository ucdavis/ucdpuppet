class ucdpuppet::puppet::oi inherits ucdpuppet::puppet::params {

	# import a SMF manifest for puppet
  service { "svc:/site/puppet:default": 
                                       ensure=>running,
																			 manifest => "/etc/puppet/puppet.xml",
						subscribe => [
													File["/etc/puppet/puppet.conf"],
												],
						require => [
													File["/etc/puppet/puppet.xml"],
												],
					}

	file { "/etc/puppet/puppet.xml":
			source => "puppet:///modules/ucdpuppet/puppet/oi/puppet.xml",
			mode	 => 0644,
			owner  => root,
      group  => root,
	}

	file { "/etc/puppet/puppet.conf":
			content => template("ucdpuppet/puppet/oi/puppet.conf.erb"),
	}

	file { "/usr/bin/puppet":
			ensure => link,
			target => "/var/ruby/1.8/gem_home/bin/puppet",
	}

	file { "/usr/bin/facter":
			ensure => link,
			target => "/var/ruby/1.8/gem_home/bin/facter",
	}

	file { "/usr/bin/hiera":
			ensure => link,
			target => "/var/ruby/1.8/gem_home/bin/hiera",
	}
						
}
