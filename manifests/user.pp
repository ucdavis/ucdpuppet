class ucdpuppet::user { 
	# This class sets up some complex user management based on the example hiera structure below:
	#$myusers = {
	#  'nick' => { 
	#							tag => ['userclass1','atmuser'],
	#							zstorage => { '/z1/blear' => { server => 'odinseye.lawr.ucdavis.edu',  fs => "z1/blear", quota => '100G', },
	#														'/z1/blear2' => { server => 'someotherserver.ucdavis.edu', fs => "z1/blear2", quota => '100G', },
	#													},
	#							},
	#  'dan'  => { 
	#              tag => ['userclass2'], 
	#							}
	#}
	
	# load our user list from hiera, and creates virtual resources from them.
	$hiera_users = hiera("userlist")

	define zstorage ($fs,$quota,$owner,$server) {
		zfs { "$fs":
			ensure => present,
			quota => $quota,
		}
		file { "$title":
			owner => $owner,
			recurse => 'true',
			require => Zfs["$fs"],
		}
	}
	
	define dirstorage ($owner,$server) {
		file {"$title":
			recurse => true, # create a deep path if requested
			ensure => directory,
			owner => $owner,
		}
	}
	
	
	define ucduser(
		# these are the default user class parameters 
		$homedir_prefix = '/home',		 # Homes are always created $homedir_prefix/name, user classes will override this parameter
		$shell          = '/bin/bash', # Default shell
		$group					= 'users',		 # Default group of user
		$groups					= [],     		 # Additional groups of a user
		$password				= '*',
		$managehome     = 'false',
		$comment				= 'Created by puppet',
		$tag						= [],
		$uid 						= template("ucdpuppet/user/get_campus_uidNumber.erb"), # Ask campus LDAP for UID if none is specified.
	
		# two additional areas to manage storage of a user
		$zstorage       = {},					 # ZFS filesystems assigned to the user
		$dirs           = {},          # Directories assigned to the user
		) {
		$ldap_password = hiera("campus_ldap_password")
		$owner = $title
		Ucdpuppet::User::Zstorage   { owner => $owner }
		Ucdpuppet::User::Dirstorage { owner => $owner }
	
		# Pass the user as the $title for the storage classes so we don't have to set it manually.
	
		# Add some extra storage to users based on tags.  Somewhat ugly hack.
		if member($tag,'atmuser') {
			$atm_homefs = { "/z4/home/$title" => { 'fs' => "z4/home/$title", quota => "100G", server => "metro-zeolite.ou.ad3.ucdavis.edu" } }
			create_resources('@ucdpuppet::user::zstorage',$atm_homefs)
			notice("added atmhomefs to $title")
		}
	
		# Declare the user
		user { $title:
						uid => $uid,
						home => "$homedir_prefix/$title",
						shell => $shell,
						gid => $group,
						groups => $groups,
						password => $password,
						managehome => $managehome,
						comment => $comment,
						tag => $tag,
					
		      }
	
		create_resources('@ucdpuppet::user::zstorage', $zstorage)
		create_resources('@ucdpuppet::user::dirstorage', $dirs)
		
	}
	
	create_resources("@ucdpuppet::user::ucduser",$hiera_users)
}
