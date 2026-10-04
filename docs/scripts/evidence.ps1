$script:EvidenceFile = $null

function Set-EvidenceLog {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $repoRoot = git rev-parse --show-toplevel 2>$null

    if (-not $repoRoot) {
        throw "No estás dentro de un repositorio Git."
    }

    $evidenceDir = Join-Path $repoRoot "docs\evidence"

    if (-not (Test-Path $evidenceDir)) {
        New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
    }

    if (-not $Name.EndsWith(".txt")) {
        $Name = "$Name.txt"
    }

    $script:EvidenceFile = Join-Path $evidenceDir $Name

    Write-Host "Evidencia -> $script:EvidenceFile"
}


function Invoke-Evidence {
    param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$Command
    )

    if (-not $script:EvidenceFile) {
        throw "Primero debes seleccionar un archivo con: Set-EvidenceLog tp3"
    }

    $commandText = $Command.ToString().Trim()

    "`nPS> $commandText" |
    Tee-Object -FilePath $script:EvidenceFile -Append

    & $Command 2>&1 |
    Tee-Object -FilePath $script:EvidenceFile -Append
}

Set-Alias ev Invoke-Evidence