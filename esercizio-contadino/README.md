# Traccia
Creare e implementare un’architettura che rispecchi la metafora con l’indovinello relativo al Contadino, al Cavolo, alla Capra e al Lupo.

# Indovinello del Contadino
Il *Contadino* ha la necessità di portare tutti gli elementi (*Cavolo*, *Lupo* e *Capra*) da una sponda all'altra del fiume usando una barca che può ospitare solo il *Contadino* e un elemento alla volta.

**Obiettivo:** portare tutti gli elementi da una sponda all’altra

**Problema:** Il lupo mangia la capra se lasciati soli. La capra mangia il cavolo se lasciati soli.

## Tabella di validità
| Stato | Sponda A | Sponda B | Validità |
|-------|----------|----------|----------|
| 1 *(iniziale)* | Contadino, Lupo, Capra, Cavolo | — | SI |
| 2 | Contadino, Lupo, Cavolo | Capra | SI |
| 3 | Contadino, Lupo, Capra | Cavolo | SI |
| 4 | Contadino, Capra, Cavolo | Lupo | SI |
| 5 | Contadino, Capra | Lupo, Cavolo | SI |
| 6 | Lupo, Cavolo | Contadino, Capra | SI |
| 7 | Lupo | Contadino, Capra, Cavolo | SI |
| 8 | Capra | Contadino, Lupo, Cavolo | SI |
| 9 | Cavolo | Contadino, Lupo, Capra | SI |
| 10 | — | Contadino, Lupo, Capra, Cavolo | SI |
| 11 | Contadino, Lupo | Capra, Cavolo | NO |
| 12 | Contadino, Cavolo | Lupo, Capra | NO |
| 13 | Contadino | Lupo, Capra, Cavolo | NO |
| 14 | Lupo, Capra, Cavolo | Contadino | NO |
| 15 | Lupo, Capra | Contadino, Cavolo | NO |
| 16 | Capra, Cavolo | Contadino, Lupo | NO |

## Successione di stati per raggiungere la soluzione
**1 → 6 → 2 → 9 → 4 → 8 → 5 → 10**

## Metafora con l'archiettura
| Elemento | Componente |
|----------|------------|
| Contadino | Container Podman |
| Lupo | Container Podman |
| Capra | Container Podman |
| Cavolo | Container Podman |
| Fiume | Rete |
| Sponda A | Virtual Machine |
| Sponda B | Virtual Machine |
| Barca | SSH |
| Regole di controllo | Orchestrazione dei container via script bash |
| Condizioni per il constraint e per mangiare | Funzione bash di controllo che verifica le condizioni di constraint a ogni azione di spostamento |

# Passaggi per l'implementazione dell'architettura
## 1. Creazione delle due macchine virtuali con Vagrant
Ho usato Vagrant per definire e avviare le due macchine virtuali che rappresentano le due sponde del fiume:
 
- **VM1** rappresenta la *Sponda A* (la macchina su cui viene eseguito lo script ed è il punto di partenza degli elementi).
- **VM2** rappresenta la *Sponda B* (la macchina di destinazione).
Nel `Vagrantfile` ho configurato entrambe le VM e ho utilizzato la **rete privata** di Vagrant come rappresentazione del *fiume*.
 
Con `vagrant up` le due macchine vengono create e avviate.
 
## 2. Installazione di Podman sulle VM
Su entrambe le VM ho installato **Podman**. Ogni elemento dell'indovinello (Contadino, Lupo, Capra, Cavolo) è infatti un container.
 
I container vengono creati a partire dall'immagine `alpine` e mantenuti attivi con il comando `sleep infinity`.
 
## 3. Configurazione della comunicazione SSH
La *barca* dell'indovinello è realizzata tramite **SSH**. Lo spostamento di un elemento da una sponda all'altra corrisponde a eliminare il container su una VM e ricrearlo sull'altra, operazione che lo script esegue da remoto via SSH.
 
Per far funzionare il tutto senza interruzioni ho configurato:
 
- L'**autenticazione SSH tramite chiavi** da VM1 a VM2 (chiave pubblica copiata sulla VM2), così che lo script possa eseguire comandi remoti **senza che venga richiesta una password** a ogni spostamento.

## 4. Lo script bash di orchestrazione
Lo script bash si occupa dello svolgimento e dell'implementazione delle regole del gioco. In sintesi:
 
- All'avvio prepara lo stato iniziale (rimuove eventuali container preesistenti su entrambe le VM) e crea i quattro container sulla Sponda A.
- Mantiene in due array lo stato logico delle sponde (chi si trova sulla Sponda A e chi sulla Sponda B) e tiene traccia della posizione del contadino.
- A ogni mossa sposta fisicamente il container interessato (e il contadino, che deve sempre accompagnare gli spostamenti) tra le due VM, mantenendo allineati lo stato logico e quello reale dei container.
- Dopo ogni spostamento, una funzione di controllo verifica i vincoli dell'indovinello: dichiara la **sconfitta** se sulla sponda lasciata incustodita ci sono Lupo+Capra o Capra+Cavolo, e la **vittoria** quando tutti gli elementi si trovano sulla Sponda B.
 
## 5. Esecuzione dello script
Per giocare:
 
1. Avviare le due VM con `vagrant up` e accedere alla VM1 con `vagrant ssh`.
2. Copiare lo script sulla VM1 e renderlo eseguibile con `chmod +x nome-script.sh`.
3. Verificare che i parametri `IP_VM2` e `USER_VM2` corrispondano alla propria configurazione.
4. Avviare il gioco con `./nome-script.sh` e seguire il menu interattivo per spostare gli elementi tra le due sponde fino a raggiungere la vittoria.