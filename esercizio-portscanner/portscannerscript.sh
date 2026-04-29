#!/bin/bash
# Questo script serve per scansionare le porte di un host specificato dall'utente
# Utilizza netcat (nc) per verificare se le porte sono aperte o chiuse

ip=$1             # L'indirizzo IP dell'host da scansionare
port_start=$2     # Porta iniziale
port_end=$3       # Porta finale

ipv4_regex='^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'
port_regex='^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$'

if [[ ! $ip =~ $ipv4_regex ]]; then
    echo "Errore: indirizzo IPv4 non valido: $ip"
    exit 1
fi
if [[ ! "$port_start" =~ $port_regex ]]; then
    echo "Errore: porta iniziale non valida: $port_start"
    exit 1
fi

if [[ ! "$port_end" =~ $port_regex ]]; then
    echo "Errore: porta finale non valida: $port_end"
    exit 1
fi

if (( port_start > port_end )); then
    echo "Errore: la porta iniziale non può essere maggiore della porta finale"
    exit 1
fi

for ((port=port_start; port<=port_end; port++)); do
    nc -w 1 $ip $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Porta $port: Aperta"
    else
        echo "Porta $port: Chiusa"
    fi
done
