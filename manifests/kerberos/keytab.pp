class ucdpuppet::kerberos::keytab inherits ucdpuppet::kerberos::params {

	file { $krb5_keytab_path:
  	source => "puppet:///keytabs/krb5.keytab"
  }
}
