# ucdpuppet


The intent of this repo is to provide a simple Puppet and Django setup to allow users to self sign up their linux hosts to improve their security.

UCD affiliates can self sign up at https://puppet.ucdavis.edu

The puppet modules so far:  
  automatic_updates - applies security patches without user intervention  
  fwsshonly - implements a firewall for IPv4 and IPv6 that only allows ICMP and ssh incoming  
  unbound - installs unbound (and if necessary) configures NetworkManager to use it  
  sshnopassword - Disables password authentication and configures ssh client to check DNS for host keys  
  useucdpuppet - Changes the server line in puppet.conf to use puppet.ucdavis.edu  

These modules assume the following puppet forge modules are installed:  
  puppet-unattended_upgrades (v1.1.1)  
  puppetlabs-apt (v2.2.2)  
  puppetlabs-firewall (v1.8.0)  

The Django setup assumes CAS for user authentication.

