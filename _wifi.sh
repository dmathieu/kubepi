#!/bin/bash -e

user=$1
address=$2

read -p "What is the wifi network? " -r < /dev/tty
wifi=$REPLY
read -p "What is the wifi password? " -r < /dev/tty
wifipwd=$REPLY

conf="/etc/wpa_supplicant/wpa_supplicant.conf"
ssh $user@$address << EOF
if [[ \$(sudo grep "$wifi" $conf) ]] ; then
  echo "Wifi already configured"
else
  echo "Setting up wifi network to $wifi"
  wpa_passphrase "$wifi" "$wifipwd" | sudo tee -a $conf
  sudo wpa_cli -i wlan0 reconfigure
  echo "
allow-hotplug wlan0
iface wlan0 inet manual
   wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
" | sudo tee -a /etc/network/interfaces.d/wlan0
fi
EOF
