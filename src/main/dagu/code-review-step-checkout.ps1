$ErrorActionPreference = 'Stop'

function Split-List {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @(
        $Value -split "`r?`n|;|," |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
}

function Get-RepoName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoUrl
    )

    $repoName = [System.IO.Path]::GetFileName($RepoUrl)
    if ($repoName.EndsWith('.git')) {
        $repoName = $repoName.Substring(0, $repoName.Length - 4)
    }

    return $repoName
}

function Parse-RepoSpec {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Entry,
        [AllowNull()]
        [string]$FallbackBranch
    )

    $normalized = $Entry.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw 'Repository entry must not be empty.'
    }

    $branch = $FallbackBranch
    $repoUrl = $normalized
    if ($normalized -match '^(?<url>.+?\.git):(?<branch>.+)$') {
        $repoUrl = $matches.url.Trim()
        $branch = $matches.branch.Trim()
    }

    return [pscustomobject]@{
        Url = $repoUrl
        Branch = $branch
    }
}

function Invoke-Git {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    Write-Host ("git " + ($Arguments -join ' '))
    & git @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required and was not found in PATH.'
}

if ([string]::IsNullOrWhiteSpace($env:MAIN_REPO_URL)) {
    throw 'MAIN_REPO_URL must be provided.'
}

if ([string]::IsNullOrWhiteSpace($env:CHECKOUT_ROOT)) {
    throw 'CHECKOUT_ROOT must be provided.'
}

$secondaryRepoEntries = Split-List -Value $env:SECONDARY_REPOS
$secondaryBranchEntries = Split-List -Value $env:SECONDARY_REPO_BRANCHES

if ($secondaryBranchEntries.Count -gt 0 -and $secondaryRepoEntries.Count -ne $secondaryBranchEntries.Count) {
    throw 'SECONDARY_REPOS and SECONDARY_REPO_BRANCHES must contain the same number of items when separate branch lists are used.'
}

$repos = New-Object System.Collections.Generic.List[object]
$repos.Add((Parse-RepoSpec -Entry $env:MAIN_REPO_URL -FallbackBranch $env:MAIN_REPO_BRANCH))

for ($i = 0; $i -lt $secondaryRepoEntries.Count; $i++) {
    $fallbackBranch = $null
    if ($i -lt $secondaryBranchEntries.Count) {
        $fallbackBranch = $secondaryBranchEntries[$i]
    }

    $repos.Add((Parse-RepoSpec -Entry $secondaryRepoEntries[$i] -FallbackBranch $fallbackBranch))
}

$usedRepoDirs = @{}
$repoDetails = New-Object System.Collections.Generic.List[object]

foreach ($repo in $repos) {
    $repoName = Get-RepoName -RepoUrl $repo.Url
    $targetName = $repoName
    if ($usedRepoDirs.ContainsKey($targetName)) {
        $usedRepoDirs[$targetName] += 1
        $targetName = '{0}-{1}' -f $repoName, $usedRepoDirs[$targetName]
    } else {
        $usedRepoDirs[$targetName] = 0
    }

    $targetDir = Join-Path $env:CHECKOUT_ROOT $targetName
    Write-Host "Cloning $($repo.Url) into $targetDir"
    Invoke-Git clone $repo.Url $targetDir

    if (-not [string]::IsNullOrWhiteSpace($repo.Branch)) {
        Push-Location $targetDir
        try {
            Write-Host "Checking out branch $($repo.Branch) in $targetDir"
            Invoke-Git checkout $repo.Branch
        } finally {
            Pop-Location
        }
    }

    $repoDetails.Add([pscustomobject]@{
        Name = $targetName
        Url = $repo.Url
        Branch = $repo.Branch
        Directory = $targetDir
    })
}

$repoDetails | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $env:RUN_ROOT 'repositories.json')
Set-Content -Path (Join-Path $env:RUN_ROOT 'status.txt') -Value 'checked-out'
Write-Host "Checked out $($repoDetails.Count) repositories into $($env:CHECKOUT_ROOT)"