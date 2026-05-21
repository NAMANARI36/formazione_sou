# Traccia
Simulare  degli output(risposte) che i server web restituiscono al browser(tramite i codici di stato o status code 2XX,3XX,4XX e 5XX) quando noi dal lato client effettuiamo una richiesta,  che definiscono lo stato positivo o negativo della stessa. Prima dell'esercitazione con gli script, fare una relazione(README su GitHub, email, pdf etc) sulla teoria che c'è dietro il protocollo HTTP e gli HTTP status code.


## Soluzione
- Ho inizializzato vagrant nella cartella del progetto attraverso il comando vagrant init
- Ho modificato il Vagrantfile specificando le caratteristiche per la creazione della VM
- Ho avviato la VM attraverso il comando vagrant up nome-vm
- Ho fatto l'accesso alla VM attraverso il comando vagrant ssh nome-vm
- Ho configurato un Virtual Host Apache2 che utilizza il comando RedirectMatch per ritornare i diversi responde code in base alla route visitata
- Viene avviato uno script che esegue un curl su ogni route registrata per vedere i diversi response code

## Descrizione dei Response Code

Un response code è un codice numerico di tre cifre che il server web restituisce al client in risposta a ogni richiesta HTTP. Serve a comunicare l'esito della richiesta: indica se è andata a buon fine, se la risorsa è stata spostata, se non è stata trovata, oppure se si è verificato un errore lato server.

I codici sono raggruppati in cinque classi, identificate dalla prima cifra:

- **1XX – Informativi:** la richiesta è stata ricevuta e il processo continua.
- **2XX – Successo:** la richiesta è stata ricevuta e elaborata correttamente.
- **3XX – Redirezione:** sono necessarie ulteriori azioni per completare la richiesta
- **4XX – Errore del client:** la richiesta contiene un errore
- **5XX – Errore del server:** il server non è riuscito a soddisfare una richiesta apparentemente valida.

### Codici simulati in questa esercitazione

**200 – OK**
È la risposta standard per le richieste andate a buon fine. Indica che il server ha ricevuto la richiesta, l'ha elaborata correttamente ed ha restituito al client la risorsa richiesta (ad esempio una pagina web).

**301 – Moved Permanently**
Indica che la risorsa richiesta è stata spostata in modo permanente a un nuovo URL. Il server comunica al browser il nuovo indirizzo, e il client dovrebbe utilizzare quest'ultimo per tutte le richieste future.

**404 – Not Found**
Indica che il server non è riuscito a trovare la risorsa richiesta. L'URL inserito non corrisponde ad alcuna pagina o file esistente sul server.

**500 – Internal Server Error**
È un errore generico che indica un malfunzionamento interno del server, il quale non è riuscito a portare a termine la richiesta. Non fornisce dettagli specifici sulla causa.