class ucdpuppet::svnserver::lucid {
	package { subversion: ensure => latest }
	package { libapache2-svn: ensure => latest }
}
