param(
    [string]$WorkflowName = 'code-review',
    [string]$MainRepoUrl = $env:MAIN_REPO_URL,
    [string]$MainRepoBranch = $env:MAIN_REPO_BRANCH,
    [string]$SecondaryRepos = $env:SECONDARY_REPOS,
    [string]$SecondaryRepoBranches = $env:SECONDARY_REPO_BRANCHES,
    [string]$PromptFile = $env:PROMPT_FILE,
    [string]$CursorCommand = $env:CURSOR_COMMAND
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command dagu -ErrorAction SilentlyContinue)) {
    throw 'dagu is required and was not found in PATH.'
}

if ([string]::IsNullOrWhiteSpace($MainRepoUrl)) {
    throw 'MAIN_REPO_URL must be provided.'
}

$workflowRoot = $PSScriptRoot
$workflowFile = Join-Path $workflowRoot ($WorkflowName + '.yaml')
if (-not (Test-Path -LiteralPath $workflowFile)) {
    throw "Workflow file not found: $workflowFile"
}

if ([string]::IsNullOrWhiteSpace($PromptFile)) {
    $PromptFile = Join-Path $workflowRoot 'PROMPT.md'
}

if (-not (Test-Path -LiteralPath $PromptFile)) {
    throw "Prompt file not found: $PromptFile"
}

$runsRoot = Join-Path $workflowRoot 'runs'
$runId = [guid]::NewGuid().ToString()
$runRoot = Join-Path $runsRoot $runId
$checkoutRoot = Join-Path $runRoot 'checkout'
$resultsRoot = Join-Path $runRoot 'results'
$copiedPromptFile = Join-Path $runRoot 'PROMPT.md'
$resultFile = Join-Path $resultsRoot 'review.md'

New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
Copy-Item -LiteralPath $PromptFile -Destination $copiedPromptFile -Force

$env:WORKFLOW_DIR = $workflowRoot
$env:RUN_ID = $runId
$env:RUN_ROOT = $runRoot
$env:CHECKOUT_ROOT = $checkoutRoot
$env:RESULTS_ROOT = $resultsRoot
$env:RESULT_FILE = $resultFile
$env:PROMPT_FILE = $copiedPromptFile
$env:MAIN_REPO_URL = $MainRepoUrl
$env:MAIN_REPO_BRANCH = $MainRepoBranch
$env:SECONDARY_REPOS = $SecondaryRepos
$env:SECONDARY_REPO_BRANCHES = $SecondaryRepoBranches
$env:CURSOR_COMMAND = $CursorCommand

Set-Content -Path (Join-Path $runRoot 'run-id.txt') -Value $runId
Set-Content -Path (Join-Path $runRoot 'main-repo-url.txt') -Value $MainRepoUrl
Write-Host "Prepared workflow run: $runId"
Write-Host "Run root: $runRoot"
Write-Host "Prompt file: $copiedPromptFile"

& dagu run $workflowFile
if ($LASTEXITCODE -ne 0) {
    throw "dagu run failed with exit code $LASTEXITCODE"
}

Write-Host "Workflow completed. Result file: $resultFile"