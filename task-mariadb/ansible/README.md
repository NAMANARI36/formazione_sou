# MariaDB + Ansible — note di progetto

# Task
1. Creazione di un'istanza MariaDB su una VM e popolarla con dati di test
2. Esecuzione del backup del DB
3. Restore del backup su un'altra istanza dentro un'altra VM
4. Esecuzione query per verificare la consistenza dei dati
5. Orchestrare la procedura con Ansible e mettere le credenziali dell'utente DB in un Vault.
6. Studiare lo strumento AWX per eseguire playbook Ansible e integrare quanto fatto in AWX

## 0. MariaDB

**MariaDB** è un **RDBMS** (Relational Database Management System) open source, fork di
**MySQL**.

Un **Database** è una collezione strutturata di dati persistenti.

Un **RDBMS** è il software che gestisce dati organizzati secondo il **Modello relazionale**.

Nel contesto di questa task interessano cinque aspetti:

- **Storage engine**

  Componente del **RDBMS** responsabile di come i dati di una tabella vengono memorizzati e gestiti a livello fisico. 
  **MariaDB** ha un'architettura a **Storage engine pluggable**, il quale rende possibile selezionare uno **Storage engine** per tabella.
  Lo **Storage engine** di default è **InnoDB**. 
  La scelta del motore condiziona la coerenza dei **Backup fisici**.

- **Query processor**

  Insieme di componenti che ricevono i comandi **SQL** (Structured Query Language). 
  Comprende il **Parser** che esegue l'analisi sintattica; l'**Optimizer** che sceglie il piano di esecuzione a costo minore; e l'**Executor** che accede ai dati tramite lo **Storage engine**. 

- **Backup**

  Funzione servita dalla distribuzione di **MariaDB**, che permette di produrre un **Backup** dei dati presenti in un **Database**.
  - **Backup logico** — con lo strumento `mariadb-dump` offerto dalla distribuzione di **MariaDB**, è possibile generare un file di testo con dichiarazioni **SQL** che ricostruiscono schema e dati. 
  - **Backup fisico** — con lo strumento `mariadb-backup` offerto dalla distribuzione di **MariaDB**, è possibile eseguire una copia diretta dei dati a livello di **Storage engine**.


- **Restore**
 
  Funzione che prende un artefatto di backup e ne ricostruisce i dati su un'istanza del **Database**. La procedura dipende dal tipo di backup da cui si parte:
  - **Restore da backup logico** — l'artefatto è un file di istruzioni **SQL**; il restore consiste nel rieseguire quelle istruzioni sul server di destinazione.
  - **Restore da backup fisico** — l'artefatto è una copia dei datafile.

- **Privilege system**

  Meccanismo che determina quali operazioni ciascun Client può eseguire e su quali oggetti (server, database, tabella, colonna). I privilegi sono memorizzati nelle tabelle di sistema del database `mysql` e vengono assegnati con `GRANT` e revocati con `REVOKE`.


Un Client apre la connessione verso il Server attraverso tre frasi distinte:

Un **Server** è un qualsiasi dispositivo o software che fornisce risorse ad un **Client**.
Un **Client** è qualsiasi dispositivo o software che richiede risorse ad un **Server**.

Nel caso di **MariaDB** il **Server** è il demone `mariadbd`, l'unico processo che accede
ai datafile del **Database**; il **Client** è qualsiasi processo che apre una connessione
verso di esso — il client interattivo `mariadb`, `mariadb-dump`, o un modulo Ansible
tramite il driver `pymysql`. Ogni accesso ai dati passa da questa connessione: non
esiste una via che aggiri il **Server**.

Un **Client** apre la connessione verso il **Server** attraversando quattro fasi distinte:

1. **Connessione** — il client stabilisce un canale di comunicazione con il server,
   tramite **Socket**.
2. **Identificazione** — il server determina *quale* account il client dichiara di essere,
   cercando la riga corrispondente nelle tabelle di sistema.
3. **Autenticazione** — il server verifica che il client *sia* davvero quell'account,
   secondo il metodo (authentication plugin) associato all'account.
4. **Autorizzazione** — a ogni operazione successiva, il server verifica che i privilegi
   dell'account la consentano sull'oggetto richiesto.


**MariaDB** identifica i Client tramite la coppia nome + host, dove host è un pattern che descrive l'origine ammessa della connessione. Ogni account ha associato uno o più authentication plugin, che determinano il metodo con cui la sua identità viene verificata.






Le tre fasi, distinte:

**1. Connessione**

Il client crea un **socket** e chiede al kernel di connetterlo all'indirizzo su cui il demone è in ascolto. Il demone ne espone due, ciascuno con un proprio indirizzo:

| Canale | Indirizzo | Chi lo raggiunge |
|---|---|---|
| Unix domain socket | `/var/run/mysqld/mysqld.sock` | solo processi sulla stessa macchina |
| TCP | `0.0.0.0:3306` | qualsiasi host con una rotta verso la VM |

Stabilito il canale, i due processi hanno ciascuno il proprio endpoint e ci parlano sopra il **protocollo client-server di MariaDB**, un protocollo applicativo identico su entrambi i canali: il socket trasporta byte senza semantica, è il protocollo a delimitarli in messaggi e attribuirvi significato.

