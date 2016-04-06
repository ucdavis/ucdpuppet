class ucdpuppet::unbound {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: { 
			package { [ unbound ]: ensure => latest }
		}
		#'RedHat', 'CentOS': { ... }
		default: {
			 notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}

class ucdpuppet::unboundnetworkmanager inherits ucdpuppet::unbound {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: { 
			file { "/etc/NetworkManager/NetworkManager.conf":
				source => "puppet:///modules/ucdpuppet/NetworkManager.conf"
			}
		}
		default: {
			 notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}
