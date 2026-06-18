$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:RUN_ROOT)) {
    throw 'RUN_ROOT must be defined.'
}

if (-not [string]::IsNullOrWhiteSpace($env:CHECKOUT_ROOT) -and (Test-Path -LiteralPath $env:CHECKOUT_ROOT)) {
    Remove-Item -LiteralPath $env:CHECKOUT_ROOT -Recurse -Force
    Write-Host "Removed checkout directory: $($env:CHECKOUT_ROOT)"
}

Set-Content -Path (Join-Path $env:RUN_ROOT 'status.txt') -Value 'cleaned'
Write-Host "Run artifacts retained in $($env:RUN_ROOT)"