L'handshake procede così:

- il **server parla per primo**: manda versione, thread ID, capability flag, il nome del plugin di autenticazione di default e un **nonce** — venti byte casuali generati per questa connessione
- il **client risponde** con il nome utente, il database di default (opzionale), le proprie capability e la risposta di autenticazione

**2. Identificazione**

Dalla connessione arrivano il **nome utente dichiarato** e l'**origine**. Il server cerca in `mysql.global_priv` la riga corrispondente, ordinando per specificità dell'host e usando la prima corrispondenza. L'account è identificato dalla coppia **nome + host**, dove `host` è un pattern che descrive da dove quell'account può connettersi.

L'origine **non viene dichiarata dal client**: il server la legge dalla connessione stessa, con `getpeername()` sul socket. Su Unix domain socket è per definizione `localhost`. È questo che rende `host` una difesa reale — è un dato attestato dal kernel, non affermato dal client.

**3. Autenticazione**

Trovato l'account, il server legge il campo `plugin` di quella riga e delega a lui la verifica dell'identità. Se il plugin differisce da quello annunciato nell'handshake, il server manda un **auth switch request** e il client rifà la risposta con il metodo corretto.

- **`mysql_native_password`** — il client calcola una risposta combinando l'hash della password con il nonce ricevuto. Il server ha memorizzato l'hash e verifica. La password in chiaro non attraversa mai il canale, e il nonce rende la risposta valida solo per questa connessione: intercettarla non permette di replicarla.
- **`unix_socket`** — nessuno scambio. Il server chiede al kernel l'**UID (User IDentifier)** del processo client tramite `SO_PEERCRED`, lo risolve in un nome utente di sistema e lo confronta con quello dell'account. Funziona solo su Unix domain socket, per costruzione: su TCP il processo client sta in un altro kernel, e quel dato non esiste.

Il plugin non identifica l'account: è un **attributo** dell'account già identificato. Due account non possono differire per il solo plugin.

Esito: un **OK packet** o un **ERR packet**. Nel primo caso la connessione entra in fase di comando e il client può inviare query.

**4. Autorizzazione**

Fase distinta, che dura tutta la sessione: a ogni operazione il server verifica che i privilegi dell'account la consentano sull'oggetto richiesto.









-

## Utenti e accesso

### Utente OS ≠ utente DBMS

Sono due **namespace separati**: `root@localhost` in MariaDB e `root` sul sistema operativo non hanno alcuna relazione — due account in sistemi di autorizzazione indipendenti che si chiamano uguale per convenzione. `app_user` non esiste su Ubuntu: esiste solo nella tabella `mysql.global_priv`.

| | Utente OS | Utente MariaDB |
|---|---|---|
| Registro | `/etc/passwd`, `/etc/shadow` | tabella `mysql.global_priv` |
| Identità | nome + UID (User IDentifier) | coppia **nome + host** |
| Autenticazione | PAM (Pluggable Authentication Modules) | authentication plugin |
| Autorizza su | file, processi, syscall | database, tabelle, colonne |

Eccezione: `mysql` è un **vero utente OS** — quello sotto cui gira `mariadbd` e che possiede i file in `/var/lib/mysql`. Non è un account del DBMS.

**L'utente DBMS non tocca mai i file**: chiede al demone, e il demone li tocca — sempre con la stessa identità OS, per qualunque utente DBMS stia servendo.

### Il database `mysql`

Il database di sistema (nome storico, mai cambiato dopo il fork) contiene gli account e i privilegi:

| Tabella | Contenuto |
|---|---|
| `global_priv` | utenti, plugin di autenticazione, privilegi globali |
| `db` | privilegi a livello di database |
| `tables_priv`, `columns_priv` | privilegi a livello di tabella e colonna |
| `procs_priv` | privilegi su stored procedure e function |

Le viste `mysql.user` e `mysql.db` esistono ancora per retrocompatibilità.

```sql
SELECT User, Host, JSON_VALUE(Priv, '$.plugin') AS plugin FROM mysql.global_priv;
```

### La coppia user@host

Un account è identificato dalla **coppia**, non dal solo nome. `host` non identifica il client in modo assoluto: è un **pattern** che descrive *da dove* quell'account può connettersi.

| Valore | Significato |
|---|---|
| `localhost` | solo connessioni locali (socket Unix, o loopback) |
| `%` | wildcard: qualsiasi origine |
| `192.168.56.11` | solo da quell'IP |
| `192.168.56.%` | solo da quella subnet |

`app_user@'%'` e `app_user@'192.168.56.11'` sono **due righe distinte**, con privilegi potenzialmente diversi.

**Risoluzione**: a una connessione in arrivo possono corrispondere più righe. Il server ordina per **specificità** — l'host più specifico vince — e usa la prima corrispondenza. Fonte classica di sorprese: aggiungere un account più specifico cambia silenziosamente i privilegi effettivi di una connessione esistente.

### Authentication plugin

Il componente **modulare** che verifica l'identità di un utente al momento della connessione. Il server delega a lui la decisione se accettare o rifiutare; ogni account ne ha uno associato (colonna `plugin` di `mysql.global_priv`).

