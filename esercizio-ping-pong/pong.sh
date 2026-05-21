#!/bin/bash

IP_VM1="192.168.1.2"   # IP della VM1
USER_VM1="vagrant"     # Utente della VM1
SLEEPTIME="60"         # Tempo di attesa in secondi
CONTAINER_NAME="pong"  # Nome del container

echo "[VM2] Avvio il container..." 
CONTAINER_ID=$(sudo docker run -d -p 80:80 --name $CONTAINER_NAME ealen/echo-server)

echo "[VM2] Container avviato: $CONTAINER_NAME"
echo "[VM2] Aspetto $SLEEPTIME secondi..."
sleep $SLEEPTIME

echo "[VM2] Fermo il container..."
sudo docker stop $CONTAINER_ID > /dev/null
sudo docker rm $CONTAINER_ID > /dev/null

echo "[VM2] Mi connetto alla VM1 per avviare ping.sh..."
ssh $USER_VM1@$IP_VM1 'bash /home/vagrant/ping.sh'