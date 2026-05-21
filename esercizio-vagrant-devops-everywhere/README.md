# Traccia
Creare un progetto Vagrant. Tramite un provisioner a vostra scelta (shell scripting, Puppet, Ansible, Chef, ecc...) configurate una macchina Linux ( nessuna preferenza sulla distribuzione ). Sarete liberi di decidere cosa far fare alla macchina. L'importante è che sia portabile. Colui che analizzerà il vostro progetto dovrà eseguire 'vagrant up' e utilizzarla.

## Soluzione

- Ho inizializzato vagrant nella cartella del progetto attraverso il comando vagrant init
- Ho modificato il Vagrant file specificando le caratteristiche hardware per la creazione della VM
- Ho configurato il provisioning di vagrant per far avviare il servizio apache2

