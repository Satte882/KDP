# Security notes

## `xlsx` / SheetJS

The upstream skill currently declares:

```json
"xlsx": "^0.18.5"
```

This old npm release is affected by two known advisories:

- `GHSA-4r6h-8v6p-xvw6` / `CVE-2023-30533` — Prototype Pollution while reading crafted spreadsheet files.
- `GHSA-5pgg-2g8v-p4x9` / `CVE-2024-22363` — Regular Expression Denial of Service in versions before 0.20.2.

The maintained SheetJS Community Edition is distributed from the official SheetJS CDN rather than relying on the stale npm-registry release.

### Local mitigation

`scripts/harden-kdp-skill.ps1` replaces the installed skill dependency with the official SheetJS CE `0.20.3` package:

```text
https://cdn.sheetjs.com/xlsx-0.20.3/xlsx-0.20.3.tgz
```

The mitigation has been tested on `windows-latest` with:

- comparison against the upstream TypeScript diagnostic baseline;
- a synthetic workbook round-trip through the skill's `parseKdpXlsxBuffer` parser;
- `npm audit --omit=dev` with no remaining reported production vulnerabilities after the replacement.

This is a local compatibility-tested override. It is not an upstream release of `joshyattridge/amazon-kdp-skill` and should be removed once upstream ships an equivalent or newer fix.

Do not run `npm audit fix --force` against the installed skill.

## KDP publish path: `saveResult` scope

The current upstream `server/src/kdpPublish.ts` declares `saveResult` inside the `hasMetadata(...)` branch but later references it after that block. Because the server is run through `tsx`, source can be transpiled even though TypeScript reports the invalid reference; the live write path could therefore fail at runtime.

The local hardening script applies a narrowly scoped fix:

- hoist the `saveResult` binding to the enclosing save-details block;
- assign it inside the metadata branch;
- guard the later recovery check when no metadata save result exists.

The script checks the expected upstream source shape first. If upstream changes the relevant code and it no longer matches either the known broken form or the known fixed form, the script stops instead of modifying unknown source.

GitHub Actions verifies that the core `kdpPublish.ts` `saveResult` diagnostic is removed and that the local KDP server still passes the read-only Windows smoke test after hardening.

## Remaining upstream TypeScript diagnostics

The current upstream repository also contains TypeScript diagnostics in development/debug/staging code that are not introduced by the local SheetJS override. They are treated as upstream quality debt and are not automatically patched by this repository.

A full clean `tsc --noEmit` is therefore not currently used as a release gate. Instead, the workflow compares the SheetJS-upgraded diagnostics with the upstream baseline and separately validates the core publish scope issue.

## Sessions and credentials

Never commit:

- `.kdp-session/`
- Amazon cookies or storage state
- `.env` files containing secrets
- passwords or MFA codes
- downloaded royalty reports

The Amazon login and MFA step remains a human action in a visible browser session.
