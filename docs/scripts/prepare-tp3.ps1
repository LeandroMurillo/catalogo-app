<#
.SYNOPSIS
Prepara las imagenes del TP2 para comenzar el TP3 desde el punto 1.
.DESCRIPTION
Con -Reset elimina los tres contenedores del TP3, catalogo-net y
catalogo-db-data (incluidos todos sus datos). Sin -Reset, se detiene si
existen esos recursos. No crea la red, el volumen ni los contenedores.
Conserva el codigo, las evidencias, otras imagenes y recursos ajenos al TP3.
.EXAMPLE
.\docs\scripts\prepare-tp3.ps1
.EXAMPLE
.\docs\scripts\prepare-tp3.ps1 -Reset
#>
[CmdletBinding()]
param([switch]$Reset)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Docker {
    param([string[]]$DockerArgs)
    & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Docker fallo (codigo $LASTEXITCODE): docker $($DockerArgs -join ' ')"
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Get-Command docker -ErrorAction Stop | Out-Null
$context = (Invoke-Docker @('context', 'show')).Trim()
$contextInfo = (Invoke-Docker @('context', 'inspect', $context) | ConvertFrom-Json)[0]
$endpoint = $contextInfo.Endpoints.docker.Host
if ($endpoint -notmatch '^(npipe|unix)://') {
    throw "Se requiere un Docker local. Contexto actual: $context ($endpoint)."
}
if ($env:DOCKER_HOST -or $env:DOCKER_CONTEXT) {
    throw 'Quita DOCKER_HOST y DOCKER_CONTEXT de esta sesion para usar el contexto local seleccionado.'
}
$osType = (Invoke-Docker @('info', '--format', '{{.OSType}}')).Trim()
if ($osType -ne 'linux') { throw 'Docker debe estar iniciado en modo Linux containers.' }
Write-Host "Contexto Docker: $context"

$targets = @('catalogo-frontend', 'catalogo-api', 'catalogo-db')
$containers = @(Invoke-Docker @('ps', '-a', '--format', '{{.Names}}'))
$existing = @($targets | Where-Object { $_ -in $containers })
$networks = @(Invoke-Docker @('network', 'ls', '--format', '{{.Name}}'))
$volumes = @(Invoke-Docker @('volume', 'ls', '--format', '{{.Name}}'))
$hasNetwork = 'catalogo-net' -in $networks
$hasVolume = 'catalogo-db-data' -in $volumes
if (($existing.Count -gt 0 -or $hasNetwork -or $hasVolume) -and -not $Reset) {
    throw 'Ya existen recursos del TP3. Usa -Reset para borrarlos, incluidos los datos de MongoDB, y empezar desde cero.'
}

# No tocar recursos compartidos con contenedores ajenos al TP3.
foreach ($filter in @('network=catalogo-net', 'volume=catalogo-db-data')) {
    $users = @(Invoke-Docker @('ps', '-a', '--filter', $filter, '--format', '{{.Names}}'))
    $foreign = @($users | Where-Object { $_ -notin $targets })
    if ($foreign.Count -gt 0) {
        throw "Hay contenedores ajenos al TP3 usando $filter : $($foreign -join ', '). No se modifico el entorno."
    }
}

# Construir primero: si falla una imagen, conservar el entorno existente.
Write-Host 'Construyendo catalogo-api:v1...'
Invoke-Docker @('build', '--build-arg', 'APP_VERSION=v1', '-t', 'catalogo-api:v1', (Join-Path $repoRoot 'backend')) | Out-Host
Write-Host 'Construyendo catalogo-api:v2...'
Invoke-Docker @('build', '--build-arg', 'APP_VERSION=v2', '-t', 'catalogo-api:v2', (Join-Path $repoRoot 'backend')) | Out-Host
Write-Host 'Construyendo catalogo-frontend:v1...'
Invoke-Docker @('build', '-t', 'catalogo-frontend:v1', (Join-Path $repoRoot 'frontend')) | Out-Host
Invoke-Docker @('pull', 'mongo:7') | Out-Host

foreach ($version in @('v1', 'v2')) {
    $actual = (Invoke-Docker @('run', '--rm', '--network', 'none', '--entrypoint', 'printenv', "catalogo-api:$version", 'APP_VERSION')).Trim()
    if ($actual -ne $version) { throw "Version incorrecta en catalogo-api:$version : $actual" }
}

if ($Reset) {
    Write-Host 'Reiniciando los recursos del TP3 (se eliminan los datos de MongoDB)...'
    foreach ($name in $existing) {
        Invoke-Docker @('stop', $name) | Out-Host
        # -v elimina los volumenes anonimos, no los volumenes nombrados.
        Invoke-Docker @('rm', '-v', $name) | Out-Host
    }
    if ($hasVolume) { Invoke-Docker @('volume', 'rm', 'catalogo-db-data') | Out-Host }
    if ($hasNetwork) { Invoke-Docker @('network', 'rm', 'catalogo-net') | Out-Host }
}

$remaining = @(Invoke-Docker @('ps', '-a', '--format', '{{.Names}}') | Where-Object { $_ -in $targets })
$remainingNetworks = @(Invoke-Docker @('network', 'ls', '--format', '{{.Name}}'))
$remainingVolumes = @(Invoke-Docker @('volume', 'ls', '--format', '{{.Name}}'))
if ($remaining.Count -gt 0 -or 'catalogo-net' -in $remainingNetworks -or 'catalogo-db-data' -in $remainingVolumes) {
    throw 'La verificacion final encontro recursos del TP3. Revisa el estado de Docker.'
}
Invoke-Docker @('image', 'ls', '--filter', 'reference=catalogo-*', '--format', 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}') | Out-Host
Write-Host 'Listo. Comienza por el punto 1 del TP3: crear catalogo-net y catalogo-db-data.'
