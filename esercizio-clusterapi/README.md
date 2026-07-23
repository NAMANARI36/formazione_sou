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
|--|--|
| **Management Cluster** | **Cluster Kubernetes** che ospita i **Provider** contenenti i **CRD** e i **Controller** di **CAPI**. È il punto di controllo da cui viene dichiarato e riconciliato il ciclo di vita dei **Workload Cluster**. |
| **Workload Cluster** | **Cluster Kubernetes** il cui ciclo di vita è gestito dal **Management Cluster**. Destinato a ospitare i carichi applicativi. |

Un **Provider** è un pacchetto di **CRD** e **Controller** che implementa uno strato di responsabilità del ciclo di vita del **Cluster** per una tecnologia specifica.

# Task
1. Creare un ClusterAPI
2. Avviare un Workload Cluster
3. Fare il deploy di un'applicazione sul Workload Cluster

# Prerequisiti
- Docker
- kubectl 
- kind

# Riferimento alla guida
https://cluster-api.sigs.k8s.io/user/quick-start

# Passaggi
## Step 1 Installazione dei prerequisiti
~~~
brew install kind kubectl
brew install --cask docker-desktop
~~~

## Step 2 Creazione del Cluster kind con l'obiettivo di utilizzare il Provider di Docker (CAPD)
~~~
kind create cluster --config kind-capd.yaml
~~~

## Step 3 Installazione del clusterctl
1. Download di clusterctl per MacOS con AMD64
~~~
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.4/clusterctl-darwin-amd64 -o clusterctl
~~~

2. Rendere eseguibile il file binario appena scaricato
~~~
chmod +x ./clusterctl
~~~

3. Installazione del binario
~~~
sudo mv ./clusterctl /usr/local/bin/clusterctl
~~~

## Step 4 Trasformazione del Cluster in un Management Cluster con Provider Docker come infrastruttura
1. Abilitazione della feature gate ClusterTopology
~~~
export CLUSTER_TOPOLOGY=true
~~~

2. Inizializzazione del Management Cluster con il Provider Docker
~~~ 
clusterctl init --infrastructure docker
~~~

## Step 5 Creazione del Workload Cluster
1. Genero il manifest del Workload andando a sostituire alle variabili del template del Provider i parametri scelti
~~~
clusterctl generate cluster capi-quickstart \
  --flavor development \
  --kubernetes-version v1.36.1 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > capi-quickstart.yaml
~~~

2. Creo il Workload Cluster
~~~
kubectl apply -f capi-quickstart.yaml
~~~

## Step 6 Installazione del Container Network Interface Calico sul Workload Cluster
Lo scopo di Calico è fornire connettività di rete ai Pod e applicare le policy che la regolano

1. Recupero del kubeconfig del Workload Cluster
~~~
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
~~~

2. Applicazione del Manifest di Calico sul Workload Cluster
~~~
kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.0/manifests/calico.yaml
~~~

## Step 7 Deploy di un'applicazione di prova sul Workload Cluster
1. Creazione di un Deployment nginx
~~~
kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  create deployment nginx --image=nginx --replicas=2
~~~

2. Esposizione del Deployment tramite un Service di tipo NodePort
~~~
kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  expose deployment nginx --port=80 --type=NodePort
~~~

3. Accesso all'applicazione tramite port-forward
~~~
kubectl --kubeconfig=./capi-quickstart.kubeconfig \
  port-forward svc/nginx 8080:80
~~~

4. Verifica della risposta dell'applicazione
~~~
curl http://localhost:8080
~~~






