# R-Backup-Server

Automatisiertes Backup-System für Debian 12 mit `rsnapshot` und SMB-Shares.

## Features

- Drei Backup-Zyklen: **daily**, **weekly**, **monthly**
- Zentrales Mounten unter `/mnt/live-backup`
- Automatische Cronjobs mit einfacher Uhrzeiteingabe (`HH:MM`)
- Individuelle Retention-Einstellungen
- Sichere SMB-Credentials in separaten Dateien (`chmod 600`)
- Locking-Mechanismus verhindert parallele Backups
- Logdateien pro Server und Backup-Typ
- Alle Konfigurationen und Skripte liegen unter `/opt/R-Backup-Server`

---

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/<DEIN-USERNAME>/R-Backup-Server.git
cd R-Backup-Server
```

### 2. Setup ausführen
```bash
bash setup.sh
```
Richtet alle Abhängigkeiten und Verzeichnisse ein.

## Nutzung

### Neuen Server hinzufügen
```bash
bash /opt/R-Backup-Server/add-server.sh
```
Eingaben:

- Servername, IP, SMB-Share
- Benutzername & Passwort
- Uhrzeiten im Format `HH:MM` (z. B. `2:00`)
- Retention optional anpassen

Beispiel:

- Daily um `2:00`
- Weekly um `3:00` (Sonntag)
- Monthly um `4:00` (1. des Monats)

## Credentials
Zugangsdaten werden gespeichert unter:
```bash
/opt/R-Backup-Server/credentials/<SERVERNAME>.smbcredentials
```
Nur root hat Zugriff (chmod 600).

## Verzeichnisstruktur

```plaintext
/opt/R-Backup-Server/
├── add-server.sh
├── cron-vorlage.sh
├── configs/            # rsnapshot-Konfigurationen
│   └── WWR02.conf
├── credentials/
│   └── WWR02.smbcredentials
├── jobs/               # Generierte Skripte
│   ├── WWR02-daily.sh
│   ├── WWR02-weekly.sh
│   └── WWR02-monthly.sh
└── logs/
    └── WWR02/
        ├── WWR02-daily.log
        ├── WWR02-weekly.log
        └── WWR02-monthly.log
```

## Logs

Logs befinden sich unter:
```bash
/opt/R-Backup-Server/logs/<SERVERNAME>/<SERVERNAME>-<typ>.log
```

## Mountpoint
SMB-Share wird immer unter `/mnt/live-backup` gemountet.

## Retention
Default:

- daily: 7 Versionen
- weekly: 4 Versionen
- monthly: 3 Versionen

## Mailbenachrichtigungen

- Erfolgreiche Backups: Mail mit Erfolgsmeldung
- Fehlgeschlagene Backups: Mail mit Logausgabe im Body
- E-Mail-Adresse wird bei `setup.sh` hinterlegt und kann in `/opt/R-Backup-Server/mail.conf` angepasst werden
