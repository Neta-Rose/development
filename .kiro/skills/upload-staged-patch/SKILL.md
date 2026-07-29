---
name: upload-staged-patch
description: Create a patch file from the repository's staged git changes, upload it to filebin.net, and return the share URL. Use when asked to share or export staged changes, publish the index as a patch, or hand a diff to someone else.
---

# Upload Staged Changes as a Patch

Wraps `.kiro/scripts/upload-staged-patch.ps1`, which:

1. Captures the index with `git diff --cached --binary` (staged changes only — unstaged
   edits and untracked files are excluded).
2. Writes it to `.kiro/patches/staged-<branch>-<timestamp>.patch`.
3. Uploads it with `POST https://filebin.net/<bin>/<filename>` and records the result in
   `.kiro/patches/last-upload.json`.

Optional argument: an existing filebin bin id to upload into. With no argument, a fresh
cryptographically random 20-character bin is created so the URL is unguessable.

Argument supplied by the user: `$ARGUMENTS`

## Workflow

1. Run from the repository root:

   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File .kiro\scripts\upload-staged-patch.ps1
   ```

   If the user supplied a bin id in `$ARGUMENTS`, append `-BinId <id>`. Other optional
   parameters: `-OutputDir <dir>`, `-BaseUrl <url>`, `-DeleteLocalPatch` (remove the local
   patch file after a successful upload).

   Do not quote the `-File` path — some shells pass the quotes through literally.

2. Interpret the exit code:

   | Code | Meaning | What to do |
   | ---- | ------- | ---------- |
   | 0 | Uploaded | Report the URLs from the script output. |
   | 3 | Nothing staged | Tell the user nothing is staged. Show `git status --short` so they can pick what to stage. Do **not** stage anything for them. |
   | 1 | Failed | Relay the HTTP status and response body the script printed. The local patch is still on disk — give its path. |

3. Report back with, at minimum:
   - the **bin URL** (`https://filebin.net/<bin>`) and the **direct file URL**,
   - the local patch path, the number of staged files, and the expiry timestamp.

   Reproduce the URLs exactly as printed; do not shorten or reconstruct them.

## Rules

- Never run `git add`, `git commit`, `git reset`, or `git stash` as part of this skill. It
  only reads the index. If nothing is staged, that is a result to report, not a problem to fix.
- Warn the user that filebin.net is a **public, unauthenticated** host: anyone with the URL
  can download or delete the patch, and the patch contains the staged diff verbatim,
  including any secrets that happen to be staged. Bins expire after about 7 days.
- If the staged diff touches files that commonly hold credentials (`.env*`, `*.pem`, `*.key`,
  `credentials*`, `*secret*`), call that out **before** reporting the URL, and offer to delete
  the upload with `curl -X DELETE <file URL>`.
