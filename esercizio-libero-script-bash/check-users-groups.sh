#!/bin/bash

filter_group="" # Variabile per memorizzare il gruppo da filtrare (se specificato)

while getopts ":sg:" opt; do
  case "$opt" in
    s )
      filter_group="sudo"
      ;;
    g )
      filter_group="$OPTARG"
      ;;
    \? ) # Viene eseguito quando viene passata una flag non presente nella stringa delle flag di getopts
      echo "Usage: $0 [-s] [-g group_name]" 
      exit 1
      ;;
    : ) # Viene eseguito quando non viene passato un argomento al flag che lo richiede
      echo "Error: the flag -$OPTARG requires an argument"
      echo  "Usage: $0 [-s] [-g group_name]"
      exit 1
      ;;
  esac
done

check_users_groups() {
    for user in $(compgen -u); do
        groups_output=$(groups "$user" 2>/dev/null)

        if [ -n "$filter_group" ]; then
            if echo "$groups_output" | grep -qw "$filter_group"; then
                echo "$groups_output"
            fi
        else
            echo "$groups_output"
        fi
    done
}

check_users_groups