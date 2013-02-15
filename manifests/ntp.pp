class ucdpuppet::ntp {

				case $operatingsystem {
					Solaris: { $ntpconf = "/etc/inet/ntp.conf" }
					Ubuntu:	 { $ntpconf = "/etc/ntp.conf" }
				}

        package { ntp: ensure => latest }
        service { ntp: ensure => running,
		  		require => [ Package["ntp"], File[$ntpconf] ],
		  		subscribe => [ Package["ntp"], File[$ntpconf] ],
				}

				file { $ntpconf:
					ensure => present,
					source => "puppet:///modules/ucdpuppet/ntp/ntp.conf.$operatingsystem",
				}
}
