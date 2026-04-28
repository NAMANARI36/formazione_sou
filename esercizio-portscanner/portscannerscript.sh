#!/bin/bash
# Questo scrip serve per scansionare le porte di un host specificato dall'utente
# Utilizza netcat (nc) per verificare se le porte sono aperte o chiuse

ip=$1 # L'indirizzo IP dell'host da scansionare, passato come primo argomento
port_start=$2 # La porta di inizio del range da scansionare, passata come secondo argomento
port_end=$3 # La porta di fine del range da scansionare, passata come terzo argomento


for ((port=$port_start; port<=$port_end; port++)); do
    nc -z -v $ip $port
done    