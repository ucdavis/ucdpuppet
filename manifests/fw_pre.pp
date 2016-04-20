#part of ucdpuppet::fwsshonly
class ucdpuppet::fw_pre {
	# this allows all linux platforms to install the correct package
	# to enable firewall rules to persist across reboots
	class { 'firewall': }
	firewall { '000 accept all icmp':
		proto   => 'icmp',
		action  => 'accept',
	}
	firewall { '000 accept all v6':
		proto   => 'ipv6-icmp',
		action  => 'accept',
		provider => 'ip6tables',
	}
	firewall { '001 accept all to lo interface':
		proto   => 'all',
		iniface => 'lo',
		action  => 'accept',
	}
	firewall { '001 accept all to lo interface v6':
		proto   => 'all',
		iniface => 'lo',
		action  => 'accept',
		provider => 'ip6tables',
	}
	firewall { '002 accept related established rules':
		proto   => 'all',
		state   => ['RELATED', 'ESTABLISHED'],
		action  => 'accept',
  	}
	firewall { '002 accept related established rules v6':
		proto   => 'all',
		state   => ['RELATED', 'ESTABLISHED'],
		action  => 'accept',
		provider => 'ip6tables',
  	}
	firewall { '100 allow ssh access':
		dport   => '22',
		proto  => tcp,
		action => accept,
	}
	firewall { '100 allow ssh access v6':
		dport   => '22',
		proto  => tcp,
		action => accept,
		provider => 'ip6tables',
	}
}

	

