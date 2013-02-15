class ucdpuppet::svnserver () {

	Class['ucdpuppet::svnserver'] -> Class['ucdpuppet::apache'] # svn server with WebDAV requires apache

	case $operatingsystem {
		Ubuntu:	{
			case $lsbdistcodename {
				lucid: { include ucdpuppet::svnserver::lucid }
			}
		}
	}

	# this is a virtual resource to use to create automated backups, call it like this
	# @ucdpuppet::svnserver::svndump { 'lawrlinux': path => '/data', dumppath => '/dumps', rotate => '7', frequency => 'daily', }
	# the default vales for path,dumppath,rotate,frequency will be used above if you don't specify them

	define svndump ($path,$dumppath,$rotate,$frequency) 
	{	
			file { "${dumppath}/${title}.dump":
							ensure => present,
							recurse => true,
							mode => 700,
#							require => File["$dumppath"],  fix this later
			}

			file { "/etc/logrotate.d/${title}-svndump":
							content => template("ucdpuppet/svnadmin_dump.logrotate.erb"),
			}
	}

}
