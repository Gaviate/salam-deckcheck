param([string] $Compiler = 'salam')

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$deckcheckRoot = Split-Path -Parent $PSScriptRoot
$deckcheckPassed = 0
$deckcheckUtf8 = [System.Text.UTF8Encoding]::new($false)

function Assert-Run {
    param(
        [string] $Name,
        [string[]] $CliArguments,
        [int] $ExpectedExit,
        [string[]] $Patterns
    )
    # Expected validation failures must be captured as data under PowerShell 7.
    $PSNativeCommandUseErrorActionPreference = $false
    $deckcheckOutput = @(& $script:deckcheckExecutable @CliArguments 2>&1)
    $deckcheckExit = $LASTEXITCODE
    $deckcheckText = ($deckcheckOutput | ForEach-Object { $_.ToString() }) -join "`n"
    if ($deckcheckExit -ne $ExpectedExit) {
        throw "$Name returned $deckcheckExit (expected $ExpectedExit).`n$deckcheckText"
    }
    foreach ($deckcheckPattern in $Patterns) {
        if ($deckcheckText -notmatch $deckcheckPattern) {
            throw "$Name did not match $deckcheckPattern.`n$deckcheckText"
        }
    }
    $script:deckcheckPassed += 1
    Write-Output "PASS $Name"
}

function Assert-Deck {
    param(
        [string] $Name,
        [string] $Text,
        [int] $ExpectedExit,
        [string[]] $Patterns,
        [switch] $Bom
    )
    $deckcheckFile = Join-Path $script:deckcheckData ($Name + '.tsv')
    $deckcheckEncoding = $script:deckcheckUtf8
    if ($Bom) { $deckcheckEncoding = [System.Text.UTF8Encoding]::new($true) }
    [System.IO.File]::WriteAllText($deckcheckFile, $Text, $deckcheckEncoding)
    Assert-Run -Name $Name -CliArguments @($deckcheckFile) -ExpectedExit $ExpectedExit -Patterns $Patterns
}

