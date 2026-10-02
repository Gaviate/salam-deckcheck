# DeckCheck

DeckCheck is an offline command-line checker for flashcard decks, written in
Salam. It is intended to catch editing mistakes before a TSV deck is imported
into a study app.

The input format is one card per line: `question<TAB>answer<TAB>topic`.
DeckCheck now loads local deck files and reports their physical line count.
Validation is being developed incrementally in this repository.

## Build

Use Salam v0.4.7 or a compatible release, with its standard library available:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
salam build src/main.salam --output=build/deckcheck.exe
./build/deckcheck.exe fixtures/clean.tsv
```

DeckCheck source is copyright 2026 Jaye, licensed under GPL-3.0-only.
It imports the GPL-3.0 Salam standard library. See [LICENSE](LICENSE).