È a plugin perché il metodo di verifica non è cablato nel server: puoi sostituirlo, affiancarne più di uno allo stesso account, o aggiungerne di nuovi senza ricompilare.

| Plugin | Meccanismo |
|---|---|
| `mysql_native_password` | challenge-response su hash SHA-1 memorizzato nell'account |
| `unix_socket` | identità OS via socket Unix |
| `ed25519` | firma crittografica, più robusto di `mysql_native_password` |
| `pam` | delega a PAM → LDAP, Kerberos, quel che PAM sa fare |
| `gssapi` | Kerberos / Active Directory |

Un account può avere **più plugin contemporaneamente**: il server prova in sequenza. Impostare una password su `root@localhost` non rimuove `unix_socket` — la password diventa un'alternativa.

### `unix_socket`

Verifica l'identità tramite le credenziali del sistema operativo anziché una password: il server chiede al kernel l'UID del processo connesso, lo risolve nel nome utente di sistema, e verifica che coincida col nome dell'account MariaDB.

`root` sull'OS → si connette a `root@localhost` → i nomi coincidono → entra. Nessuna password è coinvolta nella decisione.

Funziona **solo su socket Unix, per costruzione**: su TCP il kernel non ha alcun UID da comunicare.

**Perché è il default per root (da MariaDB 10.4)**: risolve il **bootstrap**. Subito dopo l'installazione il DB dev'essere accessibile, ma non esiste ancora una password. Le alternative storiche erano peggiori — root senza password, o password generata in un file di log (approccio MySQL). `unix_socket` lega l'accesso a un'identità che l'OS già conosce e protegge: chi è root ha comunque accesso ai datafile, quindi non concedi nulla di nuovo.

Non è specifico di Ubuntu — cambia solo il **packaging**:

| | Debian/Ubuntu | RHEL/Rocky |
|---|---|---|
| Socket | `/var/run/mysqld/mysqld.sock` | `/var/lib/mysql/mysql.sock` |
| Utente di manutenzione | `debian-sys-maint` (`/etc/mysql/debian.cnf`) | — |

### Nel playbook

```yaml
login_unix_socket: "{{ mariadb_socket_path }}"
```

**Non attiva** il plugin: dice al modulo `community.mysql` di connettersi via socket anziché TCP. Funziona perché il play gira con `become: true`, quindi il modulo è eseguito come root e il plugin lo riconosce.

Da qui: `become: true` serve non per manipolare file, ma perché Ansible deve *essere* root a livello OS affinché il DBMS lo riconosca come `root@localhost`.

### Perché serve comunque un utente con password

Le operazioni **locali** (install, seed, restore) girano con `become: true` sull'host stesso → socket Unix → nessuna credenziale.

Le operazioni che **attraversano la rete** non possono: su TCP il kernel non dice al server chi sei. La verifica di consistenza deve leggere entrambe le istanze, che girano su macchine diverse → serve una password.

È l'unico segreto che viaggia, ed è la ragione per cui la credenziale nel Vault ha senso. La password di root non esiste, quindi non c'è nulla da proteggere lì.

**Minimo privilegio**: l'utente di backup richiede solo `SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER` — non `DROP`, non `INSERT`. Un utente di backup con privilegi di scrittura potrebbe distruggere ciò che dovrebbe proteggere.

| Utente | Privilegi | Usato da |
|---|---|---|
| `backup_user` | `SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER` | backup e verifica |
| `app_user` | `ALL` su `testdb` | l'applicazione (nel progetto: nessuno) |

Il **restore** richiede praticamente `ALL` (`CREATE`, `INSERT`, `DROP`, `REFERENCES`), ma gira sul target in locale → socket Unix → nessuna credenziale.

## 1. Architettura del progetto

Due VM (Virtual Machine) gestite da Vagrant, ciascuna con la propria istanza MariaDB indipendente:

| Host | Gruppo | Ruolo |
|---|---|---|
| `db-source-01` (192.168.56.10) | `db_source` | ospita i dati di test, subisce il backup |
| `db-target-01` (192.168.56.11) | `db_target` | parte vuoto, riceve il restore |

---

## 2. Inventory e gruppi

### Inventory

L'**Inventory** è insieme strutturato degli host con i relativi parametri, da cui il **Playbook** seleziona i target su cui eseguire i **Task**.

Host presenti in questo inventory:
- db-source-01
- db-target-01

### Gruppi e gerarchia

Un **Gruppo** è un insieme di host raggruppati sotto un nome comune. 
I **Gruppi** sono utili per associare un ruolo ad un insieme di host e per definire parametri dedicati al ruolo e accessibili a tutti gli host che ne fanno parte.

```yaml
all:
  children:
    db_servers:
      children:
        db_source:
          hosts:
            db-source-01:
        db_target:
          hosts:
            db-target-01:
```
 
`children` è la keyword YAML con cui l'inventory dichiara una relazione di contenimento tra gruppi
 

## 3. Play, ruoli, tag, block

### Play

Il fattore che determina il numero di play è il **cambio di `hosts`**, non il numero di ruoli: un play ha un solo target pattern.

Minimo teorico qui: 3 play. Scelta adottata: 5, uno per fase, per **osservabilità** — il nome del play compare come intestazione nell'output e in AWX diventa un blocco navigabile.

