#!/bin/bash
# add-server.sh - Fuegt einen neuen Server ins Backup-System ein

BASE_DIR="/opt/R-Backup-Server"
CONFIG_DIR="${BASE_DIR}/configs"
JOBS_DIR="${BASE_DIR}/jobs"
LOGS_DIR="${BASE_DIR}/logs"
CRED_DIR="${BASE_DIR}/credentials"
SNAPSHOT_ROOT="/backups/${SERVERNAME}"

mkdir -p "$CONFIG_DIR" "$JOBS_DIR" "$LOGS_DIR" "$CRED_DIR"

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

# 2. SMB-Credentials-Datei erstellen
CRED_FILE="${CRED_DIR}/${SERVERNAME}.smbcredentials"
cat > "$CRED_FILE" <<EOF
username=${SMBUSER}
password=${SMBPASS}
EOF
chmod 600 "$CRED_FILE"

echo "Backup-Zeiten eingeben (HH:MM-Format):"
read -p "Tägliche Backups um: " TIME_DAILY
read -p "Wöchentliche Backups um: " TIME_WEEKLY
read -p "Monatliche Backups um: " TIME_MONTHLY

# Zeiten umwandeln
CRON_DAILY=$(time_to_cron "$TIME_DAILY")
CRON_WEEKLY=$(time_to_cron "$TIME_WEEKLY" | sed 's/* \* 0/* * 0/')   # Sonntag
CRON_MONTHLY=$(time_to_cron "$TIME_MONTHLY" | sed 's/* \* \*/1 * */') # 1. des Monats

# 3. Retention
read -p "Abweichende Retention-ZeitrÃ¤ume? (y/N): " RET
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

# 4. rsnapshot-Konfiguration erstellen (mit echten Tabs und Backup-Zeile)

# EntsprechendesBackup-Verzeichnis erstellen, falls nicht vorhanden
if [ ! -d "$SNAPSHOT_ROOT" ]; then
    mkdir -p "$SNAPSHOT_ROOT"
    chmod 700 "$SNAPSHOT_ROOT"
fi

RSNAP_CONF="${CONFIG_DIR}/${SERVERNAME}.conf"
{
printf "config_version\t1.2\n"
printf "snapshot_root\t/backups/%s/\n" "$SERVERNAME"
printf "no_create_root\t1\n\n"
printf "retain\tdaily\t%s\n" "$DAILYS"
printf "retain\tweekly\t%s\n" "$WEEKLYS"
printf "retain\tmonthly\t%s\n\n" "$MONTHLYS"
printf "cmd_rsync\t/usr/bin/rsync\n"
printf "cmd_ssh\t/usr/bin/ssh\n"
printf "cmd_logger\t/usr/bin/logger\n\n"
printf "backup\t/mnt/live-backup/\tlocalhost/\n"
} > "$RSNAP_CONF"

# 5. Config testen
if ! rsnapshot -c "$RSNAP_CONF" configtest >/dev/null 2>&1; then
    echo "FEHLER: Die rsnapshot-Konfiguration fuer $SERVERNAME ist ungueltig!"
    rsnapshot -c "$RSNAP_CONF" configtest
    exit 1
fi

# 6. Backupskripte erstellen
mkdir -p "${LOGS_DIR}/${SERVERNAME}"

for TYPE in daily weekly monthly; do
    SCRIPT_PATH="${JOBS_DIR}/${SERVERNAME}-${TYPE}.sh"
    cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
${BASE_DIR}/cron-vorlage.sh "$SERVERNAME" "$SERVERIP" "$SHAREPATH" "$TYPE"
EOF
    chmod +x "$SCRIPT_PATH"
done

# 7. Cronjobs einrichten
TMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TMP_CRON"

echo "$CRON_DAILY ${JOBS_DIR}/${SERVERNAME}-daily.sh" >> "$TMP_CRON"
echo "$CRON_WEEKLY ${JOBS_DIR}/${SERVERNAME}-weekly.sh" >> "$TMP_CRON"
echo "$CRON_MONTHLY ${JOBS_DIR}/${SERVERNAME}-monthly.sh" >> "$TMP_CRON"

crontab "$TMP_CRON"
rm "$TMP_CRON"

# 8. Archiv-Konfiguration (optional)
read -p "Nächtliche Archivierung um 4:00 Uhr aktivieren? (y/N): " ENABLE_ARCHIVE
ENABLE_ARCHIVE=${ENABLE_ARCHIVE:-N}

ARCHIVE_MESSAGE=""
if [[ "$ENABLE_ARCHIVE" =~ ^[Yy]$ ]]; then
    ARCHIVE_CONFIG="${BASE_DIR}/archive/archive-config.conf"
    BACKUP_SOURCE="/opt/backups/${SERVERNAME}"
    ARCHIVE_DEST="${BASE_DIR}/archive/${SERVERNAME}"

    # Archiv-Eintrag zur Konfiguration hinzufügen
    if [ -f "$ARCHIVE_CONFIG" ]; then
        echo "${SERVERNAME};${BACKUP_SOURCE};${ARCHIVE_DEST}" >> "$ARCHIVE_CONFIG"
        echo "Archiv-Konfiguration für $SERVERNAME hinzugefügt."
        ARCHIVE_MESSAGE=" - Tägliche Archivierung um 4:00 Uhr"
    else
        echo "WARNUNG: Archiv-Konfigurationsdatei nicht gefunden: $ARCHIVE_CONFIG"
    fi
fi

echo "Backup-Jobs fuer $SERVERNAME erfolgreich eingerichtet:"
echo " - Daily um $TIME_DAILY"
echo " - Weekly um $TIME_WEEKLY" 
echo " - Monthly um $TIME_MONTHLY"
echo "$ARCHIVE_MESSAGE"
echo "Logs: ${LOGS_DIR}/${SERVERNAME}/"
