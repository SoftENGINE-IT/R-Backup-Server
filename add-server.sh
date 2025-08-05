#!/bin/bash
# add-server.sh - Fügt einen neuen Server ins Backup-System ein

BASE_DIR="/opt/R-Backup-Server"
CONFIG_DIR="${BASE_DIR}/configs"
JOBS_DIR="${BASE_DIR}/jobs"
LOGS_DIR="${BASE_DIR}/logs"

mkdir -p "$CONFIG_DIR" "$JOBS_DIR" "$LOGS_DIR"

# Funktion: Uhrzeit (HH:MM) in Cron-Format umwandeln
time_to_cron() {
    local input="$1"
    IFS=":" read -r HOUR MINUTE <<< "$input"
    HOUR=${HOUR:-0}
    MINUTE=${MINUTE:-0}
    echo "$MINUTE $HOUR * * *"
}

# 1. Eingaben
read -p "Name des neuen Servers: " SERVERNAME
read -p "IP des neuen Servers: " SERVERIP
read -p "Pfad des SMB-Shares [Standard: J]: " SHAREPATH
SHAREPATH=${SHAREPATH:-J}
read -p "Benutzername des SMB-Shares: " SMBUSER
read -s -p "Passwort des SMB-Shares: " SMBPASS
echo

echo "Backup-Zeiten eingeben (HH:MM-Format):"
read -p "Tägliche Backups um: " TIME_DAILY
read -p "Wöchentliche Backups um: " TIME_WEEKLY
read -p "Monatliche Backups um: " TIME_MONTHLY

# Zeiten umwandeln
CRON_DAILY=$(time_to_cron "$TIME_DAILY")
CRON_WEEKLY=$(time_to_cron "$TIME_WEEKLY" | sed 's/* \* 0/* * 0/')   # Sonntag
CRON_MONTHLY=$(time_to_cron "$TIME_MONTHLY" | sed 's/* \* \*/1 * */') # 1. des Monats

# 2. Retention
read -p "Abweichende Retention-Zeiträume? (y/N): " RET
RET=${RET:-N}

DAILYS=7
WEEKLYS=4
MONTHLYS=3

if [[ "$RET" =~ ^[Yy]$ ]]; then
    read -p "Wie viele dailys behalten? [Standard 7]: " DAILYS
    DAILYS=${DAILYS:-7}
    read -p "Wie viele weeklys behalten? [Standard 4]: " WEEKLYS
    WEEKLYS=${WEEKLYS:-4}
    read -p "Wie viele monthlys behalten? [Standard 3]: " MONTHLYS
    MONTHLYS=${MONTHLYS:-3}
fi

# 3. rsnapshot-Konfiguration erstellen
RSNAP_CONF="${CONFIG_DIR}/${SERVERNAME}.conf"
cat > "$RSNAP_CONF" <<EOF
config_version  1.2
snapshot_root   /backups/${SERVERNAME}/
no_create_root  1

retain  daily   ${DAILYS}
retain  weekly  ${WEEKLYS}
retain  monthly ${MONTHLYS}

cmd_rsync       /usr/bin/rsync
cmd_ssh         /usr/bin/ssh
cmd_logger      /usr/bin/logger
EOF

# 4. Backupskripte erstellen
mkdir -p "${LOGS_DIR}/${SERVERNAME}"

for TYPE in daily weekly monthly; do
    SCRIPT_PATH="${JOBS_DIR}/${SERVERNAME}-${TYPE}.sh"
    cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
${BASE_DIR}/cron-vorlage.sh "$SERVERNAME" "$SERVERIP" "$SHAREPATH" "$SMBUSER" "$SMBPASS" "$TYPE"
EOF
    chmod +x "$SCRIPT_PATH"
done

# 5. Cronjobs einrichten
TMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TMP_CRON"

echo "$CRON_DAILY ${JOBS_DIR}/${SERVERNAME}-daily.sh" >> "$TMP_CRON"
echo "$CRON_WEEKLY ${JOBS_DIR}/${SERVERNAME}-weekly.sh" >> "$TMP_CRON"
echo "$CRON_MONTHLY ${JOBS_DIR}/${SERVERNAME}-monthly.sh" >> "$TMP_CRON"

crontab "$TMP_CRON"
rm "$TMP_CRON"

echo "Backup-Jobs für $SERVERNAME erfolgreich eingerichtet:"
echo " - Daily um $TIME_DAILY"
echo " - Weekly um $TIME_WEEKLY"
echo " - Monthly um $TIME_MONTHLY"
echo "Logs: ${LOGS_DIR}/${SERVERNAME}/"
