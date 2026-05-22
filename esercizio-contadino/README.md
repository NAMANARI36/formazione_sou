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

