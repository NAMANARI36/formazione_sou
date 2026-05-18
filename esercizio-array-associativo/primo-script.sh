#!/usr/bin/env bash
echo "Geppetto:Gabriele:VAlerio:GiuLIA:FABIANO:MeRiSiTa:Annie:JnnNY:ANITA:MeRiSiTa:Anniei:Gabriele:VAlerio:GiuLIA:BRUNO:ROBERTO" | tr ':' '\n' | tr '[:upper:]' '[:lower:]' | sort | uniq
