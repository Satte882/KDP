# KDP Release Pipeline

Dieses Repository beschreibt und steuert eine agentenunterstützte Publishing-Pipeline für Amazon Kindle Direct Publishing (KDP).

Ziel ist **nicht**, Bücher vollautonom zu veröffentlichen. Ziel ist, aus einem freigegebenen Buch-Release reproduzierbar einen vollständigen KDP-Draft zu erzeugen, technische und inhaltliche Schritte zu automatisieren und die finale Veröffentlichung bewusst beim Menschen zu belassen.

## Kernidee

```text
GitHub: Buch / freigegebener Release
        |
        v
Cursor / Coding Agent
        |
        +-- Manuskript prüfen
        +-- DOCX / EPUB / Print-PDF erzeugen
        +-- Cover prüfen
        +-- Metadaten vorbereiten
        +-- KDP Release Spec erzeugen
        |
        v
joshyattridge/amazon-kdp-skill
        |
        v
lokaler Express Server + Playwright
        |
        v
Amazon KDP Weboberfläche
        |
        v
KDP Draft + Preview
        |
        v
MANUELLE FREIGABE
        |
        v
Publish
```

## Warum diese Architektur?

Amazon KDP stellt keine öffentliche Publishing-API für diese Workflows bereit. Der verwendete Skill automatisiert deshalb die KDP-Weboberfläche lokal über Playwright und persistiert die KDP-Session lokal.

Das Repo trennt bewusst zwei Verantwortlichkeiten:

1. **Release Engineering**: Buchdateien, Metadaten, Validierung und reproduzierbare Release-Spezifikation.
2. **KDP Adapter**: Browser-Automatisierung gegen KDP über `joshyattridge/amazon-kdp-skill`.

Damit bleibt die Buch-Pipeline unabhängig von der fragilen KDP-Weboberfläche. Wenn Amazon UI-Elemente ändert, muss primär der Adapter angepasst werden, nicht der gesamte Release-Prozess.

## Verwendeter KDP Skill

Upstream:

- https://github.com/joshyattridge/amazon-kdp-skill

Der Skill unterstützt laut Upstream unter anderem:

- KDP-Session und Login
- Bücherregal und Metadaten-Sync
- Royalty Reports
- Keyword-/Kategorie-Audits
- Metadaten- und Preisänderungen
- Upload von Manuskript und Cover
- Erstellen neuer Titel
- KDP Publish Wizard

Der Skill arbeitet lokal mit Express + Playwright. Schreibende Aktionen sollen zunächst als Dry-run ausgeführt werden. Ein Live-Publish darf in diesem Repository nur nach expliziter menschlicher Freigabe erfolgen.

> Hinweis: Das Upstream-Repo ist ein externer Baustein. Es wird hier nicht vendort oder kopiert, sondern separat installiert. Dadurch bleiben Herkunft, Updates und Verantwortlichkeiten klar getrennt.

## Setup unter Windows

Voraussetzungen:

- Windows 11
- Git
- Node.js / npm
- Cursor oder ein anderer Agent mit Agent-Skills-Unterstützung
- Amazon-KDP-Konto

PowerShell:

```powershell
./scripts/setup-kdp-skill.ps1
```

Alternativ direkt:

```powershell
npx skills add joshyattridge/amazon-kdp-skill
```

Beim ersten Zugriff auf KDP muss der Benutzer den Amazon-Login inklusive MFA selbst durchführen. Session-Cookies dürfen niemals in Git eingecheckt werden.

## Geplanter Release-Ablauf

### Phase 1 - Build

Aus der freigegebenen Buchquelle werden die benötigten Artefakte erzeugt:

```text
release/
  manuscript.docx
  ebook.epub
  print.pdf
  cover.pdf
  metadata.json
  kdp-release.json
```

### Phase 2 - Validate

Vor einem KDP-Schreibzugriff werden geprüft:

- vollständige Metadaten
- vorhandene Release-Dateien
- Buchformat und Seitenlayout
- Coverdatei
- ISBN-Entscheidung
- Preis und Territorien
- Kategorien und Keywords

### Phase 3 - Dry-run

Der KDP Skill wird zunächst ohne Live-Publish ausgeführt.

Beispiel:

```text
Create or update the KDP draft from templates/kdp-release.example.json.
Run all possible validations and uploads as a dry-run.
Do not publish.
Stop and report every unresolved warning.
```

### Phase 4 - KDP Draft

Nach erfolgreichem Dry-run darf der Agent:

- den Titel in KDP anlegen oder aktualisieren
- Metadaten eintragen
- Manuskript hochladen
- Cover hochladen
- Pricing vorbereiten
- KDP Preview vorbereiten

### Phase 5 - Human Gate

Vor Veröffentlichung wird zwingend gestoppt.

Der Mensch prüft insbesondere:

- KDP Preview
- Titel und Untertitel
- Autorenname
- Beschreibung
- Kategorien und Keywords
- Preis und Märkte
- Rechte / Territories
- ISBN
- Druckkosten und Royalty

Erst danach darf eine explizite Live-Publish-Anweisung erfolgen.

## Sicherheits- und Governance-Regeln

Die verbindlichen Agent-Regeln stehen in [`AGENTS.md`](AGENTS.md).

Kernprinzipien:

- Read-Aktionen dürfen automatisiert erfolgen.
- Write-Aktionen zuerst als Dry-run.
- Ein Buch nach dem anderen; keine parallelen KDP-Schreibvorgänge.
- Keine Session-Cookies oder Amazon-Zugangsdaten im Repository.
- Kein Live-Publish ohne explizite menschliche Freigabe.
- Bei unerwarteten KDP-Dialogen, Preisabweichungen oder Preview-Problemen stoppen statt raten.

## Repository-Struktur

```text
KDP/
  README.md
  AGENTS.md
  .gitignore
  scripts/
    setup-kdp-skill.ps1
  templates/
    kdp-release.example.json
```

Später können Build-/Validierungs-Skripte ergänzt werden, ohne den KDP-Adapter selbst in dieses Repository zu kopieren.

## Zielbild

Der gewünschte Endzustand ist:

```text
freigegebener Buch-Release
        -> reproduzierbarer KDP Draft
        -> menschliche Qualitätskontrolle
        -> explizite Veröffentlichung
```

Damit wird KDP vom manuellen Einmalprozess zu einem kontrollierten Release-Prozess, ohne die letzte irreversible Entscheidung an einen Agenten abzugeben.
