$ErrorActionPreference = 'Stop'

$requiredDirectories = @(
    $env:RUN_ROOT,
    $env:CHECKOUT_ROOT,
    $env:RESULTS_ROOT
)

foreach ($directory in $requiredDirectories) {
    if ([string]::IsNullOrWhiteSpace($directory)) {
        throw 'RUN_ROOT, CHECKOUT_ROOT, and RESULTS_ROOT must be defined before the workflow starts.'
    }

    New-Item -ItemType Directory -Force -Path $directory | Out-Null
}

if ([string]::IsNullOrWhiteSpace($env:PROMPT_FILE)) {
    throw 'PROMPT_FILE must be defined before the workflow starts.'
}

if (-not (Test-Path -LiteralPath $env:PROMPT_FILE)) {
    throw "Prompt file not found in run directory: $($env:PROMPT_FILE)"
}

Set-Content -Path (Join-Path $env:RUN_ROOT 'status.txt') -Value 'initialized'
Write-Host "Initialized run directories under $($env:RUN_ROOT)"