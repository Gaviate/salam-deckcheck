# DeckCheck

DeckCheck is an offline command-line checker for flashcard decks, written in
Salam. It is intended to catch editing mistakes before a TSV deck is imported
into a study app.

The input format is one card per line: `question<TAB>answer<TAB>topic`.
DeckCheck detects malformed rows and blank questions or answers, keeping the
original physical line numbers in its diagnostics. Blank lines and `#` comments
are ignored. A deck with no cards fails validation.

## Build

Use Salam v0.4.7 or a compatible release, with its standard library available:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
salam build src/main.salam --output=build/deckcheck.exe
./build/deckcheck.exe fixtures/clean.tsv
```

DeckCheck source is copyright 2026 Jaye, licensed under GPL-3.0-only.
It imports the GPL-3.0 Salam standard library. See [LICENSE](LICENSE).

Exit codes: `0` for a passing deck/help, `1` for validation errors, `2` for
incorrect usage or an unreadable path. All fixtures contain synthetic content.