Push-Location $deckcheckRoot
try {
    New-Item -ItemType Directory -Path 'build/test-data' -Force | Out-Null
    $script:deckcheckExecutable = Join-Path $deckcheckRoot 'build/deckcheck.exe'
    $script:deckcheckData = Join-Path $deckcheckRoot 'build/test-data'
    & $Compiler build src/main.salam --output=build/deckcheck.exe --log-level=error
    if ($LASTEXITCODE -ne 0) { throw 'Salam native build failed.' }

    Assert-Run 'help' @('--help') 0 @('Usage: deckcheck', 'Exit codes:')
    Assert-Run 'no-arguments-help' @() 0 @('Usage: deckcheck')
    Assert-Run 'excess-arguments' @('--help', 'extra') 2 @('exactly one')
    Assert-Run 'missing-file' @('build/test-data/never-created-deck.tsv') 2 @('cannot read deck')
    Assert-Run 'directory-path' @('fixtures') 2 @('cannot read deck')
    Assert-Run 'clean-fixture' @('fixtures/clean.tsv') 0 @('(?m)^Cards:\s+3$', '(?m)^Ignored lines:\s+1$', 'Result: PASS', 'Topic "\s*Arithmetic\s*":\s*2')
    Assert-Run 'broken-fixture' @('fixtures/broken.tsv') 1 @('line\s+2\s*: blank answer', 'line\s+3\s*: blank question', '(?m)^Malformed rows:\s+2$', '(?m)^Errors:\s+4$')
    Assert-Run 'duplicates-fixture' @('fixtures/duplicates.tsv') 1 @('line\s+3\s*: duplicate question; first seen at line\s+2', 'line\s+5\s*: duplicate question; first seen at line\s+2', '(?m)^Unique complete cards:\s+2$', 'Topics \(unique complete cards\):\s+2')
    Assert-Run 'mixed-topics-fixture' @('fixtures/mixed-topics.tsv') 0 @('Topic "\s*Time\s*":\s*2', 'No topic:\s+1', 'زبان')

    Assert-Deck 'no-final-newline' "Q`tA`tT" 0 @('(?m)^Cards:\s+1$', '(?m)^Ignored lines:\s+0$')
    Assert-Deck 'lf' "Q`tA`tT`n" 0 @('(?m)^Cards:\s+1$', '(?m)^Ignored lines:\s+0$')
    Assert-Deck 'crlf' "Q`tA`tT`r`n" 0 @('(?m)^Cards:\s+1$', '(?m)^Ignored lines:\s+0$', 'Topic "\s*T\s*":\s*1')
    Assert-Deck 'real-final-blank-line' "Q`tA`tT`n`n" 0 @('(?m)^Cards:\s+1$', '(?m)^Ignored lines:\s+1$')
    Assert-Deck 'physical-line-numbers' "# comment`n`nQ`tA`tT`nBad`t`tT" 1 @('line\s+4\s*: blank answer', '(?m)^Ignored lines:\s+2$')
    Assert-Deck 'bom-crlf' "# comment`r`nQ`tA`tT`r`nBad`t`tT`r`n" 1 @('line\s+3\s*: blank answer', '(?m)^Cards:\s+2$', '(?m)^Ignored lines:\s+1$') -Bom
    Assert-Deck 'bom-first-question' "Q`tA`tT`nq`tB`tU" 1 @('line\s+2\s*: duplicate question; first seen at line\s+1', '(?m)^Unique complete cards:\s+1$') -Bom
    Assert-Deck 'leading-and-adjacent-empty-fields' "`tA`tT`nQ`t`tT`n `t `tT" 1 @('(?m)^Blank questions:\s+2$', '(?m)^Blank answers:\s+2$', '(?m)^Errors:\s+4$', '(?m)^Malformed rows:\s+0$')
    Assert-Deck 'all-empty-tsv-fields' "Q`tA`tT`n`t`t" 1 @('line\s+2\s*: blank question', 'line\s+2\s*: blank answer', '(?m)^Cards:\s+2$', '(?m)^Ignored lines:\s+0$')
    Assert-Deck 'empty-topic' "Q`tA`t" 0 @('No topic:\s+1', '(?m)^Malformed rows:\s+0$')
    Assert-Deck 'extra-trailing-field' "Q`tA`tT`t" 1 @('expected 3 tab-separated fields; found\s+4', '(?m)^Malformed rows:\s+1$')
    Assert-Deck 'empty-deck' '' 1 @('deck contains no cards', '(?m)^Cards:\s+0$', 'Result: FAIL')
    Assert-Deck 'comments-only' "# first`n # second`n" 1 @('deck contains no cards', '(?m)^Ignored lines:\s+2$')
    Assert-Deck 'blanks-only' "`n  `n" 1 @('deck contains no cards', '(?m)^Ignored lines:\s+2$')
    Assert-Deck 'utf8-content' "سلام؟`tپاسخ 👋`tزبان" 0 @('(?m)^Cards:\s+1$', 'زبان')
    Assert-Deck 'unicode-full-fold' "École`tA`tÉtudes`nécole`tB`tElse`nStraße`tC`tétudes`nSTRASSE`tD`tElse" 1 @('(?m)^Duplicate questions:\s+2$', 'Topic "\s*Études\s*":\s*2', 'Topics \(unique complete cards\):\s+1')
    Assert-Deck 'invalid-does-not-shadow-complete' "Q`t`tWrong`nq`tA`tCorrect`nq`tB`tExcluded" 1 @('first seen at line\s+2', '(?m)^Unique complete cards:\s+1$', 'Topic "\s*Correct\s*":\s*1', 'Topics \(unique complete cards\):\s+1')
    Assert-Deck 'empty-topic-is-distinct' "Q1`tA`t`nQ2`tA`t(uncategorized)" 0 @('Topics \(unique complete cards\):\s+2', 'No topic:\s+1', 'Topic "\s*\(uncategorized\)\s*":\s*1')
    Assert-Deck 'embedded-nul' "Q`tA`tT`0`nQ2`tA2`tT2`n" 2 @('cannot read deck')
    Assert-Deck 'unicode-whitespace-fields' " `t `tT" 1 @('(?m)^Blank questions:\s+1$', '(?m)^Blank answers:\s+1$', '(?m)^Errors:\s+2$')
    Assert-Deck 'hash-in-answer' "`t#answer`tTopic`nQ`tA`tT" 1 @('line\s+1\s*: blank question', '(?m)^Cards:\s+2$', '(?m)^Ignored lines:\s+0$')
    Assert-Deck 'hash-in-topic' "`t`t#topic`nQ`tA`tT" 1 @('line\s+1\s*: blank question', 'line\s+1\s*: blank answer', '(?m)^Cards:\s+2$', '(?m)^Ignored lines:\s+0$')

    Write-Output "All $deckcheckPassed functional cases passed against the native executable."
}
finally {
    Pop-Location
}
