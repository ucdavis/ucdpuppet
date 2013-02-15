class ucdpuppet::kerberos::install inherits ucdpuppet::kerberos::params {
	
	# install any necessary kerberos packages 
	case $operatingsystem {
		Ubuntu: {
	    package { libpam-krb5: ensure => latest }
    	package { krb5-user:   ensure => latest }
		}
		Solaris: {
			#openindiana seems to have what we need by default
		}
	}
	
}	
