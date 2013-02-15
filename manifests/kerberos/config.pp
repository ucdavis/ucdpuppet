class ucdpuppet::kerberos::config inherits ucdpuppet::kerberos::params {
  file { $krb5_conf_path:
    source => "puppet:///modules/ucdpuppet/kerberos/krb5.conf"
  }
}
