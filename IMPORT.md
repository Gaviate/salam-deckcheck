# DeckCheck source publication

The DeckCheck application was developed through ten genuine, successive local commits. This publication branch holds a verified Git bundle and a one-use manual workflow that imports those exact commits into a new `source` branch. The source branch contains the application README, GPL-3.0 source, synthetic examples and native functional checks.

Expected original head: `363c9550a7161ceb785e881c2dc03d1c90fd7363`.

Bundle SHA-256: `65622646be55f9b3517f4ebfa8481cea2855178a2d29ac01b6916b8e415be79d`.

The import job verifies the bundle hash and complete Git history, refuses to replace an existing source branch, and pushes without force. It uses the ordinary repository-scoped GitHub Actions token with only contents permission. It does not run application code or use any user credential or repository secret.
