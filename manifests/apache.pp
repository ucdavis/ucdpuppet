class ucdpuppet::apache {
	case $operatingsystem {
		Ubuntu:	{
			case $lsbdistcodename {
				lucid: { include ucdpuppet::apache::lucid }
			}
		}
	}
}
