#!/bin/bash

# Configure FRR
docker exec -i clab-srlceos400-frr-routing vtysh << 'EOF'
configure terminal

hostname frr-routing
no ipv6 forwarding

interface eth1
 ip address 11.202.202.1/16
 ip ospf network point-to-point
exit

interface eth2
 ip address 192.168.10.254/16
 ip ospf passive
exit

router ospf
 network 11.202.0.0/16 area 0
 network 192.168.0.0/16 area 0
 redistribute bgp
exit

end
write memory
EOF

# Set MTU for the interfaces
docker exec -it clab-srlceos301-frr-routing ip link set eth1 mtu 1500
docker exec -it clab-srlceos301-frr-routing ip link set eth2 mtu 1500

# Restart the interfaces to apply MTU change
docker exec -it clab-srlceos301-frr-routing ip link set eth1 down
docker exec -it clab-srlceos301-frr-routing ip link set eth1 up
docker exec -it clab-srlceos301-frr-routing ip link set eth2 down
docker exec -it clab-srlceos301-frr-routing ip link set eth2 up

# Verify MTU settings
docker exec -it clab-srlceos301-frr-routing ip link show eth1 | grep mtu
docker exec -it clab-srlceos301-frr-routing ip link show eth2 | grep mtu
docker exec -it clab-srlceos301-frr-routing vtysh << 'EOF'
show ip interface brief
show ip route
show ip ospf neighbor
ip r del default
ip route add default via 11.202.202.254
EOF

docker exec -it clab-srlceos301-frr-routing bash << 'EOF'
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
EOF
