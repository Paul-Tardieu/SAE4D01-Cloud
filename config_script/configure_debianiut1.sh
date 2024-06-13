#!/bin/bash

# Set up network interfaces and configure MTU
docker exec -it clab-srlceos400-custom_wordpress << 'EOF'
ip link set eth1 up
ip link set eth0 down

# Assign IP addresses if not already assigned
ip addr add 192.168.10.1/16 dev eth1 || true
ip a flush dev eth0
ip r flush dev eth0

# Set MTU
ip link set eth1 mtu 1500

# Set up routes
ip route add 11.202.0.0/16 dev eth1 || true
ip route add default via 192.168.10.254 dev eth1 || true

# Verify configurations
ip addr show eth1
ip route show
EOF
