#!/bin/bash

IP_VM2="192.168.1.3"  # IP della VM2
USER_VM2="vagrant"    # Utente della VM2
SLEEPTIME="60"         # Tempo di attesa in secondi
CONTAINER_NAME="ping"  # Nome del container

echo "[VM1] Avvio il container..."
CONTAINER_ID=$(sudo docker run -d -p 80:80 --name $CONTAINER_NAME ealen/echo-server)

echo "[VM1] Container avviato: $CONTAINER_NAME"
echo "[VM1] Aspetto $SLEEPTIME secondi..."
sleep $SLEEPTIME

echo "[VM1] Fermo il container..."
sudo docker stop $CONTAINER_ID > /dev/null
sudo docker rm $CONTAINER_ID > /dev/null

echo "[VM1] Mi connetto alla VM2 per avviare pong.sh..."
ssh $USER_VM2@$IP_VM2 'bash /home/vagrant/pong.sh'