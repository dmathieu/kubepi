#!/bin/bash -e

if [ ! -f /tmp/raspbian/.setup ]; then
  echo "Fetching image"
  mkdir -p /tmp/raspbian

  curl -L https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip > /tmp/raspbian/image.zip
  unzip /tmp/raspbian/image.zip -d /tmp/raspbian
  touch /tmp/raspbian/.setup
fi

image=`find /tmp/raspbian/*.img`


echo "Finding SD card"
if [ "$(uname -s)" == "Darwin" ]; then
  diskutil list
else
  lsblk
fi

read -p "Identify your sd card's disk. (e.g. disk5 or mmcblk0) " < /dev/tty
echo
disk=$REPLY


if [ "$(uname -s)" == "Darwin" ]; then
  echo "Unmounting $disk"
  diskutil unmountDisk /dev/$disk
else
  shopt -s dotglob
  find /media/$USER/* -prune -type d | while IFS= read -r d; do 
    echo "Unmounting $d"
    sudo umount $d
  done
fi

echo "Imaging $image to $disk"
sudo dd bs=4M if=$image of=/dev/$disk conv=fsync

echo "Enabling SSH"
if [ "$(uname -s)" == "Darwin" ]; then
  diskutil mountDisk /dev/$disk
  while [ ! -d /Volumes/boot ]; do
    echo "Waiting for mount"
    sleep 1
  done

  touch /Volumes/boot/ssh
  orig="$(head -n1 /Volumes/boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1"
  echo $orig > /Volumes/boot/cmdline.txt

  echo "Ejecting $disk"
  sudo diskutil eject /dev/$disk
  echo "All done!"
else
  sudo mkdir -p /media/raspberry
  sudo mount /dev/${disk}p1 /media/raspberry

  sudo touch /media/raspberry/ssh
  orig="$(sudo head -n1 /media/raspberry/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1"
  echo $orig | sudo tee /media/raspberry/cmdline.txt

  echo "Ejecting $disk"
  sudo umount /media/raspberry
  sudo rm -rf /media/raspberry
  echo "All done!"
fi
