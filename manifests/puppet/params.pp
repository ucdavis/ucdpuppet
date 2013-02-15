class ucdpuppet::puppet::params inherits ucdpuppet::params {
	$puppet_version = hiera("puppet_version")
	$puppetlabs_apt_repos = hiera("puppetlabs_apt_repos")
}
