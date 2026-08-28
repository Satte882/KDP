# Agent Instructions - KDP

Diese Regeln gelten für Agenten, die in diesem Repository arbeiten und Amazon KDP über `joshyattridge/amazon-kdp-skill` bedienen.

## Ziel

Der Agent soll aus einem freigegebenen Buch-Release einen validierten KDP-Draft erzeugen. Die finale Veröffentlichung bleibt ein Human Gate.

## Externer Skill

Verwende für KDP-Interaktionen:

- `joshyattridge/amazon-kdp-skill`
- Upstream: https://github.com/joshyattridge/amazon-kdp-skill

Der Skill wird separat installiert. Fremdcode nicht ungeprüft in dieses Repository kopieren.

## Pflichtablauf

1. Prüfe, ob der KDP Skill installiert und funktionsfähig ist.
2. Prüfe die KDP-Session vor jedem Read-/Write-Workflow.
3. Falls Login notwendig ist, öffne den vorgesehenen sichtbaren Browser-Login und lasse den Benutzer Amazon-Login/MFA selbst durchführen.
4. Validiere Release-Dateien und Metadaten vor KDP-Schreibzugriffen.
5. Führe schreibende Aktionen zuerst als Dry-run aus.
6. Verarbeite immer nur ein Buch bzw. einen Write-Workflow gleichzeitig.
7. Verifiziere Änderungen nach dem Schreiben durch erneutes Auslesen, soweit der Skill dies unterstützt.
8. Stoppe vor einem Live-Publish.
9. Ein Live-Publish ist nur nach einer expliziten Benutzeranweisung zulässig, die sich auf das konkrete Buch/Release bezieht.

## Verboten

- Kein automatisches Live-Publish aufgrund allgemeiner Aussagen wie "mach alles fertig" oder "veröffentliche das Buch", wenn der konkrete finale KDP-Draft nicht zuvor geprüft wurde.
- Keine parallelen KDP-Schreiboperationen.
- Keine Umgehung des Upstream-Rate-Limits.
- Keine Speicherung von Amazon-Passwörtern, MFA-Codes oder Session-Cookies in Git.
- `.kdp-session/`, `.env`, Reports und lokale Browserdaten niemals committen.
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
