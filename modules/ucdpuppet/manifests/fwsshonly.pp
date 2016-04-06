
# this module assumes you ran something like:
# puppet module install puppetlabs-firewall

class ucdpuppet::fwsshonly
{
	stage { 'fw_pre':  before  => Stage['main']; }
	stage { 'fw_post': require => Stage['main']; }

	class { 'ucdpuppet::fw_pre':
		stage => 'fw_pre',
	}

	class { 'ucdpuppet::fw_post':
		stage => 'fw_post',
	}

	resources { "firewall":
		purge => true
	}
}
