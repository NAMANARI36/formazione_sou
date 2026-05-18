# Cleanup
# Run as root, of course.

cd /var/log               # Changes directory to log
cat /dev/null > messages  # Overrides log file with dev/null
cat /dev/null > wtmp      # Overrides wtmp file with dev/null
echo "Log files cleaned up." # Prints
