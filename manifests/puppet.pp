class ucdpuppet::puppet inherits ucdpuppet::puppet::params {
   # Fail immediately if we're not Debian or Solaris, as things probably won't work
    if ( ($operatingsystem != 'Ubuntu') and ($operatingsystem != 'Solaris') and ($operatingsystem != 'Scientific')) {
      fail('This module is only tested on Ubuntu, Openindiana, and Scientific Linux')
    }
		include ucdpuppet::puppet::install
		include ucdpuppet::puppet::config

	}
