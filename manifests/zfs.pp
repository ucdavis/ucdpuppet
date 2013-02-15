class ucdpuppet::zfs {
	if ( ($operatingsystem != 'Ubuntu') and ($operatingsystem != 'Solaris')) {
		fail("This package only tested on Ubuntu and Solaris")
	}
	include ucdpuppet::zfs::install
}
