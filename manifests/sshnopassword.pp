# This module turns off password authentication for ssh, this prevents
# brute force attacks from guessing your users passwords.
#
# This is recommended for all clients.
#
# To use ssh with keys instead of passwords generate a key with ssh-keygen
# and place the public key in the destinations ~/.ssh/authorized_keys
#

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
		/^(CentOS|RedHat)$/: {
			package { "openssh-server": ensure => latest}
			service { "sshd":
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
		/^(CentOS|RedHat)$/: {
			augeas { sshd_config:
            context => "/files/etc/ssh/sshd_config",
            changes => [ "set PasswordAuthentication no"],
            notify => Service[sshd]
         }
         augeas { ssh_config:
            context => "/files/etc/ssh/ssh_config",
            changes => [ "set Host[.='*']/VerifyHostKeyDNS yes"],
            notify => Service[sshd]
         }
		}
		default: {
			notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}


