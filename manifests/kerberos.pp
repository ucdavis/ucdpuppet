#
# This class sets up campus kerberos servers, by default it also enables PAM login via UCD kerberos.
#
# Example, with login support:
# node "somenode.ucdavis.edu"  {
#		ucdpuppet::kerberos
# }
# Example, disable login:
# node "somewebservernode.ucdavis.edu"  {
#		ucdpuppet::kerberos( login => 'false' }
# }
# Example, with keytab.  Requires the keytab be present on the puppetmaster
# node "somewebservernode.ucdavis.edu"  {
#		ucdpuppet::kerberos( keytab => 'true' }
# }

class ucdpuppet::kerberos ($login = 'true', $keytab = 'false') inherits ucdpuppet::kerberos::params {

		# Fail immediately if we're not Debian or Solaris, as things probably won't work
		if ( ($operatingsystem != 'Ubuntu' ) and ($osfamily != 'Debian') and ($osfamily != 'Solaris') ) {
			fail('This module is only tested on Ubuntu and Openindiana')
		}
	
		# If we're on $osfamily == Solaris, then we'll need to install a keytab by default
		if  $osfamily == 'Solaris'  {
			$keytab = 'true'
		}

		include ucdpuppet::kerberos::install
		include ucdpuppet::kerberos::config
	
		if $login == 'true' {
			include ucdpuppet::kerberos::login
		}

		if $keytab == 'true' {
			include ucdpuppet::kerberos::keytab
		}
}
