class unbound {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: { 
			package { [ unbound ]: ensure => latest }
		}
		#'RedHat', 'CentOS': { ... }
		default: {
			 notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request"}
		}
}

class unbound::networkmanager inherits unbound {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: { 
			file { "/etc/NetworkManager/NetworkManager.conf":
				source => "puppet:///modules/unbound/NetworkManager.conf"
			}
		}
		default: {
			 notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request"}
		}
	}
}
