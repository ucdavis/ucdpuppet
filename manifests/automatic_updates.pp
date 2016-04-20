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
		/^(Debian|Ubuntu)$/: {
			package { [unattended-upgrades]: ensure => latest }
			file { "/etc/apt/apt.conf.d/20auto-upgrades":
	 	   	source => "puppet:///modules/ucdpuppet/auto-upgrade",
			}
		}
		/^(CentOS|RedHat)$/: {
			case $operatingsystemrelease {
				/^5.*/: {
					package { [yum-autoupdate]: ensure => latest }
				}
				/^6.*/: {
					package { [yum-autoupdate]: ensure => latest }
				}
				/^7.*/: { 
					package { [dnf-automatic]: ensure => latest }
				}
				default: {
					notify { "OS ${operatingsystem} release $operatingsystemrelease is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
				}
			}
		default: {
			notify { "operatingsystem=${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}



