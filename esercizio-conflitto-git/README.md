## Traccia
Generare volontariamente un conflitto su git attraverso il comando di merge delle branch e poi risolverlo.







# Soluzione
Ho clonato la repository formazionesou sulla VM. Ho creato il file giovanni.txt sul branch main e ho aggiunto del testo alla prima riga, poi ho fatto git add e git commit, poi ho creato il branch "ConflittoMerge", mi ci sono spostato con il comando git switch "ConflittoMerga", e poi Ho modificiato il file txt con vim, cambiando la prima riga del file, poi ho fatto git add e git commit, successivamente sono tornato sul main e ho provato a fare il merge generando un conflitto. Il conflittop è dovuto al fatto che git non può automaticamente scegliere quale delle due riga sia quella voluta. Il conflitto è risolvibile in due modi o manualmente, andando a modificare il file txt a mano e seguendo i marker di conflitto scegliere quale codice tenere, altrimenti posso usare il coamdno git checkout --ours nome-file, git checkout --theirs nome-file