Costo: ogni play ri-raccoglie i fact. Irrilevante con due host.

### Tag

Un **tag** è un'etichetta applicabile a un task, un blocco, un ruolo o un intero play. Serve a selezionare a runtime quali task eseguire (`--tags`) o escludere (`--skip-tags`), senza modificare il playbook.

Un tag dichiarato su un play o un ruolo viene ereditato da tutti i task contenuti: il livello di dichiarazione determina l'ampiezza della propagazione, non il meccanismo, perché la selezione agisce comunque sui singoli task.

Senza `--tags`/`--skip-tags` vengono eseguiti tutti i task. `always` e `never` sono tag riservati con semantica speciale.

In AWX i tag si impostano sul Job Template (`Job Tags`).

### Block

Un **block** raggruppa più task in un'unità logica, permettendo di applicare direttive comuni (`when`, `become`, `tags`, `vars`) all'intero gruppo e di gestirne il fallimento in modo strutturato:

- `rescue:` — gira se qualcosa nel block è fallito (`ansible_failed_task`, `ansible_failed_result` disponibili)
- `always:` — gira sempre

Equivalente Ansible di `try`/`catch`/`finally`. Limiti: non supportano `loop`; il `when` viene valutato per ogni task interno, non una volta sola.

---

## 4. Variabili

### Scope

Le variabili in `defaults/` di un ruolo sono visibili **solo mentre quel ruolo è in esecuzione**. Un ruolo in un play diverso non le vede.

**Regola**: se una variabile è usata da più di un ruolo, non appartiene ai `defaults/` di nessuno di essi → `group_vars/all/vars.yml`.

Condivise nel progetto: `mariadb_socket_path`, `mariadb_service_name`, `mariadb_database_name`, `mariadb_app_user`, `mariadb_app_password`.

### `defaults/` vs `vars/`

- `defaults/` — precedenza minima, sovrascrivibile: ciò che l'utente del ruolo può cambiare
- `vars/` — precedenza alta: costanti interne che non vuoi sovrascrivibili

### Prefisso

Le variabili di un ruolo vanno prefissate col nome del ruolo (`mariadb_install_bind_address`). Le variabili hanno scope globale: senza prefisso due ruoli si sovrascrivono a vicenda silenziosamente.

### Vault

I ruoli usano una variabile "pulita" che rimanda al vault:

```yaml
mariadb_app_password: "{{ vault_mariadb_app_password }}"
```

Così cambiare la fonte del segreto (AWX credential, lookup esterno) tocca un solo file.

---

## 5. Moduli e stati

### Stati

Sono la manifestazione della natura **dichiarativa** di Ansible: dichiari lo stato in cui la risorsa deve trovarsi, non l'operazione da eseguire. Il modulo confronta stato attuale e dichiarato, agisce solo se divergono. Da qui l'idempotenza e la distinzione `ok`/`changed`.

Il valore di `state` è **specifico del modulo**, non un vocabolario globale.

Distinzione importante:

- **condizioni** (`present`, `started`, `directory`) — verificabili, quindi idempotenti
- **azioni travestite da stato** (`restarted`, `touch`, `latest`) — risultano `changed` a ogni run

`restart` sta in un handler proprio per questo: gira solo su `notify`, quindi solo quando qualcosa è davvero cambiato.

`latest` è una trappola: il risultato dipende da *quando* lo lanci, non da cosa hai scritto. Non riproducibile.

In `service`, `state` ed `enabled` sono **ortogonali**: esecuzione ora vs avvio al boot.

### Parametri di tipo lista

`apt` accetta `name` come lista e costruisce **un solo comando** con tutti i pacchetti: una transazione, una risoluzione delle dipendenze. Con un `loop` avresti N invocazioni, N lock su dpkg, N round-trip.

Regola: se il parametro è dichiarato `type: list`, passa la lista. Il `loop` serve quando devi variare più di un parametro tra le iterazioni.

### `copy` vs `template`

- `copy` — contenuto identico ovunque
- `template` — contenuto che dipende da variabili, risolte al rendering

---

## 6. apt

### `sources.list` vs indice locale

Due cose distinte:

| | Cosa | Dove | Dimensione |
|---|---|---|---|
| **Configurazione** | *dove* guardare: URL, distribuzione, componenti | `/etc/apt/sources.list`, `sources.list.d/` | poche righe |
| **Indice** | *cosa c'è*: pacchetti, versioni, dipendenze, checksum | `/var/lib/apt/lists/` | decine di MB |
| **Pacchetti** | i `.deb` scaricati | `/var/cache/apt/archives/` | — |

`apt update` legge la configurazione, contatta ogni URL, scrive il risultato nell'indice. **Non installa nulla**: scarica solo metadati.

Su Ubuntu 24.04 il default è il formato **deb822**: il contenuto reale sta in `/etc/apt/sources.list.d/ubuntu.sources`. `Signed-By` dichiara la chiave GPG per repository (nel vecchio formato la chiave era globale, quindi qualsiasi repo fidato poteva firmare qualsiasi pacchetto).

### A cosa serve `apt update`

Allinea l'indice locale allo stato attuale dei repository. Protegge da:

