class ucdpuppet::puppet::install inherits ucdpuppet::puppet::params {

# for ubuntu we define an apt::source to use the puppetlabs repositories for puppet:

	if $lsbdistid == 'Ubuntu' {
		
		apt::source { 'puppetlabs':
	        location          => "http://apt.puppetlabs.com",
	        release           => "$::lsbdistcodename",
	        repos             => $puppetlabs_apt_repos,
	        required_packages => "",
	        key               => "4BD6EC30",
	        key_server        => "hkp://keyserver.ubuntu.com:80",
	        include_src       => true
	      }
		
		package { "puppet":
			ensure => $puppet_version,
		}
	
	}
}
