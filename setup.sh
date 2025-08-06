#!/bin/bash
# setup.sh - Installiert AbhÃ¤ngigkeiten und richtet Projektverzeichnisse ein

echo "=== R-Backup-Server Setup ==="

# Pakete installieren
echo "Installiere benÃ¶tigte Pakete..."
apt update
apt install -y rsync rsnapshot cifs-utils postfix mailutils

# Verzeichnisse anlegen
echo "Erstelle Projektverzeichnisse..."
mkdir -p /opt/R-Backup-Server/jobs
mkdir -p /opt/R-Backup-Server/logs
mkdir -p /opt/R-Backup-Server/configs
mkdir -p /opt/R-Backup-Server/credentials
mkdir -p /mnt/live-backup
mkdir -p /opt/7z

# 7-Zip installieren
echo "Installiere 7-Zip..."
wget -q "https://www.7-zip.org/a/7z2201-linux-x64.tar.xz" -O "/opt/7z"
tar -xf 7z2201-linux-x64.tar.xz
rm /opt/7z/7z2201-linux-x64.tar.xz

chmod 700 /opt/R-Backup-Server/credentials

# Mailadresse abfragen
read -p "E-Mail-Adresse fÃ¼r Benachrichtigungen: " MAILADDR
echo "MAIL_TO=$MAILADDR" > /opt/R-Backup-Server/mail.conf

# Skripte kopieren
cp add-server.sh /opt/R-Backup-Server/
cp cron-vorlage.sh /opt/R-Backup-Server/
chmod +x /opt/R-Backup-Server/add-server.sh
chmod +x /opt/R-Backup-Server/cron-vorlage.sh

echo "Setup abgeschlossen. Starte mit:"
echo "sudo /opt/R-Backup-Server/add-server.sh"
