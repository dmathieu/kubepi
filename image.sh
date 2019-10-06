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
diskutil list

read -p "Identify your sd card's disk. (e.g. disk5 or mmcblk0) " < /dev/tty
echo
disk=$REPLY

echo "Unmounting $disk"
diskutil unmountDisk /dev/$disk

echo "Imaging $image to $disk"
sudo dd bs=4m if=$image of=/dev/$disk conv=sync

echo "Enabling SSH"
sleep 2
diskutil mountDisk /dev/$disk
while [ ! -d /Volumes/boot ]; do
  echo "Waiting for mount"
  sleep 1
done

touch /Volumes/boot/ssh

orig="$(sudo head -n1 /Volumes/boot/cmdline.txt) cgroup_enable=cpuset cgroup_memory=1"
echo $orig | sudo tee /Volumes/boot/cmdline.txt

echo "Ejecting $disk"
sudo diskutil eject /dev/$disk
echo "All done!"
