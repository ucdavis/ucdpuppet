# This module enables security upgrades without requiring use input.
#
# This is recommended for all clients.  This is not recommended for all
# servers.
#
# The theory is that it's better for a client to be patched/most secure all 
# the time and occasionally have upgrade problems than to have security probems
# related to unpatched systems.
#

class ucdpuppet::automatic_updates
{
	case $operatingsystem {
		/^(Debian|Ubuntu|LinuxMint)$/: {
			include apt
			include unattended_upgrades
#			package { [unattended-upgrades]: ensure => latest }
#			file { "/etc/apt/apt.conf.d/20auto-upgrades":
#	 	   	source => "puppet:///modules/ucdpuppet/auto-upgrade",
#			}
		}
		/^(CentOS|RedHat)$/: {
			case $operatingsystemrelease {
				/^5.*/: {
					package { [yum-autoupdate]: ensure => latest }
				}
				/^6.*/: {
					package { [yum-cron]: ensure => latest }
					augeas { yum-cron:
						context => "/files/etc/yum/yum-cron.conf/commands",
						changes => [ "set update_cmd security","set apply_updates yes"],
					}
				}
				/^7.*/: { 
					package { [yum-cron]: ensure => latest }
					augeas { yum-cron:
						context => "/files/etc/yum/yum-cron.conf/commands",
						changes => [ "set update_cmd security","set apply_updates yes"],
					}
				}
				default: {
					notify { "OS ${operatingsystem} release $operatingsystemrelease is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
				}
			}
		}
		default: {
			notify { "operatingsystem=${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}



