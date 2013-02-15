class ucdpuppet::kerberos::login inherits ucdpuppet::kerberos::params {

	# this class enables login with kerberos credentials

	case $operatingsystem {
		Ubuntu: {
		# include the config and we're done.
		}

		Solaris: {
			# solaris also requires a keytab file
			include ucdpuppet::kerberos::keytab
			
			# and changes to the pam.conf
			file { "/etc/pam.conf":
				source => "puppet:///modules/ucdpuppet/kerberos/pam.conf",
        mode    => 0644,
        owner   => root,
        group   => sys,
			}
		}
	}
}
