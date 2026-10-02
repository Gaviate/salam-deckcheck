# DeckCheck

DeckCheck is an offline command-line checker for flashcard decks, written in
Salam. It is intended to catch editing mistakes before a TSV deck is imported
into a study app.

The input format is one card per line: `question<TAB>answer<TAB>topic`.
DeckCheck detects malformed rows and blank questions or answers, keeping the
original physical line numbers in its diagnostics. Blank lines and `#` comments
are ignored. A deck with no cards fails validation.

Complete cards with repeated questions are errors. Questions are trimmed and
Unicode case-folded for comparison; the diagnostic points to the first occurrence.
Answers and topics do not affect duplicate detection.

Topic counts include unique complete cards only. Labels are trimmed and grouped
without case distinctions, keeping the first spelling and first-appearance
order. An empty topic is allowed and appears as `No topic`. UTF-8 deck
content is preserved.

Both LF and CRLF line endings and an optional UTF-8 BOM are supported. Empty
fields and physical blank lines are preserved by the reader. Quoted fields,
escaped tabs, headers, and multiline cards are outside this simple TSV format.
Rows consisting of tab-separated empty fields are cards and fail validation;
only whitespace-only lines without tabs are ignored. NUL-containing files are
rejected as unreadable, since Salam's native strings cannot represent NUL bytes.
Unicode normalization forms are not merged. On Windows, the v0.4.7 native
runtime requires file paths representable in the current system code page;
use an ASCII path when a Unicode path cannot be opened.

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
