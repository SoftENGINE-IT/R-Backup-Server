#!/bin/bash
# daily-archive.sh - Tägliche Archivierung aller Server um 4 Uhr

BASE_DIR="/opt/R-Backup-Server"
ARCHIVE_DIR="${BASE_DIR}/archive"
CONFIG_FILE="${ARCHIVE_DIR}/archive-config.conf"
ARCHIVER_SCRIPT="${ARCHIVE_DIR}/archivieren.sh"
LOG_FILE="${ARCHIVE_DIR}/daily-archive.log"

# Lock-Datei für parallele Ausführung verhindern
LOCKFILE="/tmp/daily-archive.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Archivierung läuft bereits" >> "$LOG_FILE"
    exit 1
fi

echo "=== Tägliche Archivierung gestartet am $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"

# Prüfen ob Konfigurationsdatei existiert
if [ ! -f "$CONFIG_FILE" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - FEHLER: Konfigurationsdatei nicht gefunden: $CONFIG_FILE" >> "$LOG_FILE"
    exit 1
fi

# Prüfen ob Konfigurationsdatei Einträge hat (Kommentare und leere Zeilen ignorieren)
if ! grep -q '^[^#]' "$CONFIG_FILE" 2>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: Keine Server für Archivierung konfiguriert, überspringe." >> "$LOG_FILE"
    exit 0
fi

# Prüfen ob Archivierungsskript existiert
if [ ! -f "$ARCHIVER_SCRIPT" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - FEHLER: Archivierungsskript nicht gefunden: $ARCHIVER_SCRIPT" >> "$LOG_FILE"
    exit 1
fi

# Erfolgs- und Fehlerzähler
SUCCESS_COUNT=0
ERROR_COUNT=0

# Konfigurationsdatei zeilenweise lesen
while IFS=';' read -r SERVERNAME SOURCE_DIR DEST_DIR || [ -n "$SERVERNAME" ]; do
    # Kommentare und leere Zeilen überspringen
    if [[ "$SERVERNAME" =~ ^#.*$ ]] || [ -z "$SERVERNAME" ]; then
        continue
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Archiviere Server: $SERVERNAME" >> "$LOG_FILE"
    echo "  Quelle: $SOURCE_DIR" >> "$LOG_FILE"
    echo "  Ziel: $DEST_DIR" >> "$LOG_FILE"
    
    # Prüfen ob Quellverzeichnis existiert
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "  WARNUNG: Quellverzeichnis nicht gefunden: $SOURCE_DIR" >> "$LOG_FILE"
        ((ERROR_COUNT++))
        continue
    fi
    
    # Archivierung ausführen
    "$ARCHIVER_SCRIPT" "$SOURCE_DIR" "$DEST_DIR" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  SUCCESS: Archiv für $SERVERNAME erstellt" >> "$LOG_FILE"
        ((SUCCESS_COUNT++))
    else
        echo "  FEHLER: Archivierung für $SERVERNAME fehlgeschlagen" >> "$LOG_FILE"
        ((ERROR_COUNT++))
    fi
    
    echo "" >> "$LOG_FILE"
    
done < "$CONFIG_FILE"

echo "=== Tägliche Archivierung beendet am $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOG_FILE"
echo "Erfolgreiche Archive: $SUCCESS_COUNT" >> "$LOG_FILE"
echo "Fehlerhafte Archive: $ERROR_COUNT" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Exit-Code basierend auf Ergebnis
if [ $ERROR_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi