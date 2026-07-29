<#
.SYNOPSIS
    Creates a patch file from the repository's staged git changes and uploads it
    to filebin.net, printing the resulting share URL.

.DESCRIPTION
    1. Runs `git diff --cached --binary` to capture everything currently in the
       index (staged changes only; unstaged edits and untracked files are ignored).
    2. Writes the patch to .kiro/patches/staged-<branch>-<timestamp>.patch
    3. Uploads it with POST https://filebin.net/<bin>/<filename>
       (API docs: https://filebin.net/api - the spec lives at https://filebin.net/api.yaml)
    4. Prints the bin URL and the direct file URL, and records both in
       .kiro/patches/last-upload.json

    PRIVACY WARNING: filebin.net is a public, anonymous file host. There is no
    authentication - anyone who knows or guesses the bin URL can download the
    patch or delete it. The patch contains your staged source changes verbatim,
    including any secrets, tokens or credentials that happen to be staged.
    Bins expire on their own (filebin's default is 7 days).

.PARAMETER BinId
    Bin to upload into. Defaults to a fresh cryptographically random 20-character
    id, which keeps the URL unguessable. Pass an existing bin id to add the patch
    to that bin instead.

.PARAMETER OutputDir
    Directory for the generated patch file. Defaults to <repo>/.kiro/patches.

.PARAMETER BaseUrl
    Filebin base URL. Defaults to https://filebin.net.

.PARAMETER DeleteLocalPatch
    Delete the local patch file after a successful upload. By default the patch is
    kept on disk under .kiro/patches.

.OUTPUTS
    Exit code 0 = uploaded, 1 = error, 3 = nothing staged (nothing uploaded).

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .kiro/scripts/upload-staged-patch.ps1

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .kiro/scripts/upload-staged-patch.ps1 -BinId myexistingbin
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string] $BinId,
    [string] $OutputDir,
    [string] $BaseUrl = 'https://filebin.net',
    # A switch rather than a [bool]: when the script is launched with
    # `powershell -File`, every argument arrives as a string and [bool]
    # parameters refuse to bind to strings.
    [switch] $DeleteLocalPatch
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # Invoke-RestMethod is very slow in PS 5.1 with the progress bar on

# Exit codes
$EXIT_OK      = 0
$EXIT_ERROR   = 1
$EXIT_NOTHING = 3

function Write-Section([string] $Text) {
    Write-Host ''
    Write-Host $Text
}

function Fail([string] $Message) {
    Write-Host ''
    Write-Host "ERROR: $Message"
    exit $EXIT_ERROR
}

<#
    Runs git and returns exit code, stdout and stderr separately.

    Native commands that write to stderr raise a terminating NativeCommandError
    while $ErrorActionPreference is 'Stop', which would abort the script on
    perfectly normal git conditions (an unborn branch, for example). This wrapper
    relaxes the preference for the duration of the call and hands back the streams
    so the caller can decide what is actually an error.
#>
function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]   $RepoPath,
        [Parameter(Mandatory = $true)][string[]] $GitArgs
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw  = $null
    $code = 0
    try {
        $raw  = & git -C $RepoPath @GitArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }

    $outLines = New-Object System.Collections.Generic.List[string]
    $errLines = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($raw)) {
        if ($null -eq $item) { continue }
        if ($item -is [System.Management.Automation.ErrorRecord]) {
            $errLines.Add([string] $item)
        } else {
            $outLines.Add([string] $item)
        }
    }

    [pscustomobject] @{
        ExitCode = $code
        Lines    = $outLines.ToArray()
        Out      = ($outLines -join "`n").Trim()
        Err      = ($errLines -join "`n").Trim()
    }
}

# ---------------------------------------------------------------------------
# 1. Locate the repository
# ---------------------------------------------------------------------------
# Derived from the script's own location (<repo>/.kiro/scripts/) so the script
# works no matter what the caller's working directory is.
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
    Fail 'git was not found on PATH.'
}

$topLevel = Invoke-Git -RepoPath $repoRoot -GitArgs @('rev-parse', '--show-toplevel')
if ($topLevel.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($topLevel.Out)) {
    Fail "'$repoRoot' is not inside a git working tree. $($topLevel.Err)"
}
$repoRoot = (Resolve-Path -LiteralPath $topLevel.Out).Path

# ---------------------------------------------------------------------------
# 2. Bail out early if the index is empty
# ---------------------------------------------------------------------------
# `git diff --cached --quiet` exits 0 when there is nothing staged, 1 when there is.
$stagedCheck = Invoke-Git -RepoPath $repoRoot -GitArgs @('diff', '--cached', '--quiet')
if ($stagedCheck.ExitCode -eq 0) {
    Write-Host 'No staged changes found - nothing to upload.'
    Write-Host "Stage something first, e.g. 'git add <path>', then run this again."
    exit $EXIT_NOTHING
}
if ($stagedCheck.ExitCode -gt 1) {
    Fail "'git diff --cached' failed with exit code $($stagedCheck.ExitCode). $($stagedCheck.Err)"
}

# ---------------------------------------------------------------------------
# 3. Build the patch file name
# ---------------------------------------------------------------------------
# symbolic-ref resolves the branch even on an unborn branch (a repo with no
# commits yet), where rev-parse HEAD would fail.
$branch  = 'unknown'
$symbolic = Invoke-Git -RepoPath $repoRoot -GitArgs @('symbolic-ref', '--short', 'HEAD')
if ($symbolic.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($symbolic.Out)) {
    $branch = $symbolic.Out
} else {
    # Detached HEAD - fall back to the short commit sha.
    $shortSha = Invoke-Git -RepoPath $repoRoot -GitArgs @('rev-parse', '--short', 'HEAD')
    if ($shortSha.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($shortSha.Out)) {
        $branch = "detached-$($shortSha.Out)"
    }
}

$safeBranch = ($branch.Trim() -replace '[^A-Za-z0-9._-]', '-')
if ($safeBranch.Length -gt 40) { $safeBranch = $safeBranch.Substring(0, 40) }
if ([string]::IsNullOrWhiteSpace($safeBranch)) { $safeBranch = 'unknown' }

$patchName = 'staged-{0}-{1}.patch' -f $safeBranch, (Get-Date -Format 'yyyyMMdd-HHmmss')

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot '.kiro\patches'
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path
$patchPath = Join-Path $OutputDir $patchName

# ---------------------------------------------------------------------------
# 4. Generate the patch
# ---------------------------------------------------------------------------
# --binary          include binary file changes so the patch applies cleanly
# --output          let git write the bytes itself, avoiding any PowerShell
#                   re-encoding of the diff (which would corrupt it)
# --src/dst-prefix  pin the a/ b/ prefixes so `git apply` works even if the user
#                   has diff.noprefix or diff.mnemonicPrefix configured
$diff = Invoke-Git -RepoPath $repoRoot -GitArgs @(
    'diff', '--cached', '--binary', '--no-color',
    '--src-prefix=a/', '--dst-prefix=b/', "--output=$patchPath"
)
if ($diff.ExitCode -ne 0) {
    Fail "'git diff --cached' failed with exit code $($diff.ExitCode). $($diff.Err)"
}
if (-not (Test-Path -LiteralPath $patchPath)) {
    Fail "git did not produce a patch file at '$patchPath'. $($diff.Err)"
}

$patchItem = Get-Item -LiteralPath $patchPath
if ($patchItem.Length -eq 0) {
    Remove-Item -LiteralPath $patchPath -Force
    Fail 'The generated patch was empty; nothing was uploaded.'
}

$nameOnly    = Invoke-Git -RepoPath $repoRoot -GitArgs @('diff', '--cached', '--name-only')
$stagedFiles = @($nameOnly.Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$fileCount   = $stagedFiles.Count
$sha256      = (Get-FileHash -LiteralPath $patchPath -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Section 'Patch created'
Write-Host "  file    : $patchPath"
Write-Host ("  size    : {0:N0} bytes ({1} staged file(s))" -f $patchItem.Length, $fileCount)
Write-Host "  sha256  : $sha256"

# The patch is about to be published to a public host, so surface staged paths
# that commonly carry credentials. This is a heads-up, not a block.
$secretPatterns = @(
    '(^|/)\.env',
    '\.pem$', '\.p12$', '\.pfx$', '\.key$', '\.keystore$', '\.jks$',
    'id_rsa', 'id_ed25519',
    'credential', 'secret', 'password', 'apikey', 'api[_-]key', 'token',
    '\.npmrc$', '\.netrc$', 'service[_-]account.*\.json$'
)
$suspicious = @($stagedFiles | Where-Object {
    $path = $_
    @($secretPatterns | Where-Object { $path -match $_ }).Count -gt 0
})
if ($suspicious.Count -gt 0) {
    Write-Host ''
    Write-Host 'WARNING: these staged paths look like they could contain credentials:'
    foreach ($s in $suspicious) { Write-Host "    $s" }
    Write-Host '  They will be included in the patch and published publicly. Ctrl+C now to abort.'
    Start-Sleep -Seconds 4
}

# ---------------------------------------------------------------------------
# 5. Pick a bin
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($BinId)) {
    # The bin id is the only thing protecting the upload, so make it unguessable.
    $alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    $bytes    = New-Object 'byte[]' 20
    $rng      = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }

    $builder = New-Object System.Text.StringBuilder
    foreach ($b in $bytes) { [void] $builder.Append($alphabet[$b % $alphabet.Length]) }
    $BinId = $builder.ToString()
} else {
    $BinId = $BinId.Trim()
    if ($BinId.Length -lt 8) {
        Fail "Bin id '$BinId' is too short; filebin requires at least 8 characters."
    }
}

$BaseUrl = $BaseUrl.TrimEnd('/')
$fileUrl = '{0}/{1}/{2}' -f $BaseUrl, [uri]::EscapeDataString($BinId), [uri]::EscapeDataString($patchName)
$binUrl  = '{0}/{1}'     -f $BaseUrl, [uri]::EscapeDataString($BinId)

# ---------------------------------------------------------------------------
# 6. Upload
# ---------------------------------------------------------------------------
Write-Section "Uploading to $BaseUrl ..."

try {
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # Older frameworks may not expose Tls12; the platform default still applies.
}

$response = $null
try {
    # Content-SHA256 is optional but lets filebin reject a corrupted transfer.
    $response = Invoke-RestMethod -Uri $fileUrl `
                                  -Method Post `
                                  -InFile $patchPath `
                                  -ContentType 'application/octet-stream' `
                                  -Headers @{ 'Content-SHA256' = $sha256 } `
                                  -TimeoutSec 300
} catch {
    $status      = ''
    $body        = ''
    $webResponse = $null

    if ($_.Exception -and ($_.Exception | Get-Member -Name Response -ErrorAction SilentlyContinue)) {
        $webResponse = $_.Exception.Response
    }
    if ($webResponse) {
        try { $status = [int] $webResponse.StatusCode } catch { }
        try {
            $reader = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
            $body   = $reader.ReadToEnd().Trim()
            $reader.Dispose()
        } catch { }
    }

    Write-Host ''
    Write-Host 'ERROR: upload failed.'
    Write-Host "  url         : $fileUrl"
    if ($status) { Write-Host "  http status : $status" }
    if ($body)   {
        if ($body.Length -gt 500) { $body = $body.Substring(0, 500) + ' ...' }
        Write-Host "  response    : $body"
    }
    Write-Host "  message     : $($_.Exception.Message)"
    Write-Host ''
    Write-Host "The patch is still on disk: $patchPath"
    exit $EXIT_ERROR
}

# ---------------------------------------------------------------------------
# 7. Report
# ---------------------------------------------------------------------------
$expiresAt = ''
$sizeLabel = ''
if ($response) {
    if ($response.PSObject.Properties['bin'] -and $response.bin -and
        $response.bin.PSObject.Properties['expired_at']) {
        $expiresAt = [string] $response.bin.expired_at
    }
    if ($response.PSObject.Properties['file'] -and $response.file -and
        $response.file.PSObject.Properties['bytes_readable']) {
        $sizeLabel = [string] $response.file.bytes_readable
    }
}

Write-Section 'Upload complete'
Write-Host "  bin URL  : $binUrl"
Write-Host "  file URL : $fileUrl"
if ($sizeLabel) { Write-Host "  uploaded : $sizeLabel" }
if ($expiresAt) { Write-Host "  expires  : $expiresAt" }
Write-Host ''
Write-Host 'Apply it elsewhere with:'
Write-Host "  curl -L -o staged.patch `"$fileUrl`""
Write-Host '  git apply staged.patch'
Write-Host ''
Write-Host 'NOTE: this URL is public and unauthenticated - anyone with it can read or delete the patch.'
Write-Host "      Remove it again with: curl -X DELETE `"$fileUrl`""

$metadata = [ordered] @{
    bin_url      = $binUrl
    file_url     = $fileUrl
    bin          = $BinId
    filename     = $patchName
    branch       = $branch
    staged_files = $fileCount
    bytes        = $patchItem.Length
    sha256       = $sha256
    patch_path   = $patchPath
    expires_at   = $expiresAt
    uploaded_at  = (Get-Date).ToString('o')
}
$metadataPath = Join-Path $OutputDir 'last-upload.json'
$json = [pscustomobject] $metadata | ConvertTo-Json
# Write without a BOM so the file parses cleanly with any JSON reader.
[System.IO.File]::WriteAllText($metadataPath, $json, (New-Object System.Text.UTF8Encoding($false)))

if ($DeleteLocalPatch) {
    Remove-Item -LiteralPath $patchPath -Force
    Write-Host ''
    Write-Host "Local patch deleted (-DeleteLocalPatch). Details recorded in $metadataPath"
}

exit $EXIT_OK
