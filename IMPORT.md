# DeckCheck source publication

The DeckCheck application was developed through nine genuine, successive local commits. This publication branch holds a verified Git bundle and a one-use manual workflow that imports those exact commits into a new `source` branch. It does not flatten the application into a single commit or manufacture earlier commit dates.

The expected original head is `bfbd124d68a95ed7a549a6e6dd6404577fd5d6ee`. The bundle SHA-256 is `9071d1f73b530ea0915f4bc8cbfa0b47c1c82678287d6c36e0ee64ec5e6ba521`. The imported branch contains the application README, GPL-3.0 source, synthetic examples and native functional checks.

The import job verifies the bundle hash and Git history, refuses to replace an existing source branch, and pushes without force. It uses the ordinary repository-scoped GitHub Actions token with only contents permission; it does not run application code or use any user credential or repository secret.
