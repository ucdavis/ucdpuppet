
class ssh {
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
			notify { "this OS is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request"}
   	}
	}
}

class ssh::nopassword inherits ssh {
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: {
			augeas { sshd_config:
			context => "/files/etc/ssh/sshd_config",
			changes => [ "set PasswordAuthentication no",
		}
		notify => Service[ssh]
	}
	default: {
		notify { "this OS is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request"}
	}
}


