#!/bin/bash
# am-i-root.sh:   Am I root or not?

ROOT_UID=0   # Root has $UID 0.

if [ "$UID" -eq "$ROOT_UID" ]  # ID Comparison to check if the user is root
then
  echo "You are root."         # Prints
else
  echo "You are just an ordinary user (but mom loves you just the same)."   # Prints
fi

exit 0 # Positive exit code

# ============================================================= #
# Code below will not execute, because the script already exited.

# An alternate method of getting to the root of matters:

ROOTUSER_NAME=root

username=`id -nu`                         # Prints the user username
if [ "$username" = "$ROOTUSER_NAME" ]     # Comparison to check if the user username is root
then
  echo "Rooty, toot, toot. You are root."  # Prints
else
  echo "You are just a regular fella."     # Prints
fi
