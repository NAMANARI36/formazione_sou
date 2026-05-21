#! /bin/bash
# progress-bar2.sh
# Author: Graham Ewart (with reformatting by ABS Guide author).
# Used in ABS Guide with permission (thanks!).

# Invoke this script with bash. It doesn't work with sh.

# Declaring and inizializing variables
interval=1 
long_interval=10

{
     trap "exit" SIGUSR1 # Handler that executes "exit" when it receives a SIGUSR1 type signal
     sleep $interval; sleep $interval. # The process sleeps for 2 seconds
     while true
     do
       echo -n '.'     # Use dots.
       sleep $interval  
     done; } &         # Start a progress bar as a background process.

pid=$! # Saves the PID of the last process sent in background
trap "echo !; kill -USR1 $pid; wait $pid"  EXIT        # To handle ^C.

echo -n 'Long-running process '      
sleep $long_interval
echo ' Finished!'

kill -USR1 $pid        # Sends the signal to shutdown the child process 
wait $pid              # Stop the progress bar.
trap EXIT              # Removes the handler

exit $?                # Exits and use the exit code of the last command executed
