#!/bin/bash

# Configure CEOS
docker exec -i clab-srlceos301-ceos Cli << 'EOF'
enable
configure terminal
no aaa root

username admin privilege 15 role network-admin secret sha512 \$6\$i11PnoGHoTmynn0c\$/RCPMkyStp0xlu2RFENEqon7y26wP8N2f/uFjHquUdOvY.uu2CPwOaonyfe/Rc7/njZGLDuRB9eYZ0aAeCIwI1

transceiver qsfp default-mode 4x10G

service routing protocols model multi-agent

hostname ceos

spanning-tree mode mstp

system l1
   unsupported speed action error
   unsupported error-correction action error
exit

management api http-commands
   no shutdown
exit

management api gnmi
   transport grpc default
exit

management api netconf
   transport ssh default
exit

interface Ethernet1
   mtu 1500
   no switchport
   ip address 10.202.202.254/16
exit

interface Ethernet2
   mtu 1500
   no switchport
   ip address 11.202.202.254/16
   ip ospf network point-to-point
exit

interface Management0
   ip address 172.20.20.5/24
   ipv6 address 2001:172:20:20::5/64
exit

ip routing

ip route 0.0.0.0/0 10.202.255.254
ip route 0.0.0.0/0 172.20.20.1

ipv6 route ::/0 2001:172:20:20::1

router bgp 23
   neighbor 10.202.3.20 remote-as 22
   network 11.202.0.0/16
   redistribute ospf
exit

router ospf 1
   redistribute bgp
   network 11.202.0.0/16 area 0.0.0.0
   max-lsa 12000
exit

end
write memory
EOF

# Verify MTU settings
docker exec -i clab-srlceos301-ceos Cli << 'EOF'
enable
show interfaces Ethernet1 | include MTU
show interfaces Ethernet2 | include MTU
show ip interface brief
show ip route
show ip ospf neighbor
EOF

# Check running-config, NAT translations, and access-lists
docker exec -i clab-srlceos301-ceos Cli << 'EOF'
enable
show running-config
EOF
