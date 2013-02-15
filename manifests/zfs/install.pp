class ucdpuppet::zfs::install {
	
	if $::lsbdistid == 'Ubuntu' {
		apt::source { "zfs-native":
		  location          => "http://ppa.launchpad.net/zfs-native/stable/ubuntu",
		  release           => "$::lsbdistcodename",
		  repos             => "main",
		  key               => "F6B0FC61",
		  key_server        => "hkp://keyserver.ubuntu.com:80",
		  include_src       => false
		}
	
		# Install the ubuntu zfs package
		package { 'ubuntu-zfs':
			ensure => "latest",
			require => Apt::Source["zfs-native"],
		}
			
	}
	
}
