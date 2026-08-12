# Throne and Liberty — Astrum English Localization

English localization for the Astrum (RU) version of Throne and Liberty, covering T1 and T2/Talandre content.

## Install

1. [Download `tl_localization.bat`](https://github.com/berkaycimsir/tl-astrum-english/releases/latest/download/tl_localization.bat).
2. Close Throne and Liberty.
3. Run the downloaded batch file.
4. Choose **Install English**.
5. Select the Throne and Liberty folder if it is not detected automatically.

The batch file downloads the matching localization payload and installer from this repository. To return to Russian, run it again and choose **Restore Russian**.

## Current build

- Built for the Astrum Talandre/T2 localization catalog shipped with `TL.exe` version `1.321.32.16466`.
- Preserves all 125,800 Astrum localization keys and hashes.
- Applies English to 123,580 safely matched rows (98.24% catalog coverage).
- All 2,797 explicitly marked T1 rows are English.
- All 1,959 explicitly marked T2 rows are English.
- Talandre and Herba content is included.
- All 382 detected T3-related rows remain in Russian; this release intentionally covers only T1 and T2.
- Other unmatched strings remain Russian instead of receiving guessed translations.

## How it works

The installer places the compatible localization file at:

```text
<Game>\TL\Content\Localization\Game\ru\Game.locres
```

It temporarily moves the original Russian localization PAK and signature into a timestamped backup directory. The restore option removes the loose English file and restores those original files.

## Safety

- The game must be closed before installing or restoring.
- Existing localization files are backed up.
- No executable or DLL modification.
- No process memory access.
- No anti-cheat bypass.
- No PAK or signature modification.

The mod may need rebuilding after an Astrum game update changes the localization catalog. If localization stops working after a patch, restore Russian and wait for a compatible release.

## Verification

`payload/Game.locres` SHA-256:

```text
463BFAC99222991A4268C61740F04F10719FDD07809962D5C26B61F000C305B1
```

## Disclaimer

This is an unofficial community localization project and is not affiliated with Astrum Entertainment, NCSOFT, Amazon Games, or the Throne and Liberty development team. Use it at your own risk.
