# Security notes

## `xlsx` / SheetJS

The upstream skill currently declares:

```json
"xlsx": "^0.18.5"
```

This npm release is affected by two known advisories:

- `GHSA-4r6h-8v6p-xvw6` / `CVE-2023-30533` — Prototype Pollution while reading crafted spreadsheet files.
- `GHSA-5pgg-2g8v-p4x9` / `CVE-2024-22363` — Regular Expression Denial of Service in versions before 0.20.2.

The maintained SheetJS Community Edition releases are distributed from the official SheetJS CDN rather than the npm registry. The current supported release should be evaluated upstream before changing the dependency in the installed skill.

### Current policy

Until the upstream skill updates SheetJS:

1. Do not use the KDP skill to parse arbitrary or untrusted `.xlsx` files.
2. Report parsing is limited to royalty/report files downloaded directly from Amazon KDP or files whose origin is explicitly trusted.
3. Metadata export to `.xlsx` is lower risk because the Prototype Pollution advisory concerns reading crafted input files, not writing spreadsheets.
4. The KDP publishing path (metadata, content upload, pricing, draft creation) does not require users to supply arbitrary spreadsheet input and is therefore not blocked by this issue.
5. Do not run `npm audit fix --force` against the installed skill.
6. A future local override to SheetJS >= 0.20.2 must be compatibility-tested before it becomes part of the setup process.

This is a temporary risk control, not a claim that `xlsx@0.18.5` is secure.

## Sessions and credentials

Never commit:

- `.kdp-session/`
- Amazon cookies or storage state
- `.env` files containing secrets
- passwords or MFA codes
- downloaded royalty reports

The Amazon login and MFA step remains a human action in a visible browser session.
