
class ucdpuppet::ssh {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: {
			package { "openssh-server": ensure => latest}
			service { "ssh":
				ensure  => true,
				enable  => true,
				require => Package["openssh-server"]
			}
		}
		default: {
			notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
   	}
	}
}

class ucdpuppet::sshnopassword inherits ucdpuppet::ssh {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: {
			augeas { sshd_config:
				context => "/files/etc/ssh/sshd_config",
				changes => [ "set PasswordAuthentication no"],
				notify => Service[ssh]
			}
			augeas { ssh_config:
				context => "/files/etc/ssh/ssh_config",
				changes => [ "set Host[.='*']/VerifyHostKeyDNS yes"],
				notify => Service[ssh]
			}
		}
		default: {
			notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}


