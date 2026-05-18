#!/usr/bin/env bash
arrayDichiarativo=("Geppetto" "Gabriele" "VAlerio" "GiuLIA" "FABIANO" "MeRiSiTa" "Annie" "Jenny" "GEPPETTO" "Valerio" "Fabiano")
declare -A arrayAssociativo

for stringa in "${arrayDichiarativo[@]}"; do
    chiave="${stringa,,}"
    arrayAssociativo["$chiave"]=1
done

for chiave in "${!arrayAssociativo[@]}"; do
    echo "$chiave"
done
