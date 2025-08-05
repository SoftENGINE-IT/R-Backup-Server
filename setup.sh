#!/bin/bash
# setup.sh - Installiert Abhängigkeiten und richtet Projektverzeichnisse ein

echo "=== R-Backup-Server Setup ==="

# Pakete installieren
echo "Installiere benötigte Pakete..."
apt update
apt install -y rsync rsnapshot cifs-utils postfix mailutils

# Verzeichnisse anlegen
echo "Erstelle Projektverzeichnisse..."
mkdir -p /opt/R-Backup-Server/jobs
mkdir -p /opt/R-Backup-Server/logs
mkdir -p /opt/R-Backup-Server/configs
mkdir -p /opt/R-Backup-Server/credentials
mkdir -p /mnt/live-backup

chmod 700 /opt/R-Backup-Server/credentials

# Mailadresse abfragen
read -p "E-Mail-Adresse für Benachrichtigungen: " MAILADDR
echo "MAIL_TO=$MAILADDR" > /opt/R-Backup-Server/mail.conf

# Skripte kopieren
cp add-server.sh /opt/R-Backup-Server/
cp cron-vorlage.sh /opt/R-Backup-Server/
chmod +x /opt/R-Backup-Server/add-server.sh
chmod +x /opt/R-Backup-Server/cron-vorlage.sh

echo "Setup abgeschlossen. Starte mit:"
echo "sudo /opt/R-Backup-Server/add-server.sh"
