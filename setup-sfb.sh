## Simple File Browser Setup Skript
# Website = https://filebrowser.org

## Variablen
BRAND_NAME="yourBrand"
ADMIN_USER_NAME="admin"                     ## Bitte Ändern! "admin" ist kein sicherer Benutzername!
ADMIN_PASSWORD="meinSicheresPasswort!"      ## Bitte Ändern!
HOSTIP=$(hostname -I | awk '{print $1}')

## Instalaltion Simple File Browser
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

mkdir -p /opt/filebrowser
cd /opt/filebrowser

## Konfiguration
filebrowser config init
filebrowser config --database /opt/filebrowser/filebrowser.db
filebrowser config set --address $HOSTIP --branding.name $BRAND_NAME --auth.method=json

## Filebrwoser Benutzer und Dateuberechtigungen
useradd -r -s /bin/false filebrowser
chown -R root:filebrowser /opt/filebrowser

## Filebrowser Admin Benutzer erstellen
filebrowser users add $ADMIN_USER_NAME $ADMIN_PASSWORD
filebrowser users update $ADMIN_USER_NAME --perm.admin
filebrowser users update $ADMIN_USER_NAME --locale de

## Filebrowser Service erstellen und starten
cat <<EOF | sudo tee /etc/systemd/system/filebrowser.service
[Unit]
Description=Filebrowser Service
After=network.target

[Service]
User=root
Group=filebrowser
ExecStart=/usr/local/bin/filebrowser -r /opt/archive --address $HOSTIP -d /opt/filebrowser/filebrowser.db
WorkingDirectory=/opt/archive
Restart=always
RestartSec=5

# Optional: Port setzen (falls nicht Standard 8080)
# ExecStart=/usr/local/bin/filebrowser -r /opt/archive --port 8081

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
sudo systemctl enable filebrowser
sudo systemctl start filebrowser