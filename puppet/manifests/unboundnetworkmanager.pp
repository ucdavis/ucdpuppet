# This module configured NetworkManager to use unbound.  
#
# This has several advantages, not limited to:
# * It's DNSSEC enabled
# * client no longer depend on the local name server which may be down or slow
# * It's generally much faster
# * Unbound is simple, fast, and written from scratch with security in mind
# * If SSHFP records are signed with DNSSEC ssh will trust them without querying
#   the user
# 
# I believe Apple, Microsoft, and Canonical are moving in this direction 
# (local validating, recursive, and caching DNS resolver).  Citation needed.
#
# recommended for all users

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