- `apt install` che fallisce con 404 — chiedi una versione già rimossa dal repository
- risoluzione delle dipendenze sbagliata
- `apt upgrade` cieco

Il caso del progetto è il primo: la box `bento/ubuntu-24.04` è stata costruita mesi fa, i suoi indici puntano a versioni non più servite.

### `cache_valid_time`

Aggiorna solo se l'indice è più vecchio di N secondi (guarda l'mtime di `/var/lib/apt/lists/`). Senza, `update_cache: true` scarica gli indici a ogni run.

L'aggiornamento della cache **non conta come `changed`**.

---

## 7. MariaDB — cos'è

**Fork di MySQL** nato nel 2009: Oracle acquisisce Sun (che aveva comprato MySQL AB), Monty Widenius forka la codebase e fonda MariaDB. Due discendenti dello stesso antenato, oggi divergenti.

Eredità della codebase comune, mai rinominata per compatibilità: il database di sistema si chiama `mysql`, l'utente OS è `mysql`, il socket è `mysqld.sock`, la porta è 3306, la collection è `community.mysql`, il driver è `pymysql`.

I comandi invece sono stati rinominati (`mysql` → `mariadb`, `mysqldump` → `mariadb-dump`); gli originali restano come symlink.

| | MySQL | MariaDB |
|---|---|---|
| Proprietà | Oracle | MariaDB Foundation |
| Licenza | GPL + Enterprise proprietaria | GPL |
| Root di default | password in un log | `unix_socket` |

Default su Debian/Ubuntu per la licenza interamente libera.

---

## 8. I tre pacchetti

### `mariadb-server`

Il **DBMS (Database Management System)**: il software che gestisce archiviazione, accesso concorrente e integrità dei dati. Contiene:

- **`/usr/sbin/mariadbd`** — il demone: parsa e ottimizza le query, gestisce transazioni e lock, media tra modello relazionale e file su disco, autentica le connessioni
- **gli storage engine** — InnoDB (transazionale, FK, crash recovery), Aria, MyISAM: lo strato che decide *come* i dati stanno fisicamente su disco
- **`/etc/mysql/**`** — configurazione
- **`/var/lib/mysql/`** — i datafile, inizializzati al primo avvio, inclusi `mysql` (utenti e grant) e `information_schema`
- **l'unit systemd**

È l'unico processo che tocca i datafile.

### `mariadb-client`

I programmi che si **connettono** a un'istanza: `mariadb` (client interattivo), `mariadb-dump` (su cui si regge il backup), `mariadb-admin`, `libmariadb`.

Su Debian/Ubuntu `mariadb-server` lo tira dentro come dipendenza: dichiararlo è ridondante, ma esplicito perché il backup ne dipende.

### `python3-pymysql`

Il **driver**: la libreria Python che implementa il protocollo client di MariaDB/MySQL. Equivalente di `libmariadb` per il mondo Python.

Va installato **sul managed node**, non sul control node: i moduli `community.mysql` sono script Python che Ansible copia ed esegue sul nodo remoto, ed è quel codice a chiamare `pymysql.connect()`. Conseguenza diretta dell'architettura agentless: il modulo gira dove sta la risorsa.

Senza, ogni task `mysql_*` fallisce con "PyMySQL module required" → l'installazione è il primo task.

---

## 9. Il DBMS come strato obbligato

Il DBMS media **ogni** accesso ai dati, e in quanto tale è l'unico posto dove può esistere controllo d'accesso, integrità e concorrenza.

Ma il controllo d'accesso è solo una delle ragioni per cui lo strato esiste:

- **Concorrenza** — N client scrivono insieme; il DBMS serializza con lock e MVCC (Multi-Version Concurrency Control)
- **Atomicità** — una transazione o si applica tutta o niente: redo log e crash recovery, logica che nessun filesystem offre
- **Integrità** — la FK (Foreign Key) tra `orders` e `customers` esiste perché il DBMS la fa rispettare; sui file è solo un intero
- **Astrazione** — scrivi `SELECT ... JOIN`, non "leggi la pagina 4712"

**Il controllo è completo verso la rete, parziale verso chi ha root sulla macchina**: i file in `/var/lib/mysql` hanno owner `mysql:mysql`, ma root li legge direttamente. È esattamente quello che fa `mariabackup`. Da qui: il backup fisico richiede accesso al filesystem, il dump logico solo `SELECT`.

---

## 10. Socket

Un **socket** è l'**endpoint** di un canale di comunicazione tra processi: la maniglia che il kernel dà al processo per parlare con un altro processo. Il canale sta nel kernel; il socket è ciò che il processo tiene in mano.

Le due varianti differiscono solo per **come ci si trova** — lo spazio dei nomi da cui pescano gli indirizzi:

| | Unix domain socket | Network socket (TCP) |
|---|---|---|
| Indirizzo | path sul filesystem (`/var/run/mysqld/mysqld.sock`) | IP + porta (`192.168.56.10:3306`) |
| Namespace | il filesystem | lo stack di rete |
| Chi raggiunge | solo processi locali | chiunque abbia una rotta |
| Identificazione | il kernel comunica UID/GID/PID del client | nessuna: serve una password |
| Overhead | nessuno stack di rete | incapsulamento TCP/IP |

