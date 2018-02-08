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
diskutil list

read -p "Identify your sd card's disk. (e.g. disk5) " < /dev/tty
echo
disk=$REPLY

echo "Unmounting $disk"
diskutil unmountDisk /dev/$disk

echo "Imaging $image to $disk (don't exit. It wouldn't stop the process)"
sudo dd bs=1m if=$image of=/dev/$disk conv=sync &

while :;do
  sudo killall -INFO dd || break
  sleep 1
done

echo "Enabling SSH"
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
