
class ucdfw
{
	package { [ iptables-persistent ]: ensure => latest }
}

class ucdfw::sshonly
{
	stage { 'fw_pre':  before  => Stage['main']; }
	stage { 'fw_post': require => Stage['main']; }

	class { 'ucdfw::pre':
		stage => 'fw_pre',
	}

	class { 'ucdfw::post':
		stage => 'fw_post',
	}

	resources { "firewall":
		purge => true
	}
}
