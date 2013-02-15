class ucdpuppet::puppet::config inherits ucdpuppet::puppet::params {
	# this class handles configuration for the various OSes
	if $osfamily == 'Solaris' {
		# import a SMF manifest for puppet
	  service { "svc:/site/puppet:default": 
	            ensure=>running,
						 manifest => "/etc/puppet/puppet.xml",
							subscribe => [ File["/etc/puppet/puppet.conf"], ],
							require => [ File["/etc/puppet/puppet.xml"], ],
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

	if $lsbdistid == 'Ubuntu' {
	  service { puppet: ensure=>running,
	            subscribe => [File["/etc/default/puppet"], File["/etc/puppet/puppet.conf"], ]
	          }
	
	  file { "/etc/default/puppet":
	      source => "puppet:///modules/ucdpuppet/puppet/$lsbdistcodename/etc_default_puppet",
	      mode   => 0644,
	      owner  => root,
	      group  => root,
	  }
	
	  file { "/etc/puppet/puppet.conf":
	      content => template("ucdpuppet/puppet/$lsbdistcodename/puppet.conf.erb")
	  }
	}

	if $lsbdistid == 'ScientificSL' {
		service { puppet: 
							ensure => running,
						  enable => 'true',
							subscribe => [File["/etc/puppet/puppet.conf"]],
						}

	  file { "/etc/puppet/puppet.conf":
	      content => template("ucdpuppet/puppet/$lsbdistcodename/puppet.conf.erb")
	  }
	}

}
