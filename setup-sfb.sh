## Simple File Browser Setup Skript für die SoftENGINE
# Website = https://filebrowser.org

## Variablen
BRAND_NAME="SoftENGINE"

## Instalaltion Simple File Browser
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

## Konfiguration
HOSTIP=$(hostname -I | awk '{print $1}')

filebrowser config set --address $HOSTIP
filebrowser config set --branding.name $BRAND_NAME
filebrowser config set --auth.method=json
filebrowser config --database /opt/R-Backup-Server/filebrowser.db

## Dienst neu starten
systemctl restart filebrowser
