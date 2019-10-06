#!/bin/bash -e

isWifi=0
imageURL=https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-09-30/2019-09-26-raspbian-buster-lite.zip

while (( $# > 0 ))
do
  case "$1" in
    (--wifi)
      isWifi=1
      ;;
    (*)
      ;;
  esac
  shift
done

if [ ! -f /tmp/raspbian/.setup ]; then
  echo "Fetching image"
  mkdir -p /tmp/raspbian

  curl -L $imageURL > /tmp/raspbian/image.zip
  unzip /tmp/raspbian/image.zip -d /tmp/raspbian
  touch /tmp/raspbian/.setup
fi

image=`find /tmp/raspbian/*.img`


echo "Finding SD card"
lsblk

read -p "Identify your sd card's disk. (e.g. disk5 or mmcblk0) " < /dev/tty
echo
disk=$REPLY

shopt -s dotglob
find /media/$USER/* -prune -type d | while IFS= read -r d; do 
  echo "Unmounting $d"
  sudo umount $d
done

echo "Imaging $image to $disk"
sudo dd bs=4M if=$image of=/dev/$disk conv=fsync

echo "Enabling SSH"
sudo mkdir -p /media/$USER/boot
sudo mount /dev/${disk}p1 /media/$USER/boot

sudo touch /media/$USER/boot/ssh
orig="$(sudo head -n1 /media/$USER/boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1"
echo $orig | sudo tee /media/$USER/boot/cmdline.txt

sudo mkdir -p /media/$USER/rootfs
sudo mount /dev/${disk}p2 /media/$USER/rootfs

if [[ $isWifi == 1 ]]; then
  echo "Enabling Wifi"
  if [ ! -f .config/wifi ]; then
    read -p "What is the wifi network? " -r < /dev/tty
    echo "wifi=$REPLY" > .config/wifi
    read -p "What is the wifi password? " -r < /dev/tty
    echo "wifipwd=$REPLY" >> .config/wifi
  fi
  source .config/wifi

  echo "auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
  wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" | sudo tee /media/$USER/rootfs/etc/network/interfaces.d/wlan0
  sudo chmod 666 /media/$USER/rootfs/etc/network/interfaces.d/wlan0
  wpa_passphrase "$wifi" "$wifipwd" | sudo tee /media/$USER/rootfs/etc/wpa_supplicant/wpa_supplicant.conf
  sudo chmod 666 /media/$USER/rootfs/etc/wpa_supplicant/wpa_supplicant.conf
fi

echo "Ejecting $disk"
sudo umount /media/$USER/rootfs
sudo umount /media/$USER/boot
sudo rm -rf /media/$USER
echo "All done!"
