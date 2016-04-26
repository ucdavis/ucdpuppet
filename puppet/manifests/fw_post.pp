#part of ucdpuppet::fwsshonly
class ucdpuppet::fw_post {
	firewall { "999 drop all other requests":
		action => "drop",
	}
	firewall { "999 drop all other requests v6":
		action => "drop",
		provider => 'ip6tables',
	}
}

