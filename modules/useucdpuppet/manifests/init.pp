class useucdpuppet
{
	augeas { "puppet.conf":
      context => "/files/etc/puppetlabs/puppet/puppet.conf/agent",
      changes => ["set server puppet.ucdavis.edu"]
   }
}

