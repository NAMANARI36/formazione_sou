# Cluster API — Management Cluster, Workload Cluster e deploy applicativo

Percorso completo per inizializzare un management cluster con **CAPI** (Cluster API),
provisionare un **workload cluster** e installarci sopra un'applicazione.

## Nota sulla terminologia

La traccia originale usa termini che non corrispondono alla nomenclatura upstream del progetto.
Mappatura adottata in questo documento:

| Traccia | Termine standard | Motivo |
|---|---|---|
| "Creare un ClusterAPI" | Bootstrap del **management cluster** + `clusterctl init` | CAPI non è un oggetto che si "crea": è un set di controller e **CRD** (Custom Resource Definition) che si installano *su* un cluster esistente, trasformandolo in management cluster |
| "Worker Cluster" | **Workload cluster** | In CAPI *worker* qualifica un ruolo di **nodo**, non di cluster. Il cluster gestito dal management cluster si chiama workload cluster |

## Architettura

```
┌─────────────────────────────────────────────┐
│ MANAGEMENT CLUSTER                          │
│                                             │
│  ├── cert-manager                           │
│  ├── CAPI core controller                   │
│  ├── CABPK  (bootstrap provider, kubeadm)   │
│  ├── KCP    (control plane provider)        │
│  └── CAPD   (infrastructure provider)       │
│                                             │
│  Custom Resource: Cluster, MachineDeployment │
└───────────────────┬─────────────────────────┘
                    │ reconciliation loop
                    ▼
┌─────────────────────────────────────────────┐
│ WORKLOAD CLUSTER                            │
│  control plane node(s) + worker node(s)     │
│  + CNI + applicazione                       │
└─────────────────────────────────────────────┘
```

Il management cluster non ospita i workload applicativi: ospita i controller che
riconciliano lo stato desiderato dei workload cluster verso l'infrastruttura reale.

## Componenti

| Acronimo | Nome esteso | Ruolo |
|---|---|---|
| **CAPI** | Cluster API | Progetto SIG (Special Interest Group) Cluster Lifecycle: API dichiarative per il lifecycle dei cluster |
| **CAPD** | Cluster API Provider Docker | Infrastructure provider di riferimento: provisiona i nodi come container sull'host |
| **CABPK** | Cluster API Bootstrap Provider Kubeadm | Genera la configurazione kubeadm che inizializza ogni nodo |
| **KCP** | Kubeadm Control Plane provider | Gestisce il ciclo di vita delle macchine di control plane |
| **CNI** | Container Network Interface | Plugin di rete pod-to-pod; senza, i nodi restano `NotReady` |
| **CRD** | Custom Resource Definition | Estensione dell'API server con i tipi CAPI (`Cluster`, `Machine`, …) |

## Prerequisiti

| Componente | Versione | Note |
|---|---|---|
| kind | ≥ v0.32.0 | Versione minima richiesta da CAPI v1.13 |
| kubectl | ≥ v1.32 | |
| clusterctl | v1.13.4 | CLI per il lifecycle del management cluster |
| Helm | ≥ v3 | Per l'installazione dell'applicazione |
| Memoria disponibile | ≥ 6 GB | Requisito CAPD |

> **CAPD non è destinato alla produzione.** È l'infrastructure provider di
> riferimento, pensato per sviluppo e test: i "nodi" sono container sull'host,
> senza isolamento reale né alta disponibilità.

### Installazione di clusterctl

```bash
# Linux AMD64 — per ARM64 sostituire con clusterctl-linux-arm64
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.4/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
clusterctl version
```

---

## Step 1 — Management cluster

### 1.1 Configurazione kind

CAPD provisiona i nodi del workload cluster come container sull'host, quindi i suoi
controller devono raggiungere il socket del container runtime. Va montato dentro il
management cluster tramite `extraMounts`.

```bash
cat > kind-cluster-with-extramounts.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
EOF

kind create cluster --config kind-cluster-with-extramounts.yaml
kubectl cluster-info
```

> `hostPath` va allineato al socket effettivo del runtime in uso sull'host.

### 1.2 Inizializzazione di Cluster API

```bash
# ClusterTopology abilita ClusterClass, richiesto dai template CAPD
export CLUSTER_TOPOLOGY=true

clusterctl init --infrastructure docker
```

`clusterctl init` installa cert-manager, il core provider, e — se non specificati —
i provider kubeadm di bootstrap e control plane, oltre all'infrastructure provider indicato.

### 1.3 Verifica

```bash
kubectl get pods -A | grep -E 'capi|capd|cert-manager'
kubectl get providers -A
```

Attendere che tutti i deployment dei provider siano `Available` prima di procedere.

---

## Step 2 — Workload cluster

### 2.1 Generazione del manifest

