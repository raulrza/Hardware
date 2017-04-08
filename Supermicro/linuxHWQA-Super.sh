#!/bin/bash
# This script is intended to run a quick QA on the Supermicro hardware being tested.
# It is meant to be used to test RHEL/Debian based Operating Systems.

release=(`cat /etc/redhat-release`)
osRelease=`cat /etc/redhat-release`
vendor=`dmidecode -t baseboard | grep -i manufacturer`
motherboard=`dmidecode -t baseboard | grep -i product`
product=`dmidecode -t baseboard | grep -i product | cut -f2 -d ":"`
servicetag=`dmidecode -t baseboard | grep -i serial`
system=`dmidecode -t system | grep -i product`
version=`dmidecode -t baseboard | grep Version`
raidUtility="MegaCli64"
raidCmd="-cfgdsply -aall"

# Make sure the user running the script is root
if [[ `id -u` -ne '0' ]]; then
	echo "The script: $0 must be run as root!"
	exit 1
fi 

# Check for non RHEL flavors of linux ie Debian/Ubuntu
if [[ ! -f /etc/redhat-release ]]; then
	echo "Non RHEL-based OS detected."
	release=(`lsb_release -d | cut -f2`)
	releaseMinor=2
	osRelease="${release[0]} ${release[1]} ${release[2]}"	
fi


# Tee the output into a log file as well as std_out
# The log file name will reflect the HW and OS installed for easy identification
# Debian displays the release information slightly different, check for Debian

if [[ ${release[0]} = "Debian" ]]; then
	echo "Debian based OS detected."
	exec > >(tee /root/$product'_'${release[0]}'_'${release[2]}'_'${release[3]}.log)

else

	exec > >(tee /root/$product'_'${release[0]}'_'${release[1]}'_'${release[$releaseMinor]}.log)

fi

exec 2>&1

# Display the output to std out and log file
echo -e "OS Release: $osRelease"
echo $vendor
echo $motherboard
echo $version
echo $system
echo $servicetag
echo
echo -e "Memory Information:\n"
free -m
echo
echo -e "CPU Information:\n"
cat /proc/cpuinfo
echo
echo -e "Disk information:\n"
echo
fdisk -l
echo
echo "Raid Information:"
echo

# Run the appropriate RAID utility and commands
$raidUtility $raidCmd

# Check the network interfaces and display installed NICs
echo "Network Information:"
echo
ifconfig -a
echo
lspci | grep -i ethernet
echo

# Search dmesg for any system errors and investigate as necessary
echo "Logged Errors:"
echo "Investigate to determine whether or not these errors are critical."
echo 
echo "dmesg:"
dmesg | grep -i error
echo
exit 0