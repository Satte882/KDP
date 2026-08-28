# Agent Instructions - KDP

Diese Regeln gelten für Agenten, die in diesem Repository arbeiten und Amazon KDP über `joshyattridge/amazon-kdp-skill` bedienen.

## Ziel

Der Agent soll aus einem freigegebenen Buch-Release einen validierten KDP-Draft erzeugen. Die finale Veröffentlichung bleibt ein Human Gate.

## Externer Skill

Verwende für KDP-Interaktionen:

- `joshyattridge/amazon-kdp-skill`
- Upstream: https://github.com/joshyattridge/amazon-kdp-skill
- lokale Installation: `.agents/skills/amazon-kdp`

Der Skill wird separat installiert. Fremdcode nicht ungeprüft in dieses Repository kopieren.

Nach Installation oder Update des Upstream-Skills muss die getestete lokale Härtung ausgeführt werden:

```powershell
./scripts/harden-kdp-skill.ps1
```

`./scripts/setup-kdp-skill.ps1` führt Installation und Härtung automatisch nacheinander aus.

## Windows / lokaler API-Endpunkt

Auf Windows ist für lokale CLI-Aufrufe dieses Repositories `127.0.0.1` statt `localhost` zu verwenden, um mögliche IPv4-/IPv6-Auflösungsunterschiede von Node `fetch` zu vermeiden.

Vor Upstream-CLI-Aufrufen:

```powershell
$env:KDP_API_URL = "http://127.0.0.1:3001"
```

Für einen ungefährlichen Read-only-Test steht zur Verfügung:

```powershell
./scripts/kdp-smoke.ps1
```

Der Smoke-Test darf den lokalen Server starten, prüft `/api/kdp/health`, `/api/kdp/status` und `npm run status`, führt aber weder Login noch KDP-Schreiboperationen aus.

## Pflichtablauf

1. Prüfe, ob der KDP Skill installiert und die lokale Härtung angewendet ist.
2. Prüfe die KDP-Session vor jedem Read-/Write-Workflow.
3. Unter Windows `KDP_API_URL=http://127.0.0.1:3001` für lokale Upstream-CLI-Aufrufe setzen.
4. Falls Login notwendig ist, öffne den vorgesehenen sichtbaren Browser-Login und lasse den Benutzer Amazon-Login/MFA selbst durchführen.
5. Validiere Release-Dateien und Metadaten vor KDP-Schreibzugriffen.
6. Führe schreibende Aktionen zuerst als Dry-run aus.
7. Verarbeite immer nur ein Buch bzw. einen Write-Workflow gleichzeitig.
8. Verifiziere Änderungen nach dem Schreiben durch erneutes Auslesen, soweit der Skill dies unterstützt.
9. Stoppe vor einem Live-Publish.
10. Ein Live-Publish ist nur nach einer expliziten Benutzeranweisung zulässig, die sich auf das konkrete Buch/Release bezieht.

## Lokale Härtung des Upstream-Skills

Der aktuelle Upstream-Stand hat zwei für dieses Repository relevante Probleme:

1. Er deklariert `xlsx@^0.18.5`, obwohl für diese alte npm-Version bekannte High-Severity-Advisories existieren.
2. Im Live-Write-Pfad von `server/src/kdpPublish.ts` wird `saveResult` außerhalb seines ursprünglichen Block-Scopes verwendet.

`scripts/harden-kdp-skill.ps1` behebt lokal genau diese bekannten Zustände:

- ersetzt SheetJS durch die offizielle CE-Version `0.20.3` vom SheetJS-CDN;
- führt anschließend `npm audit --omit=dev` aus und bricht bei verbleibenden Production-Vulnerabilities ab;
- korrigiert den bekannten `saveResult`-Scope-Fehler;
- verweigert den Source-Patch, wenn der Upstream-Code nicht mehr dem bekannten fehlerhaften oder bereits korrigierten Muster entspricht.

Die Härtung wurde in GitHub Actions auf `windows-latest` zusammen mit Parser-, Audit- und Read-only-KDP-Smoke-Tests geprüft.

Da `.agents/` generierter lokaler Zustand ist, muss die Härtung nach einer Neuinstallation oder einem Update des Upstream-Skills erneut angewendet werden.

Details: [`docs/SECURITY.md`](docs/SECURITY.md).

## Verboten

- Kein automatisches Live-Publish aufgrund allgemeiner Aussagen wie "mach alles fertig" oder "veröffentliche das Buch", wenn der konkrete finale KDP-Draft nicht zuvor geprüft wurde.
- Keine parallelen KDP-Schreiboperationen.
- Keine Umgehung des Upstream-Rate-Limits.
- Keine Speicherung von Amazon-Passwörtern, MFA-Codes oder Session-Cookies in Git.
- `.kdp-session/`, `.env`, Reports und lokale Browserdaten niemals committen.
- Kein `npm audit fix --force`.
- Keine zusätzlichen lokalen Patches am Upstream-Skill ohne reproduzierbaren Test.
- Nicht raten, wenn KDP unerwartete Pflichtfelder, Warnungen, Preisabweichungen oder Preview-Fehler zeigt.

## Human Gate vor Publish

Vor einer Veröffentlichung muss der Agent einen kompakten Freigabestatus liefern mit:

- Buch / Edition / Format
- verwendeter Manuskriptdatei
- verwendeter Coverdatei
- Titel / Untertitel / Autor
- ISBN-Status
- Kategorien / Keywords
- Listenpreis und relevante Märkte
- Ergebnis der KDP Preview bzw. bekannte Warnungen
- offene Punkte

Danach stoppen.

Erst nach expliziter Freigabe darf der Agent den Live-Publish-Schritt ausführen.

## Fehlerstrategie

Bei Fehlern:

1. Fehler und KDP-Schritt identifizieren.
2. Vorhandene Recovery-Informationen des Upstream-Skills auswerten.
3. Nur reversible Korrekturen automatisch ausführen.
4. Bei unklaren Auswirkungen stoppen und den Benutzer informieren.

## Release-Artefakte

Bevorzugte Struktur:

```text
release/
  manuscript.docx
  ebook.epub
  print.pdf
  cover.pdf
  metadata.json
  kdp-release.json
```

Die konkrete Release-Spezifikation soll sich an `templates/kdp-release.example.json` orientieren und nur die für das konkrete Format relevanten Felder enthalten.
