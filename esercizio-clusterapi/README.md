# Quickstart ClusterAPI (CAPI)

**CAPI** (Cluster API) è un sistema che estende un **Cluster Kubernetes** tramite **CRD** (Custom Resource Definition) e relativi **Controller**, per gestire in modo dichiarativo il ciclo di vita di altri **Cluster Kubernetes**.

**CAPI** è un'implementazione dell'**Operator Pattern** di **Kubernetes**.
L'**Operator Pattern** è un pattern che estende **Kubernetes** codificando in software la conoscenza operativa necessaria a gestire un'applicazione o un sistema, esponendola attraverso l'**API** di **Kubernetes**.
Composizione:
- Uno o più **CRD**, che definiscono lo stato desiderato in forma dichiarativa.
- Un **Controller** dedicato, che riconcilia continuamente lo stato reale verso quello dichiarato.

**CRD** è il meccanismo di estendibilità dichiarativa dell'**API Kubernetes** che permette di registrare un nuovo tipo di risorsa nell'**API Server**, definendone nome, gruppo, versioni e schema di validazione.

## Architettura

L'architettura di **CAPI** distingue due ruoli.

| Ruolo | Descrizione |
|---|---|
| **Management Cluster** | **Cluster Kubernetes** che ospita i **Provider** contenenti i **CRD** e i **Controller** di **CAPI**. È il punto di controllo da cui viene dichiarato e riconciliato il ciclo di vita dei **Workload Cluster**. |
| **Workload Cluster** | **Cluster Kubernetes** il cui ciclo di vita è gestito dal **Management Cluster**. Destinato a ospitare i carichi applicativi. |


Un **Provider** è un pacchetto di **CRD** e **Controller** che implementa uno strato di responsabilità del ciclo di vita del **Cluster** per una tecnologia specifica.



### Management Cluster

| Tipo di **Provider** | Responsabilità | |
|---|---|---|
| **Core** | Risorse indipendenti dall'infrastruttura: `Cluster`, `Machine`, `MachineSet`, `MachineDeployment`, `MachineHealthCheck` | 
| **Bootstrap** | Genera la configurazione che trasforma una macchina in un nodo Kubernetes |
| **Control Plane** | Gestisce il ciclo di vita del control plane del Workload Cluster |
| **Infrastructure** | Crea e gestisce le risorse dell'infrastruttura sottostante: rete, bilanciamento, sicurezza, calcolo |
| **Add-on** | Installa componenti aggiuntivi nel Workload Cluster | 
| **IPAM** | Assegna indirizzi IP alle macchine | 

Il **Core Provider** è unico. Per gli altri ruoli esistono implementazioni alternative: la scelta riguarda quale implementazione adottare, non se coprire il ruolo.

| Tipo di provider | Implementazioni |
|---|---|
| Bootstrap | Kubeadm (`CABPK`, default)|
| Control Plane | Kubeadm (`KCP`, default) |
| Infrastructure | Docker (`CAPD`), AWS (`CAPA`), Azure (`CAPZ`), OpenStack (`CAPO`), Proxmox |

# Task
1. Creare un ClusterAPI
2. Avviare un Workload Cluster
3. Fare il deploy di un'applicazione sul Workload Cluster








