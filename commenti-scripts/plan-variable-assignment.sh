#!/bin/bash
# Naked variables

echo

# When is a variable "naked", i.e., lacking the '$' in front?
# When it is being assigned, rather than referenced.

# Assignment
a=879   # Declaration and inizialization of a variable
echo "The value of \"a\" is $a."  # Prints

# Assignment using 'let'
let a=16+5 # Sum of two numbers
echo "The value of \"a\" is now $a."  # Prints

echo

# In a 'for' loop (really, a type of disguised assignment):
echo -n "Values of \"a\" in the loop are: "
for a in 7 8 9 11   # For loop
do
  echo -n "$a "
done

echo
echo

# In a 'read' statement (also a type of assignment):
echo -n "Enter \"a\" "
read a
echo "The value of \"a\" is now $a."

echo

exit 0 # Positive exit code
