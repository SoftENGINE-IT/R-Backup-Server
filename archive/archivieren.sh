#!/bin/bash

# Parameter prüfen
if [ $# -ne 2 ]; then
    echo "Verwendung: $0 <SOURCE_DIR> <DEST_DIR>"
    echo "  SOURCE_DIR: Quellordner für das Backup"
    echo "  DEST_DIR: Zielordner für das Archiv"
    exit 1
fi

# ======= Konfiguration =======
SOURCE_DIR="$1"                   # Quellordner (Parameter 1)
DEST_DIR="$2"                     # Zielordner (Parameter 2)
SEVEN_ZIP="/opt/7z/7zz"           # Pfad zu 7zz (CLI)

# .env Datei laden (falls vorhanden)
SCRIPT_DIR="$(dirname "$0")"
ENV_FILE="${SCRIPT_DIR}/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# ======= Datum & Dateiname =======
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="backup_$DATE.7z"

# ======= Sicherung ausführen =======
# Zielordner erstellen, falls er nicht existiert
mkdir -p "$DEST_DIR"

# Backup erstellen (mit optionaler Verschlüsselung)
if [ -n "$ARCHIVE_PASSWORD" ] && [ "$ARCHIVE_PASSWORD" != "" ]; then
    echo "Erstelle verschlüsseltes Archiv..."
    "$SEVEN_ZIP" a -t7z -p"$ARCHIVE_PASSWORD" "$DEST_DIR/$ARCHIVE_NAME" "$SOURCE_DIR"
else
    echo "Erstelle unverschlüsseltes Archiv..."
    "$SEVEN_ZIP" a -t7z "$DEST_DIR/$ARCHIVE_NAME" "$SOURCE_DIR"
fi

# Rueckgabewert prüfen
if [ $? -eq 0 ]; then
    echo "Backup erfolgreich: $DEST_DIR/$ARCHIVE_NAME"
else
    echo "Backup fehlgeschlagen!"
    exit 1
fi
