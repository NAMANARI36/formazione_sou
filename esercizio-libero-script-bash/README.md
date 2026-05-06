# Traccia
Creare uno script bash a piacere
## Descrizione
Come esercizio ho scritto uno script che ritorna la lista di tutti gli utenti di sistema con i relativi gruppi di appartenenza, lo script utilizza l'utility "getopts" per gestire i flags personalizzati del comando. 
- la flag -g per filtra in base al nome del gruppo passato come argomento
- la flag -s è uno shortcut per filtrare gli utenti con gruppo sudo.
getopts è un'utility built-in che permette di gestire le flags di un comando in modo semplificato
