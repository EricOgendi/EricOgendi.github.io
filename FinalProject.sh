#!/bin/bash

# Check if the script is run with sudo
if [ "$(id -u)" != "0" ]; then
  echo "Please run this script with sudo."
  exit 1
fi

# Execute the command to check for blank passwords in /etc/shadow
result=$(sudo awk -F: '!$2 {print $1}' /etc/shadow)

# Check if there are any users with blank passwords
if [ -z "$result" ]; then
  echo "No users with blank passwords found."
else
  echo "Users with blank passwords:"
  echo "$result"
fi

# Checking for Null passwords

echo "Checking if null passwords can be used..."
grep -q "nullok" /etc/pam.d/common-password

if [ $? -eq 0 ]; then
    echo "Null passwords can be used."
    echo "Fixing the issue..."
    sudo sed -i '/nullok/d' /etc/pam.d/common-password
    echo "Null passwords disallowed now."
else
    echo "Null passwords are already disallowed."
fi

# 3:Checking if Ubuntu has rsh-server installed
echo "Verifying if rsh-server package is installed..."

if dpkg -l | grep -q "rsh-server"; then
    echo "rsh-server package is installed. Removing it..."
    sudo apt-get remove rsh-server
    echo "rsh-server package removed."
else
    echo "rsh-server package is not installed."
fi
#4####################

# Check if sudo group contains users not needing access to security functions
if grep -q "^sudo:x:[0-9]*:.*[^,]$" /etc/group; then
    echo "The sudo group contains users not needing access to security functions."
    echo "Fixing the issue..."

    # Get a list of users in the sudo group
    users_in_sudo=$(grep "^sudo:" /etc/group | cut -d ':' -f 4)

    for user in $users_in_sudo; do
        # Check if the user needs to be removed from the sudo group
        if [ "$user" != "root" ]; then
            echo "Removing user $user from the sudo group..."
            sudo gpasswd -d "$user" sudo
            echo "User $user removed from the sudo group."
        else
            echo "Skipping removal of 'root' from the sudo group."
        fi
    done
    echo "Sudo group configured with only necessary members."
else
    echo "Sudo group contains only members requiring access to security functions."
fi
##5: 

echo "Verifying if telnet package is installed..."

if dpkg -l | grep -q "telnetd"; then
    echo "Telnet package is installed. This is a finding."
    echo "Fixing the issue..."
    sudo apt-get remove telnetd
    echo "Telnet package removed."
else
    echo "Telnet package is not installed."
fi
