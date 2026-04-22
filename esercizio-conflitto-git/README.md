# Traccia
Generare volontariamente un conflitto su git attraverso il comando di merge delle branch e poi risolverlo.







## Soluzione
Ho clonato la repository "formazionesou" sulla VM con il comando git clone https://github.com/username/repository-name </br>
Nel branch master ho creato un file.txt attraverso il comando touch nome-file </br>
Ho modificato il file.txt con il comando vim nome-file e successivamente ho scritto sulla prima riga del testo </br>
Ho eseguito il comando git add nome-file per passare dalla working area alla staging area di git </br>
Ho eseguito il comando git commit nome-file per creare la snapshot locale del file attuale </br>
Ho creato un branch con il comando git branch nome-branch </br>
Successivamente mi sono spostato dal branch master al branch appena creato con il comando git switch nome-branch </br>
Ho modificato il file.txt presente nel branch cambiando la prima riga di testo scritta in precedenza </br>
Ho eseguito git add e git commit per allineare il branch con il branch master </br>
Successivamente sono tornato sul master branch con il comando git switch nome-branch </br>
Ho eseguito il comando git merge nome-branch per provare a unire il branch master con il branch, generando il conflitto tra file </br>
Infine ho utilizzato il comando git checkout --ours nome-file per risolvere il conflitto e mantenere come file definitivo quello presente nel branch master </br>
