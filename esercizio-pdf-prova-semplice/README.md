# Logica dello script

Lo script calcola l'utilizzo medio della CPU per ogni server leggendo i dati dal file `metriche.txt`.

Lo script legge `metriche.txt` riga per riga. Ogni riga contiene un nome di server e un valore di utilizzo CPU.
Ad ogni iterazione lungo il file vengono aggiornati due array associativi. 
Nel primo array, `totale_metriche_cpu`, alla chiave corrispondente al nome del server viene sommato il valore di utilizzo CPU letto sulla riga. 
Nel secondo array, `occorrenze`, alla stessa chiave viene incrementato di 1 il contatore delle righe lette per quel server.
Successivamente itero sulle chiavi dell'array `totale_metriche_cpu`. Per ogni chiave server, estraggo dai due array i relativi valori associati, la somma delle metriche e il numero di occorrenze, infine calcolo la media e stampo il risultato.
