#!/bin/bash
# setup.sh - Installiert Abhängigkeiten und richtet Projektverzeichnisse ein

echo "=== R-Backup-Server Setup ==="

# Pakete installieren
echo "Installiere benötigte Pakete..."
apt update
apt install -y rsync rsnapshot cifs-utils

# Verzeichnisse anlegen
echo "Erstelle Projektverzeichnisse..."
mkdir -p /opt/R-Backup-Server/jobs
mkdir -p /opt/R-Backup-Server/logs
mkdir -p /opt/R-Backup-Server/configs
mkdir -p /mnt/live-backup

# Skripte kopieren (falls aus GitHub geklont)
cp add-server.sh /opt/R-Backup-Server/
cp cron-vorlage.sh /opt/R-Backup-Server/
chmod +x /opt/R-Backup-Server/add-server.sh
chmod +x /opt/R-Backup-Server/cron-vorlage.sh

echo "Setup abgeschlossen. Starte mit:"
echo "sudo /opt/R-Backup-Server/add-server.sh"
