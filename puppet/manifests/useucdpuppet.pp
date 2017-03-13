# this simple module just sets puppet.ucdavis.edu as your default puppet
# master.
#
# this means you can run puppet agent -t -v and not have to add the
# server=puppet.ucdavis.edu
#
 
class ucdpuppet::useucdpuppet
{
  augeas { "puppet.conf":
    context => "/files/etc/puppetlabs/puppet/puppet.conf/agent",
    changes => ["set server puppet.ucdavis.edu"]
  }
  service { 'puppet':
    enable => true,
  }
  #CVE-2017-2636
  File { "/etc/modprobe.d/disable-n_hdlc.conf":
    source => ["puppet:///modules/cse/disable-n_hdlc.conf"],
  }
  augeas { "floppy.conf":
    context =>  "/files//etc/modprobe.d/floppy.conf",
    changes =>  ["set blacklist floppy"]
  }
  case $operatingsystem {
    /^(Debian|Ubuntu|LinuxMint)$/: {
      file { "/etc/modprobe.d/blacklist-dccp.conf":
        source => "puppet:///modules/ucdpuppet/ubuntu-dccp.conf"
      }
    }
    /^(CentOS|RedHat)$/: {
      file { "/etc/modprobe.d/blacklist-dccp.conf":
        source => "puppet:///modules/ucdpuppet/centos-dccp.conf"
      }
    }
  }
}

