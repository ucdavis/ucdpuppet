
class autopatch
{
	case $operatingsystem {
		/^(Debian|Ubuntu)$/: {
			package { [unattended-upgrades]: ensure => latest }
			file { "/etc/apt/apt.conf.d/20auto-upgrades":
	 	   	source => "puppet:///modules/autopatch/auto-upgrade",
			}
		}
		default: {
			notify { "OS ${operatingsystem} is not supported, to fix go to http://github.com/ucdavis/ucdpuppet and open an issue or a pull request": }
		}
	}
}



