class ucdpuppet::user::clc inherits ucdpuppet::user {
# this class will add users/storage tagged with atm to the system that's calling it, with appropriate details

# realize users tagged 'atmuser', set their home directory to /zeolite/$user
Ucdpuppet::User::Ucduser <| tag == 'clc' |>

# add any user zfs filesystems that should be set up on this server
Ucdpuppet::User::Zstorage <| server == $fqdn |>

# add any user directory storage that should be set up on this server
Ucdpuppet::User::Dirstorage <| server == $fqdn |>

}
