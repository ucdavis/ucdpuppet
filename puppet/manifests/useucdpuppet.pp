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
}

