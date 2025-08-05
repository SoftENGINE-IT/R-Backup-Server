#!/bin/bash
# Vorlage: cron-vorlage.sh
# Parameter: $1 = SERVERNAME, $2 = IP, $3 = SHARE, $4 = USER, $5 = PASS, $6 = BACKUP-TYP

SERVERNAME="$1"
SERVERIP="$2"
SHAREPATH="$3"
SMBUSER="$4"
SMBPASS="$5"
BACKUPTYPE="$6"

BASE_DIR="/opt/R-Backup-Server"
MOUNTPOINT="/mnt/live-backup"
LOGDIR="${BASE_DIR}/logs/${SERVERNAME}"
LOGFILE="${LOGDIR}/${SERVERNAME}-${BACKUPTYPE}.log"
STATUSFILE="backups_complete"

mkdir -p "$LOGDIR"

echo "=== Backup $BACKUPTYPE gestartet am $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOGFILE"

# 1. SMB-Share mounten
echo "Mounting SMB share..." >> "$LOGFILE"
mount -t cifs "//$SERVERIP/$SHAREPATH" "$MOUNTPOINT" -o username="$SMBUSER",password="$SMBPASS",vers=3.0
if [ $? -ne 0 ]; then
    echo "Error: Failed to mount SMB share." >> "$LOGFILE"
    exit 1
fi

# 2. rsnapshot für entsprechenden Typ ausführen
echo "Running rsnapshot $BACKUPTYPE..." >> "$LOGFILE"
rsnapshot -c "${BASE_DIR}/configs/${SERVERNAME}.conf" "$BACKUPTYPE" >> "$LOGFILE" 2>&1

# 3. Statusdatei schreiben
echo "Setting status file..." >> "$LOGFILE"
echo "backups complete" > "${MOUNTPOINT}/${STATUSFILE}"

# 4. Unmount
echo "Unmounting SMB share..." >> "$LOGFILE"
umount "$MOUNTPOINT"

echo "=== Backup $BACKUPTYPE beendet am $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOGFILE"
