#!/bin/bash
# This script will update the BIOS firmware on Supermicro servers.


# Make sure the user is root
if [[ `id -u` -ne '0' ]]; then
   echo "The script: $0 must be run as root."
   echo "Run the script again as root”
   exit 1
fi

# Tee the output into a log file as well as std_out
exec > >(tee /root/supermicro_firmware_update.log)
exec 2>&1


motherboard=`dmidecode -t baseboard | grep -i product | cut -d ":" -f2 | sed s/-//`
echo "Motherboard Type is: "$motherboard”

# Create and mount a 4GB RAMDISK to store all of the updates
mkdir /mnt/ramdisk
mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk
if [[ $? -ne 0 ]]; then
   echo "There was an error creating the ramdisk, try again!"
   echo "mount -t tmpfs -o size=4G tmpfs /mnt/ramdisk"
   exit 1
else
   echo "Ramdisk created successfully, changing to /mnt/ramdisk"
   cd /mnt/ramdisk
fi

# Download Supermicro Update Manager (SUM)
wget http://raulbringas.com/shares/sum.tar.gz

if [[ $? -ne 0 ]]; then
   echo "Supermicro Update Manager was not downloaded successfully, try again!"
   echo "wget http://raulbringas.com/shares/sum.tar.gz"
   exit 1
else
   echo "Supermicro Update Manager has been downloaded successfully!"
   chmod +x sum.tar.gz
fi

# Extract the SUM utility
tar xvf sum.tar.gz


# Determine which BIOS update file to download based on motherboard type 
# Create a folder structure where the folder name is named after the motherboard type returned by dmidecode...
# Make a tarball with the md5sum of the bios update as well as the bios update

# Modify this to point to the location where the Supermicro BIOS files are stored
bios_update_file="http://raulbringas.com/shares/firmware/supermicro/bios/$motherboard.tar.gz"

# Download the motherboard BIOS firmware update
wget $bios_update_file

# Extract the motherboard BIOS
tar xvf $motherboard.tar.gz

bios_firmware=`ls | grep $motherboard`
echo "Bios Firmware Update File is: "$bios_firmware

# Apply the firmware update
./sum -c UpdateBios --file $bios_firmware --reboot 

if [[ $? -ne 0 ]]; then
   echo "BIOS update was not applied successfully, try again!"
   echo "./sum -c UpdateBios --file $bios_firmware --reboot"
   exit 1
else
   echo "Latest BIOS update has been applied successfully!"
   echo "Reboot the server and configure the Peer 1 Default BIOS settings!"
   exit 0
fi