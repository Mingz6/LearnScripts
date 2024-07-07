# SetupUnraid.sh
# This script demonstrates various commands for setting up and managing users and files on an Unraid system.

# Display the current working directory
pwd

# Add a new user 'ming' with a home directory
useradd --create-home ming

# Display 'ming's user and group information
id ming
# uid=1007(ming) gid=1007(ming) groups=1007(ming),0(root),3(sys),4(adm),281(docker)

# Set a password for 'ming'
passwd ming
# Follow the prompts to enter and confirm the new password

# Display 'root's user and group information
id root
# uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),17(audio),281(docker)

# Add 'ming' to additional groups: adm, docker, sys, and root
usermod -a -G 4,281,3,0 ming

# Verify 'ming's updated group membership
id ming
# uid=1007(ming) gid=1007(ming) groups=1007(ming),0(root),3(sys),4(adm),281(docker)

# List the contents of the home directory to confirm 'ming's directory exists
ls ../home

# Switch to user 'ming'
su ming
# If permission denied when accessing /root, it's expected behavior
# Navigate to the root directory and list its contents
cd /
ls

# Attempt to access the /root directory as 'ming'
cd root
# This should fail due to permission restrictions

# Instructions for using the Vim editor
# To open or create a file with Vim, use: vim <filename>
# Save and exit in Vim: Press 'esc' then type ':wq'
# Exit without saving in Vim: Press 'esc' then type ':q!'

# Create a new file using vi (Vim)
vi test.txt
# Use Vim commands to write to and save the file

# List files to confirm 'test.txt' creation
ls

# Display the contents of 'test.txt'
cat test.txt

# The 'dead.letter' file is typically created automatically by the mail system; its contents can be viewed similarly
cat dead.letter