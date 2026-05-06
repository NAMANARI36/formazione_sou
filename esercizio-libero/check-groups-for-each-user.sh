#!/bin/bash

filter_group=""

while getopts ":sg:" opt; do
  case "$opt" in
    s )
      filter_group="sudo"
      ;;
    g )
      filter_group="$OPTARG"
      ;;
    \? )
      echo "Usage: $0 [-s] [-g nome_gruppo]"
      exit 1
      ;;
    : )
      echo "Errore: il flag -$OPTARG richiede un argomento"
      echo "Usage: $0 [-s] [-g nome_gruppo]"
      exit 1
      ;;
  esac
done

check_users() {
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

check_users