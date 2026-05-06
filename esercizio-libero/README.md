# Traccia
PORTSCANNER: Supponiamo di avere 2 VM sul vostro laptop che riescano a "vedersi" lato rete. Scrivere uno script Bash che si comporti come un "port scanner" per capire quali porte TCP sono in ascolto sull'altra VM. E' richiesto di farlo tramite un ciclo che invochi il comando nc (NetCat) e non usando l'apposita feature di tale comando. E' inoltre gradita la customizzazione dell'ip/host target e del range di porte da linea di comando tramite argomenti e relativa sanificazione dell'input.
## Soluzione
- Ho inizializzato vagrant nella cartella del progetto attraverso il comando vagrant init
- Ho creato il Vagrantfile e l'ho configurato specificando le caratteristiche per la creazione delle VM
- Ho avviato le due VM attraverso il comando vagrant up nome-vm
- Ho fatto l'accesso alle due VM attraverso il comando vagrant ssh nome-vm
- Ho messo la prima VM in ascolto sulla porta 80 attraverso il comando nc -l -k numero-porta
- Ho creato uno script bash sulla seconda VM che, dato un range di porte, si occupa di verificare quale porte dell'host selezionato sono aperte
- Ho eseguito lo script bash passando come parametri l'ip della prima VM e il range di porte da scansionare
