# Resoconto tecnico per la modifica di una Virtual Disk Image

## Concetti principali

### Disk Image
Una **Disk Image** è una copia esatta del contenuto di un dispositivo di archiviazione. Contiene tutto ciò che è presente sul disco, inclusi il bootloader, la tabella delle partizioni, il sistema operativo, le applicazioni e i dati.

### Virtual Disk Image
Una **Virtual Disk Image** è una **Disk Image** contenuta in un singolo file sull'host e utilizzata come disco di una macchina virtuale. Il file è organizzato secondo un **Disk Image Format**, ad esempio **qcow2**.
Il formato **qcow2** supporta funzionalità come il thin provisioning, snapshot interni, compressione, cifratura e il meccanismo di **Backing File**.

### Disk Image Format
È la struttura secondo cui i dati del disco virtuale vengono organizzati e memorizzati dentro il file. 
Definisce come i blocchi del disco virtuale guest sono mappati sul file host e quali funzionalità sono supportate.

### Backing File
Un **Backing File** è una **Virtual Disk Image** di sola lettura che funge da base condivisa per una o più **Overlay Image**.

### Overlay Image
È l'immagine sovrapposta a un **Backing File** nel meccanismo **copy-on-write**. L'**overlay Image** parte vuota e registra solo le scritture (le differenze) rispetto al **Backing File**, che rimane di sola lettura e immutato. 
Le letture di blocchi non ancora modificati vengono servite dal **Backing File**; le scritture vengono registrate nell'**Overlay Image**. Questo permette a più VM di condividere la stessa immagine di base risparmiando spazio.

### Cloud image
Una **Cloud Image** è una variante minimale di **Virtual Disk Image**, distribuita già pronta all'uso, pensata per essere avviata come istanza in un ambiente virtualizzato o cloud. Contiene un sistema operativo essenziale, senza configurazioni specifiche dell'host, e viene tipicamente personalizzata al primo avvio tramite **Cloud-Init**. 

---

## Procedura

### 1. Installazione delle librerie

```bash
sudo apt install qemu-utils libguestfs-tools
```

- **qemu-utils**: fornisce `qemu-img`, l'utility per creare, ispezionare e convertire **Virtual Disk Image**.
- **libguestfs-tools**: fornisce le utility `virt-*` (tra cui `virt-customize`) per accedere e modificare il filesystem interno di una **Virtual Disk Image** senza dover avviare la VM.

### 2. Download della Cloud Image Ubuntu

L'immagine Ubuntu `noble-server-cloudimg-amd64.img` usata in questa procedura è una **Cloud Image** in formato **qcow2**.

```bash
curl -Lo /home/user/virtual-disk-images/ubuntu.qcow2 \
  https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

- `-L` segue gli eventuali redirect HTTP.
- `-o` specifica il path di output.

Nonostante l'estensione sia `.img`, il file è in formato **qcow2** (verificabile allo step successivo).

### 3. Ispezione dell'immagine

```bash
qemu-img info /home/user/virtual-disk-images/ubuntu.qcow2
```

Mostra le informazioni della **Virtual Disk Image**: `file format` (Disk Image Format del file), `virtual size` (capacità che il disco virtuale dichiara di avere verso il sistema guest), `disk size` (spazio realmente occupato sull'host) ed eventuale `backing file`.

### 4. Modifica dell'immagine

```bash
virt-customize -a /home/user/virtual-disk-images/ubuntu.qcow2 \
  --root-password password:admin
```

- `-a` (`--add`) indica la **Virtual Disk Image** su cui operare; il formato viene auto-rilevato.
- `--root-password password:admin` imposta la password dell'utente `root` al valore `admin`.

**Come funziona `virt-customize`:** monta il filesystem della **Virtual Disk Image** all'interno di un piccolo **appliance** (una micro-VM basata su libguestfs), esegue un `chroot` nel filesystem del guest e vi applica le operazioni richieste. È un approccio **imperativo**: ogni opzione (`--root-password`, `--run-command`, `--install`, ecc.) è un'azione eseguita in sequenza sull'immagine. Le modifiche vengono scritte direttamente nel file **qcow2**.