Stessa API (`socket()`, `bind()`, `listen()`, `connect()`), stesso concetto. MariaDB parla lo stesso protocollo su entrambi senza saperlo, e fa `bind()` su entrambi: sono due socket in ascolto.

**Il file di un Unix socket non è un file condiviso**: è un punto di rendezvous. Se ci fai `cat` non leggi niente. Serve solo perché due processi hanno bisogno di un nome concordato per trovarsi, e il filesystem è il namespace che Unix aveva già. Fatto il collegamento, i byte viaggiano in memoria dentro il kernel. È l'etichetta sulla porta, non la stanza.

### `bind()`

**System call** (la libc ne è solo il wrapper: mette gli argomenti nei registri, esegue `syscall`, traduce il ritorno in `errno`). Assegna un **indirizzo** a un socket appena creato: `socket()` restituisce un endpoint anonimo, `bind()` gli attribuisce il nome nel namespace corrispondente.

Sequenza lato server:

```
socket()   → crea l'endpoint, restituisce un file descriptor
bind()     → gli assegna l'indirizzo
listen()   → lo mette in ascolto, crea la coda delle connessioni pendenti
accept()   → estrae una connessione, restituisce un fd dedicato
```

Lato client basta `socket()` + `connect()`: l'indirizzo locale lo assegna il kernel, pescando una porta effimera.

### Spazio dei nomi

Un **namespace** è l'insieme dei nomi validi in un certo contesto, con la regola che ogni nome identifica una cosa sola dentro quell'insieme. Due entità non possono avere lo stesso nome nello stesso namespace; possono averlo in namespace diversi.

Altri esempi: le collection Ansible (`community.mysql` vs `hypothetical.other`), i Linux namespace su cui si reggono i container (due processi entrambi PID 1 in namespace diversi), il DNS.

---

## 11. `bind-address`

Il valore che finisce nell'argomento di `bind()`. Risponde a: "su quale indirizzo il server si mette in ascolto".

| Valore | Ascolta su | Chi lo raggiunge |
|---|---|---|
| `127.0.0.1` (default Debian) | solo loopback | solo processi sulla VM |
| `192.168.56.10` | solo quella interfaccia | solo la rete privata |
| `0.0.0.0` | tutte le interfacce IPv4 | chiunque abbia una rotta |

**`0.0.0.0` rende il DB accessibile, non inaccessibile.** È la wildcard IPv4: dice al kernel di non filtrare per interfaccia. L'ambiguità nasce perché in altri contesti `0.0.0.0` significa "nessun indirizzo" o "rotta di default".

**Non è una regola di firewall**: decide se il pacchetto TCP arriva al server, non chi può entrare. Sono due controlli in due strati diversi:

1. il kernel decide se qualcuno risponde a quell'indirizzo → `bind-address`
2. il database decide se quel qualcuno sei tu → i grant

Le interfacce non "fanno richieste": sono passive. Chi fa la richiesta è un **processo**, e i suoi pacchetti entrano *attraverso* un'interfaccia. Con `127.0.0.1`, un pacchetto entrato da `enp0s8` viene scartato dal kernel prima di raggiungere MariaDB.

Interfacce tipiche delle VM:

```
lo        127.0.0.1        loopback
enp0s3    10.0.2.15        NAT VirtualBox — uscita verso Internet
enp0s8    192.168.56.10    host-only — rete privata tra VM e host
```

Verifica: `sudo ss -tlnp | grep 3306` → deve mostrare `0.0.0.0:3306`.

Riguarda **solo** il socket di rete: con `127.0.0.1` il socket Unix continua a funzionare.

---

## 12. Il file di configurazione

Il template genera `/etc/mysql/mariadb.conf.d/99-ansible.cnf` (il nome del sorgente `.j2` è irrilevante per MariaDB: conta dove atterra).

**Perché un file in `conf.d/` e non modificare `50-server.cnf`**: quello appartiene al pacchetto, `apt` lo sovrascrive a ogni aggiornamento. MariaDB legge i file in **ordine alfabetico** e l'ultima direttiva vince → il prefisso `99-` garantisce che il tuo prevalga.

**Perché `template` e non `copy`**: oggi non servirebbe (una sola variabile con valore fisso). Ma il valore *può* variare per host — se un giorno volessi restringere il bind-address per macchina, quei valori finirebbero in `host_vars`. Con `copy` dovresti duplicare il file.

### Le sezioni

Formato INI. Ogni sezione vale per il programma che la legge — non è arbitrario: ogni eseguibile dichiara quali sezioni gli appartengono.

- `[mysqld]`, `[mariadb]`, `[server]` → il demone
- `[client]`, `[mysql]` → il client interattivo
- `[client]`, `[mariadb-dump]` → `mariadb-dump`

Direttiva nella sezione sbagliata = ignorata, o il server non parte.

### Le direttive

