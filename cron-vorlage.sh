#!/bin/bash
# Vorlage: cron-vorlage.sh
# Parameter: $1 = SERVERNAME, $2 = IP, $3 = SHARE, $4 = BACKUP-TYP

SERVERNAME="$1"
SERVERIP="$2"
SHAREPATH="$3"
BACKUPTYPE="$4"

BASE_DIR="/opt/R-Backup-Server"
MOUNTPOINT="/mnt/live-backup"
LOGDIR="${BASE_DIR}/logs/${SERVERNAME}"
LOGFILE="${LOGDIR}/${SERVERNAME}-${BACKUPTYPE}.log"
CRED_FILE="${BASE_DIR}/credentials/${SERVERNAME}.smbcredentials"
LOCKFILE="/tmp/r-backup-${SERVERNAME}.lock"
STATUSFILE="backups_complete"
MAIL_CONF="${BASE_DIR}/mail.conf"

mkdir -p "$LOGDIR"

# Mail-Zieladresse laden
if [ -f "$MAIL_CONF" ]; then
    source "$MAIL_CONF"
else
    MAIL_TO="root@localhost"
fi

# Lock setzen (verhindert parallele Ausführung)
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "Backup für $SERVERNAME ($BACKUPTYPE) läuft bereits – Abbruch." > "$LOGFILE"
    echo "Backup für $SERVERNAME ($BACKUPTYPE) läuft bereits." | mail -s "[R-Backup] $SERVERNAME $BACKUPTYPE - Übersprungen" "$MAIL_TO"
    exit 1
fi

echo "=== Backup $BACKUPTYPE gestartet am $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOGFILE"

# 1. SMB-Share mounten
echo "Mounting SMB share..." >> "$LOGFILE"
mount -t cifs "//$SERVERIP/$SHAREPATH" "$MOUNTPOINT" -o credentials="$CRED_FILE",vers=3.0
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount SMB share." >> "$LOGFILE"
    mail -s "[R-Backup] $SERVERNAME $BACKUPTYPE - FEHLER (Mount)" "$MAIL_TO" < "$LOGFILE"
    exit 1
fi

# 2. rsnapshot für entsprechenden Typ ausführen
echo "Running rsnapshot $BACKUPTYPE..." >> "$LOGFILE"
rsnapshot -c "${BASE_DIR}/configs/${SERVERNAME}.conf" "$BACKUPTYPE" >> "$LOGFILE" 2>&1
if [ $? -ne 0 ]; then
    echo "Error: rsnapshot $BACKUPTYPE failed." >> "$LOGFILE"
    umount "$MOUNTPOINT"
    mail -s "[R-Backup] $SERVERNAME $BACKUPTYPE - FEHLER (rsnapshot)" "$MAIL_TO" < "$LOGFILE"
    exit 1
fi

# 3. Statusdatei schreiben
echo "Setting status file..." >> "$LOGFILE"
echo "backups complete" > "${MOUNTPOINT}/${STATUSFILE}"

# 4. Unmount
echo "Unmounting SMB share..." >> "$LOGFILE"
umount "$MOUNTPOINT"

echo "=== Backup $BACKUPTYPE beendet am $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOGFILE"

# Erfolgs-Mail
mail -s "[R-Backup] $SERVERNAME $BACKUPTYPE - Erfolgreich" "$MAIL_TO" < "$LOGFILE"
