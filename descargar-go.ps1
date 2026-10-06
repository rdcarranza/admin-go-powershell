\xef\xbb\xbf# descargar-go.ps1
# Uso: .\descargar-go.ps1 <version> [dir_instaladores]
param(
    [Parameter(Position = 0)][string]$Version,          # requerido
    [Parameter(Position = 1)][string]$DirInstaladores   # opcional
)

# Verificar parámetro 1
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "ERROR: en la descarga del instalador, verifique la versión ingresada y vuelva a intentar"
    exit 1
}

# Arquitectura
$arqSo = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
$arq = switch ($arqSo) { 'ARM64' { 'arm64' } 'x86' { '386' } default { 'amd64' } }
$archi = "go$Version.windows-$arq.zip"

# Verificar parámetro 2
if ([string]::IsNullOrWhiteSpace($DirInstaladores)) {
    $DirInstaladores = Join-Path $HOME 'go\instaladores'
}
if (-not (Test-Path $DirInstaladores)) {
    New-Item -ItemType Directory -Path $DirInstaladores -Force | Out-Null
}

$url = "https://go.dev/dl/$archi"
$diriArchi = Join-Path $DirInstaladores $archi

try {
    $ProgressPreference = 'SilentlyContinue'   # acelera Invoke-WebRequest en PS 5.1
    Invoke-WebRequest -Uri $url -OutFile $diriArchi -UseBasicParsing -ErrorAction Stop
}
catch {
    if (Test-Path $diriArchi) { Remove-Item $diriArchi -Force -ErrorAction SilentlyContinue }
    Write-Host "ERROR: en la descarga del instalador, verifique la versión ingresada y vuelva a intentar"
    exit 1
}

if (Test-Path $diriArchi) {
    Write-Host "Descarga finalizada correctamente!"
    exit 0
}
else {
    Write-Host "ERROR: en la descarga del instalador, verifique la versión ingresada y vuelva a intentar"
    exit 1
}
