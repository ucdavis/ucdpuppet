# This modules enables a firewall (iptables) to block all incoming connections
# except ssh.  Only other incoming traffic that is allow is ICMP (for ping
# and MTU negotiations) and incoming traffic related to outgoing traffic.
#
# recommended for all clients that only need ssh incoming.
#
# ucdpuppet::sshnopassword is strongly recommended in combination with this 
# module to prevent brute force attacks against your password
#

class ucdpuppet::fwsshonly
{
	stage { 'fw_pre':  before  => Stage['main']; }
	stage { 'fw_post': require => Stage['main']; }

	class { 'ucdpuppet::fw_pre':
		stage => 'fw_pre',
	}

	class { 'ucdpuppet::fw_post':
		stage => 'fw_post',
	}

	resources { "firewall":
		purge => true
	}
}
