#!/bin/bash -e

user=$1
address=$2
ip=10.0.0.1


interfaces="/etc/network/interfaces.d/eth0"
ssh $user@$address << EOF
if [[ \$(sudo grep "$ip" $interfaces) ]] ; then
  echo "Static ip configured"
else
  echo "Setting up static eth0 Ip"
  echo "
iface eth0 inet static
  address 10.0.0.1
  netmask 255.255.255.0
  broadcast 10.0.0.255
  gateway 10.0.0.1
" | sudo tee -a $interfaces

echo "
interface eth0
static ip_address=10.0.0.1
" | sudo tee -a /etc/dhcpcd.conf
fi
EOF

dhcpConf="/etc/dhcp/dhcpd.conf"
ssh $user@$address << EOF
if [[ \$(sudo grep "$ip" $dhcpConf) ]] ; then
  echo "DHCP configured"
else
  echo "Configuring DHCP"
  sudo apt-get install -y isc-dhcp-server

  echo "
option domain-name \"pi.home\";
option domain-name-servers 8.8.8.8, 8.8.4.4;

subnet 10.0.0.0 netmask 255.255.255.0 {
  range 10.0.0.1 10.0.0.42;
  option subnet-mask 255.255.255.0;
  option broadcast-address 10.0.0.255;
  option routers 10.0.0.1;
}
default-lease-time 600;
max-lease-time 7200;
authoritative;
" | sudo tee -a $dhcpConf

  sudo service isc-dhcp-server restart
  systemctl status isc-dhcp-server.service
  exit 0
fi
EOF

rcConf="/etc/rc.local"
ssh $user@$address << EOF
if [[ \$(sudo grep "POSTROUTING" $rcConf) ]] ; then
  echo "lan to wifi forwarding configured"
else
  echo "Setting up lan to wifi forwarding"
  echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

  echo '#!/bin/sh
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
' | sudo tee $rcConf
sudo chmod +x $rcConf
sudo systemctl daemon-reload
fi
EOF
