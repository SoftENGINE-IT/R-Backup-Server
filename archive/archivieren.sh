#!/bin/bash

# ======= Konfiguration =======
SOURCE_DIR="/pfad/zur/quelle"     # Quellordner
DEST_DIR="/pfad/zum/ziel"         # Zielordner
SEVEN_ZIP="/opt/7z/7zz"           # Pfad zu 7zz (CLI)

# ======= Datum & Dateiname =======
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="backup_$DATE.7z"

# ======= Sicherung ausführen =======
# Zielordner erstellen, falls er nicht existiert
mkdir -p "$DEST_DIR"

# Backup erstellen
"$SEVEN_ZIP" a -t7z "$DEST_DIR/$ARCHIVE_NAME" "$SOURCE_DIR"

# Rückgabewert prüfen
if [ $? -eq 0 ]; then
    echo "Backup erfolgreich: $DEST_DIR/$ARCHIVE_NAME"
else
    echo "Backup fehlgeschlagen!"
    exit 1
fi
