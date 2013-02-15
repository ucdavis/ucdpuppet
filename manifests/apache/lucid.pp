class ucdpuppet::apache::lucid {
	package { apache2: ensure=>latest }
	package { libapache2-mod-auth-kerb: ensure=>latest}
	service { apache2: ensure=>running }
}
