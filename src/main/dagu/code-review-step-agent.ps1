$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:RUN_ROOT) -or [string]::IsNullOrWhiteSpace($env:CHECKOUT_ROOT)) {
    throw 'RUN_ROOT and CHECKOUT_ROOT must be defined.'
}

if ([string]::IsNullOrWhiteSpace($env:PROMPT_FILE) -or -not (Test-Path -LiteralPath $env:PROMPT_FILE)) {
    throw 'PROMPT_FILE must point to a copied prompt inside the workflow run directory.'
}

if ([string]::IsNullOrWhiteSpace($env:RESULT_FILE)) {
    throw 'RESULT_FILE must be defined.'
}

New-Item -ItemType Directory -Force -Path (Split-Path -Path $env:RESULT_FILE -Parent) | Out-Null

$repositorySummary = ''
$repositoriesFile = Join-Path $env:RUN_ROOT 'repositories.json'
if (Test-Path -LiteralPath $repositoriesFile) {
    $repositories = Get-Content -LiteralPath $repositoriesFile -Raw | ConvertFrom-Json
    $repositorySummary = ($repositories | ForEach-Object {
        $branchLabel = if ([string]::IsNullOrWhiteSpace($_.Branch)) { 'default branch' } else { $_.Branch }
        "- $($_.Name): $($_.Url) [$branchLabel] => $($_.Directory)"
    }) -join [Environment]::NewLine
}

$promptText = @(
    Get-Content -LiteralPath $env:PROMPT_FILE -Raw
    ''
    'Context for this workflow run:'
    "- Run root: $($env:RUN_ROOT)"
    "- Checkout root: $($env:CHECKOUT_ROOT)"
    "- Result markdown file: $($env:RESULT_FILE)"
    '- Repositories:'
    $repositorySummary
    ''
    'Write the final review in markdown.'
) -join [Environment]::NewLine

Push-Location $env:RUN_ROOT
try {
    if (-not [string]::IsNullOrWhiteSpace($env:CURSOR_COMMAND)) {
        Write-Host "Running custom Cursor command: $($env:CURSOR_COMMAND)"
        Invoke-Expression $env:CURSOR_COMMAND | Tee-Object -FilePath $env:RESULT_FILE
        if ($LASTEXITCODE -ne 0) {
            throw "Cursor command failed with exit code $LASTEXITCODE"
        }
    } else {
        if (-not (Get-Command agent -ErrorAction SilentlyContinue)) {
            throw 'Cursor agent executable `agent` was not found in PATH. Provide CURSOR_COMMAND or install Cursor CLI.'
        }

        Write-Host 'Running Cursor agent review...'
        & agent -p $promptText --force --trust --output-format text | Tee-Object -FilePath $env:RESULT_FILE
        if ($LASTEXITCODE -ne 0) {
            throw "Cursor agent failed with exit code $LASTEXITCODE"
        }
    }
} finally {
    Pop-Location
}

Set-Content -Path (Join-Path $env:RUN_ROOT 'status.txt') -Value 'reviewed'
Write-Host "Review saved to $($env:RESULT_FILE)"