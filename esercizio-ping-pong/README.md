# Traccia
Creare un progetto Vagrant a due nodi Linux con dentro Docker.
Solamente un nodo alla volta deve girare il container https://hub.docker.com/r/ealen/echo-server Ogni 60 secondi, il container deve migrare sul nodo "scarico". Questo significa che il container è come se facesse ping pong da un nodo all'altro.
Potete utilizzare quello che volete, soluzioni particolari con Bash, orchestratori di container, Jenkins, linguaggi vari. Lo scopo dell'attività non è puramente tecnico.

## Soluzione
- Ho inizializzato vagrant nella cartella del progetto attraverso il comando vagrant init
- Ho creato il Vagrantfile e l'ho configurato specificando le caratteristiche per la creazione delle VM
- Ho avviato le due VM attraverso il comando vagrant up nome-vm
- Ho fatto l'accesso alle due VM attraverso il comando vagrant ssh nome-vm
- Ho installato docker su tutte e due le VM con il comando sudo apt install docker.io
- Ho scaricato sulle due VM l'immagine docker richiesta con docker pull ealen/echo-server 
- Ho generato una chiave ssh su tutte e due le vm con il comando ssh-keygen -t ed25519
- Ho copiato la chiave pubblica della prima VM sulla seconda VM con ssh-copy-id user@ip-seconda-vm
- Ho copiato la chiave pubblica della seconda VM sulla prima VM con ssh-copy-id user@ip-prima-vm
- Ho creato uno script bash sulla prima VM che avvia il container docker per 60 secondi, al termine dei 60 secondi chiude il container e si connette via ssh sulla seconda VM per eseguire lo stesso script bash presente nella seconda VM
- A sua volta lo script bash presente nella seconda VM avvierà il container, aspettera 60 secondi e poi chiuderà il container e si connetterà via ssh alla prima VM per eseguire lo script precedente.
