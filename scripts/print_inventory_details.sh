#!/usr/bin/bash
#############################
#
## My Inventory Creator.sh
#
#############################

MYDATE=$(date +"%Y%m%d%H%M")

MYFILE1="outputs/my-software-sources_$MYDATE.txt"
MYFILE2="outputs/my-software-details_$MYDATE.txt"

## Notify User of the Output Filenames for This Run

echo "Checking for APT and Flatpak sources"
echo "and what's installed..."
echo

echo "Your output files for this check are:"
echo "$MYFILE1"
echo "$MYFILE2"

#################################################
# Determine Software Sources and Output to File
#################################################

# APT repositories
grep -h ^deb /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null | sort > "$MYFILE1"

# Flatpak remotes
flatpak remotes 2>/dev/null | sort >> "$MYFILE1"

#################################################
# Determine Installed Software and Versions
#################################################

# Installed Debian packages
dpkg-query -W -f='${Package} ${Version}\n' | sort > "$MYFILE2"

# Installed Flatpaks
flatpak list 2>/dev/null | sort >> "$MYFILE2"

echo "Completed."