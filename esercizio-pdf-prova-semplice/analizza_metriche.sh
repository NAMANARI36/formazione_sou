#!/usr/bin/env bash

# Dichiarazione array associativo: chiave = nome server, valore = somma dei valori CPU.
declare -A totale_metriche_cpu

# Dichiarazione array associativo chiave = nome server, valore = numero di righe lette per quel server.
declare -A occorrenze

# Lettura metriche.txt riga per riga. Ogni riga viene divisa in due variabili -> server e relativa metrica_cpu.
while read -r server metrica_cpu; do

    # Aggiunge il valore di utilizzo della cpu corrente alla somma accumulata per quel server.
    (( totale_metriche_cpu["$server"] += metrica_cpu ))

    # Incrementa di 1 il contatore di occorrenze per quel server.
    (( occorrenze["$server"] += 1 ))

# Reindirizza il file metriche.txt come input del ciclo while.
done < metriche.txt

# Stampa dell'intestazione del report.
echo "=== REPORT UTILIZZO MEDIO CPU ==="

# Itera su tutti i server dell'array delle somme.
for server in "${!totale_metriche_cpu[@]}"; do

    # Recupera la somma totale dei valori CPU per il server corrente.
    somma=${totale_metriche_cpu["$server"]}

    # Recupera il numero di occorrenze per il server corrente.
    conteggio=${occorrenze["$server"]}

    # Calcola la media
    media=$(( somma / conteggio ))

    # Stampa il nome del server e la media in percentuale.
    echo "$server: $media%"
done