```ini
[mysqld]
bind-address = 0.0.0.0
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

- **`character-set-server`** — il **character set**: la mappa tra caratteri e byte. `utf8mb4` è UTF-8 completo, fino a 4 byte per carattere (copre emoji e piani Unicode alti). Esiste per distinguerlo dal vecchio `utf8` di MySQL, che ne usava massimo 3 e non era UTF-8 valido. Il suffisso `_server` indica il default ereditato da database e tabelle create senza specifica esplicita.
- **`collation-server`** — la **collation**: le regole di confronto e ordinamento *dentro* un character set. Il charset dice come si scrive `à`, la collation dice se `à` = `a` e se viene prima o dopo `b`. `_ci` = case-insensitive. `utf8mb4_unicode_ci` segue l'algoritmo Unicode; `utf8mb4_general_ci` è più veloce e meno corretto.

**Perché contano**: charset e collation sono persistiti nei metadati di tabelle e colonne. Se le due istanze avessero default diversi e il dump non esplicitasse le clausole, avresti stesso contenuto logico e byte diversi → `CHECKSUM TABLE` divergenti.

`{{ ansible_managed }}` in cima: variabile speciale che si espande in un commento, segnalando che le modifiche manuali verranno sovrascritte.

---

## 13. Utenti

### Utente OS vs utente DBMS

**Namespace separati.** `root@localhost` in MariaDB e `root` sul sistema operativo non hanno nessuna relazione: due account in due sistemi di autorizzazione indipendenti che si chiamano uguale per convenzione. `app_user` non esiste su Ubuntu — esiste solo in `mysql.global_priv`.

| | Utente OS | Utente MariaDB |
|---|---|---|
| Registro | `/etc/passwd`, `/etc/shadow` | tabella `mysql.global_priv` |
| Identità | nome + UID | coppia **nome + host** |
| Autenticazione | PAM | authentication plugin |
| Autorizza | file, processi, syscall | database, tabelle, colonne |

Nota: `mysql` è invece un **vero utente OS** — quello sotto cui gira `mariadbd` e che possiede i file in `/var/lib/mysql`. Non è un account del DBMS.

**L'utente DBMS non tocca mai i file**: chiede al demone, e il demone li tocca — sempre con la stessa identità OS, per qualunque utente DBMS stia servendo.

### La coppia user@host

Un account è identificato dalla **coppia**, non dal solo nome. `host` non identifica il client in modo assoluto: è un **pattern** che descrive *da dove* quell'account può connettersi.

| Valore | Significato |
|---|---|
| `localhost` | solo connessioni locali |
| `%` | wildcard: qualsiasi origine |
| `192.168.56.11` | solo da quell'IP |
| `192.168.56.%` | solo da quella subnet |

`app_user@'%'` e `app_user@'192.168.56.11'` sono **due righe distinte** con privilegi potenzialmente diversi.

**Come MariaDB sceglie**: a una connessione possono corrispondere più righe; il server ordina per **specificità** (l'host più specifico vince) e usa la prima corrispondenza. Fonte classica di sorprese: aggiungi un account più specifico e cambi silenziosamente i privilegi effettivi di una connessione esistente.

```sql
SELECT User, Host, JSON_VALUE(Priv, '$.plugin') AS plugin FROM mysql.global_priv;
```

### Il database `mysql`

Nome storico, non cambiato dopo il fork. Contiene `global_priv` (utenti, plugin, privilegi globali), `db`, `tables_priv`, `columns_priv`, `procs_priv`. Le viste `mysql.user` e `mysql.db` esistono per retrocompatibilità.

---

## 14. Authentication plugin

Il componente **modulare** che MariaDB usa per verificare l'identità di un utente al momento della connessione. Il server delega a lui la decisione se accettare o rifiutare; ogni account ne ha uno associato (colonna `plugin` di `mysql.global_priv`).

È a plugin perché il metodo di verifica non è cablato nel server: puoi sostituirlo, affiancarne più di uno allo stesso account, o aggiungerne di nuovi senza ricompilare.

| Plugin | Meccanismo |
|---|---|
| `mysql_native_password` | challenge-response su hash SHA-1 memorizzato nell'account |
| `unix_socket` | identità OS via socket Unix |
| `ed25519` | firma crittografica, più robusto di `mysql_native_password` |
| `pam` | delega a PAM (Pluggable Authentication Modules) → LDAP, Kerberos |
| `gssapi` | Kerberos / Active Directory |

Un account può avere **più plugin contemporaneamente**: il server prova in sequenza. Impostare una password su `root@localhost` con `unix_socket` non rimuove il plugin — la password diventa un'alternativa.

### `unix_socket`

Verifica l'identità tramite le credenziali del sistema operativo anziché una password. Il server chiede al kernel l'**UID (User IDentifier)** del processo connesso, lo risolve nel nome utente di sistema, e verifica che coincida col nome dell'account MariaDB.

Funziona **solo su socket Unix, per costruzione**: su TCP quel dato non esiste.

**Perché è il default per root su MariaDB moderno (dalla 10.4)**: risolve il **bootstrap**. Subito dopo l'installazione il DB dev'essere accessibile, ma non esiste ancora una password. Le alternative storiche erano peggiori — root senza password, password vuota, o password generata in un file di log (approccio MySQL). `unix_socket` lega l'accesso a un'identità che l'OS già conosce e protegge: chi è root ha comunque accesso ai datafile, quindi non concedi nulla di nuovo.

Non è specifico di Ubuntu: cambia solo il **packaging**.

| | Debian/Ubuntu | RHEL/Rocky |
|---|---|---|
| Socket | `/var/run/mysqld/mysqld.sock` | `/var/lib/mysql/mysql.sock` |
| Utente di manutenzione | `debian-sys-maint` (`/etc/mysql/debian.cnf`) | — |

**Linux come identity provider?** L'analogia regge solo per `unix_socket` e solo in locale: c'è separazione tra chi verifica e chi autorizza. Ma non c'è protocollo, token né terza parte — è il kernel che risponde a una domanda su un processo locale. Copre un solo account, nessuna federazione. Il caso in cui l'analogia diventa letterale è il plugin `pam` (o `gssapi`): lì MariaDB delega davvero a un sistema di identità esterno.

### Nel playbook

```yaml
login_unix_socket: "{{ mariadb_socket_path }}"
```

**Non attiva** il plugin: dice al modulo `community.mysql` di connettersi via socket anziché TCP. Funziona perché il play gira con `become: true`, quindi il modulo è eseguito come root e il plugin lo riconosce.

Da qui: `become: true` serve non per manipolare file, ma perché Ansible deve *essere* root a livello OS affinché il DBMS lo riconosca come `root@localhost`.

**Conseguenza**: non esiste una password di root, quindi non serve nel Vault. Il Vault contiene la credenziale dell'utente applicativo — l'unico segreto che viaggia in rete.

---

## 15. A cosa serve l'utente dedicato

Alle operazioni che **attraversano la rete**. Install e seed girano in locale con `become: true` → socket Unix → nessuna password. La verifica deve leggere entrambe le istanze per confrontarle: da TCP il kernel non dice al server chi sei → serve una password.

Questa è la ragione per cui la credenziale nel Vault ha senso: è l'unico segreto che viaggia.

**Punto aperto**: `app_user` ha `ALL` su `testdb`. Per il backup servono solo `SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER` — non `DROP`, non `INSERT`. Un utente di backup con privilegi di scrittura viola il minimo privilegio.

| Utente | Privilegi | Usato da |
|---|---|---|
| `backup_user` | `SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER` | backup e verifica |
| `app_user` | `ALL` su `testdb` | l'applicazione (nel progetto: nessuno) |

Il **restore** è particolare: importare un dump richiede `CREATE`, `INSERT`, `DROP`, `REFERENCES` — praticamente `ALL`. Ma gira sul target in locale → socket Unix → nessuna credenziale.

---

## 16. Backup: logico vs fisico

| | `mariadb-dump` (logico) | `mariabackup` (fisico) |
|---|---|---|
| Artefatto | SQL testuale: istruzioni per **ricostruire** | copia byte-per-byte dei datafile InnoDB |
| Portabilità | tra versioni diverse | stessa major version |
| Velocità | lenta su DB grandi | veloce |
| Restore | import SQL, servizio attivo | stop + svuota `/var/lib/mysql` + `--copy-back` + chown + start |
| Privilegi | `SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER` | `RELOAD, PROCESS, LOCK TABLES, BINLOG MONITOR, REPLICA MONITOR` |
| Copre gli utenti | no (a meno di includere il DB `mysql`) | sì: ripristina l'intera istanza |
| Moduli Ansible | `community.mysql.mysql_db` | nessuno → `command` con `creates`/`removes` |

**Come `mariabackup` lavora a caldo**: copia i datafile mentre le scritture continuano, quindi la copia è internamente incoerente. In parallelo intercetta i redo log generati durante la copia. La fase `--prepare` li applica e porta la copia a uno stato consistente — lo stesso meccanismo del crash recovery di InnoDB.

**Scelta per il progetto**: `mariadb-dump`, per semplicità di orchestrazione.

Nota sulla verifica: con un backup fisico i `CHECKSUM TABLE` devono coincidere esattamente; col dump logico gli `AUTO_INCREMENT` possono divergere.

---

## 17. Trasferimento del dump

Due opzioni:

- **`fetch` + `copy`** — il dump passa dal **control node** (il tuo Mac). Semplice, tracciabile, funziona in AWX senza SSH tra le VM. ← scelta adottata
- **`synchronize` con `delegate_to`** — rsync diretto source→target. Più efficiente, ma richiede che `db-source-01` raggiunga `db-target-01` via SSH: chiavi da distribuire, e in AWX è una complicazione.

Terminologia: entrambe le VM sono **managed node**. Il Mac è il **control node**.

**Il trasferimento non elimina la necessità di `bind-address`**: il file viaggia via SSH senza toccare MariaDB, ma la verifica deve *leggere* entrambe le istanze, che girano su macchine diverse.

Esisterebbe un'alternativa: due task separati, ciascuno in locale via socket, che registrano i checksum; il confronto avviene sul control node tramite `hostvars`. Più pulito architetturalmente, ma svuota di senso l'esercizio sul Vault — nessuna credenziale viaggerebbe.

---

## 18. Stato attuale

- [x] Vagrantfile, inventory con gruppi, `ansible.cfg`, vault
- [x] `mariadb_install` — idempotente, verificato `changed=0`
- [x] `mariadb_seed` — schema `customers` / `orders` con FK, popolamento via stored procedure
- [ ] `mariadb_backup`
- [ ] `mariadb_restore`
- [ ] `mariadb_verify`
- [ ] AWX