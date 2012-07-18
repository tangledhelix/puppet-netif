# /etc/puppet/modules/netif/manifests/init.pp
# Set up network interface configurations for Exegy systems
#
#
class netif {
#    include stdlib
    # other stuff depends on network service
    service { "network" :
        ensure => true ,
        enable => true ,
    }
    
    # add openib service if we have an ib interface
    if ($::interfaces =~ /ib/) {
        service { "openibd" :
            ensure => true ,
            enable => true ,
        }
    }
}
# interface reusable type
# default MTU is set in the individual interface defined types
define netif::interface ( $ifaddr = "", $slaves = [] , $onboot = "yes", $onparent = "yes" , $mtu = "" , $routes = undef)
{
    # switch on interface name
    case $name {
        # catch alias first since it might match other stuff
        /^.*:.*$/ : {
            netif::alias { $name :
                ifaddr => $ifaddr ,
            }
        }
        # regular ethernet interface.
        /^eth\d+$/ : {
            netif::eth { $name :
                ifaddr => $ifaddr ,
            }
        }
        # vlan ethernet interface.
        /^eth\d+\.\d+$/ : {
            netif::eth_vlan { $name :
                ifaddr => $ifaddr ,
            }
        }
        # regular ib interface.
        /^ib\d+$/ : {
            netif::ib { $name :
                ifaddr => $ifaddr ,
            }
        }
        # partitioned ib interface.
        /^ib\d+\.\d+$/ : {
            netif::ib_pkey { $name :
                ifaddr => $ifaddr ,
            }
        }
        # bridge interface
        /^br\d+$/ : { 
            netif::br { $name :
                ifaddr => $ifaddr ,
                slaves => $slaves ,
            }
        }
        # tap interface
        /^tap\d+$/ : { 
            netif::tap { $name :
                ifaddr => $ifaddr ,
            }
        }

        # default case do nothing
        default : { notify {"netif: interface type ${name} not found.":} }
    }

    # make route file
    if !empty($routes) {
        netif::route { $name :
            routes => $routes
        }
    }
}