```bash
clusterctl generate cluster capi-quickstart \
  --flavor development \
  --kubernetes-version v1.36.1 \
  --control-plane-machine-count=1 \
  --worker-machine-count=2 \
  > capi-quickstart.yaml
```

Il flavor `development` usa template basati su ClusterClass. I count sono ridotti
rispetto al default della documentazione (3/3) per contenere il consumo di risorse
in locale; il control plane a replica singola non è HA (High Availability) e va bene
solo in ambiente di test.

Ispezionare il manifest generato prima di applicarlo: contiene `Cluster`,
`DockerCluster`, `KubeadmControlPlane`, `MachineDeployment` e i relativi template.

### 2.2 Applicazione

```bash
kubectl apply -f capi-quickstart.yaml
```

### 2.3 Monitoraggio del provisioning

```bash
kubectl get cluster
clusterctl describe cluster capi-quickstart
kubectl get kubeadmcontrolplane
```

Attendere `INITIALIZED=true` sul `KubeadmControlPlane`.

> Il control plane resta `NotReady` finché non viene installato un CNI: è il
> comportamento atteso, non un errore.

### 2.4 Recupero del kubeconfig

```bash
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
```

> Se il control plane endpoint non è raggiungibile dall'host con questo metodo,
> usare `kind get kubeconfig --name capi-quickstart > capi-quickstart.kubeconfig`,
> che riscrive l'endpoint su un indirizzo raggiungibile dall'host.

### 2.5 Installazione del CNI

Senza CNI i nodi non passano mai a `Ready`. Calico come esempio:

```bash
kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml
```

Verifica:

```bash
kubectl --kubeconfig=./capi-quickstart.kubeconfig get nodes
```

Tutti i nodi devono risultare `Ready`.

---

## Step 3 — Applicazione sul workload cluster

Ogni comando verso il workload cluster richiede `--kubeconfig=./capi-quickstart.kubeconfig`:
senza, il comando colpisce il management cluster.

### 3.1 Deploy

```bash
helm --kubeconfig=./capi-quickstart.kubeconfig \
  repo add bitnami https://charts.bitnami.com/bitnami
helm --kubeconfig=./capi-quickstart.kubeconfig repo update

helm --kubeconfig=./capi-quickstart.kubeconfig \
  install demo bitnami/nginx \
  --namespace demo --create-namespace \
  --set service.type=ClusterIP
```

`service.type=ClusterIP` perché il workload cluster CAPD non ha un controller
LoadBalancer: un service di tipo `LoadBalancer` resterebbe in `Pending`.

### 3.2 Verifica

```bash
kubectl --kubeconfig=./capi-quickstart.kubeconfig -n demo get pods,svc
kubectl --kubeconfig=./capi-quickstart.kubeconfig -n demo \
  rollout status deployment/demo-nginx
```

### 3.3 Accesso

```bash
kubectl --kubeconfig=./capi-quickstart.kubeconfig -n demo \
  port-forward svc/demo-nginx 8080:80
```

Applicazione raggiungibile su `http://localhost:8080`.

---

## Cleanup

L'ordine è vincolante.

```bash
# 1. Eliminare l'oggetto Cluster: i controller CAPI deprovisionano l'infrastruttura
kubectl delete cluster capi-quickstart

# 2. Solo dopo, eliminare il management cluster
kind delete cluster
```

> Non usare `kubectl delete -f capi-quickstart.yaml`: rimuove i manifest senza
> lasciare ai controller il tempo di deprovisionare, lasciando container orfani da
> ripulire a mano. L'eliminazione dell'oggetto `Cluster` è ciò che innesca il
> deprovisioning ordinato via owner reference.

---

## Troubleshooting

| Sintomo | Causa probabile | Verifica |
|---|---|---|
| Nodi bloccati su `NotReady` | CNI assente o non avviato | `kubectl --kubeconfig=... get pods -n kube-system` |
| Machine ferma in `Provisioning` | CAPD non raggiunge il socket del runtime | Log di `capd-controller-manager` in `capd-system` |
| `too many open files` | Limiti `inotify` / `ulimit` dell'host troppo bassi | `sysctl fs.inotify.max_user_instances` |
| Pod in `ErrImagePull` | Rate limit del registry pubblico | `kubectl describe pod` sul pod interessato |
| Provisioning fermo senza eventi | Il control plane non è ancora inizializzato | `clusterctl describe cluster capi-quickstart` |

## Riferimenti

- Cluster API Book — Quick Start: https://cluster-api.sigs.k8s.io/user/quick-start
- Glossario CAPI: https://cluster-api.sigs.k8s.io/reference/glossary
- Version support matrix: https://cluster-api.sigs.k8s.io/reference/versions