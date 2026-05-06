#!/bin/bash

filter_group="" # Variabile per memorizzare il gruppo da filtrare (se specificato)

while getopts ":sg:" opt; do # Analizza le opzioni della riga di comando
  case "$opt" in 
    s )
      filter_group="sudo" # Se il flag -s è presente, imposta il filtro per il gruppo "sudo"
      ;;
    g )
      filter_group="$OPTARG" # Imposta il gruppo da filtrare con l'argomento fornito
      ;;
    \? )
      echo "Usage: $0 [-s] [-g group_name]" # Mostra l'uso corretto dello script in caso di opzione non valida
      exit 1
      ;;
    : )
      echo "Error: the flag -$OPTARG requires an argument" # Mostra un messaggio di errore se il flag richiede un argomento ma non viene fornito
      echo "Usage: $0 [-s] [-g group_name]" # Mostra l'uso corretto dello script in caso di mancanza di argomento
      exit 1
      ;;
  esac
done

check_users_groups() { # Funzione per controllare i gruppi di ogni utente
    for user in $(compgen -u); do # Itera sulla lista di tutti gli utenti del sistema ritornata da compgen
        groups_output=$(groups "$user" 2>/dev/null) # Ottiene i gruppi dell'utente corrente, silenziando eventuali errori

        if [ -n "$filter_group" ]; then # Se è stato specificato un filtro, controlla se l'output dei gruppi contiene il gruppo filtrato
            if echo "$groups_output" | grep -qw "$filter_group"; then # Se il gruppo filtrato è presente, stampa l'output dei gruppi
                echo "$groups_output" # Stampa i gruppi dell'utente se il gruppo filtrato è presente
            fi
        else
            echo "$groups_output"
        fi
    done
}

check_users_groups