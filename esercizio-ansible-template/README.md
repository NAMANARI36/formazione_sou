# Traccia 1
Creare un playbook Ansible che aggiunga in append sul file /etc/security/limits.conf alcuni settings per un’utente. 
In ambiente di produzione dobbiamo imporre un numero massimo di file aperti pari a 10000, mentre in ambiente di collaudo e sviluppo 1000.
# Traccia 2
Supponiamo che in /etc/security/access.conf ci sia un’ultima riga che impedisce l’accesso agli utenti non esplicitamente autorizzati (“- : ALL : ALL”).
Creare un playbook Ansible che aggiunga una lista di utenti in whitelist anteponendosi a tale riga (hint: utilizzare l’opzione insertbefore del modulo blockinfile).
