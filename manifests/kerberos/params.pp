class ucdpuppet::kerberos::params inherits ucdpuppet::params {
	case $operatingsystem {
		Ubuntu:  { 
			$krb5_conf_path="/etc/krb5.conf"
			$krb5_keytab_path="/etc/krb5.keytab"
		}
		Solaris:  { 
			$krb5_conf_path="/etc/krb5/krb5.conf"
			$krb5_keytab_path="/etc/krb5/krb5.keytab"
		}
	}
}
