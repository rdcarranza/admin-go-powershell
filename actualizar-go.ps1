# actualizar-go.ps1
# Uso: .\actualizar-go.ps1 <version>
# Ejemplo: .\actualizar-go.ps1 1.21.5
param(
    [Parameter(Position = 0)][string]$Version
)

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($esAdmin) {
    Write-Host "Para actualizar GO ejecute sin privilegios este script."
    Write-Host "Intenta con el comando: .\actualizar-go.ps1 'x.x.x'"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "ERROR: verifique la versión ingresada y vuelva a intentar."
    exit 1
}

# Configuración de usuario
$HOMEGO  = Join-Path $HOME 'go'
$HOMEGOI = Join-Path $HOMEGO 'instaladores'
foreach ($sub in 'bin', 'src', 'instaladores') {
    $d = Join-Path $HOMEGO $sub
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# Versión actualmente instalada (vacía si Go no está instalado)
$goversion = ''
if (Get-Command go -ErrorAction SilentlyContinue) {
    $salida = (& go version) -join ' '
    if ($salida -match 'go version go(\S+)') { $goversion = $Matches[1] }
}

# Confirmar antes de descargar si ya hay una instalación
$GOROOT = Join-Path $env:ProgramFiles 'Go'
if (Test-Path $GOROOT) {
    if ($goversion -eq '') {
        Write-Host "Se instalará la versión: go$Version!"
        $resp = Read-Host "Desea eliminar la versión instalada? [SI (enter) ó NO]"
    }
    elseif ($Version -eq $goversion) {
        Write-Host "La versión: go$Version ya se encuentra instalada!"
        exit 2
    }
    else {
        Write-Host "Se reemplazará la versión: go$goversion por go$Version!"
        $resp = Read-Host "Desea eliminar la versión: $goversion? [SI (enter) ó NO]"
    }
    if ($resp -notin @('', 's', 'si')) {
        Write-Host "Actualización INTERRUMPIDA."
        exit 2
    }
}

# Descargar instalador
& (Join-Path $PSScriptRoot 'descargar-go.ps1') -Version $Version -DirInstaladores $HOMEGOI
if ($LASTEXITCODE -eq 0) {
    Write-Host "Descarga COMPLETA"
}
else {
    Write-Host "Descarga FALLIDA"
    exit 1
}

# Instalar versión descargada (requiere elevación, equivalente a sudo)
$log = Join-Path $env:TEMP ("admin-go-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$script = Join-Path $PSScriptRoot 'instalar-act-go.ps1'
$argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`"",
                '-Version', $Version, '-DirInstaladores', "`"$HOMEGOI`"",
                '-Confirmado', '-LogFile', "`"$log`"")

Write-Host "Se requieren permisos para continuar, confirme la elevación (UAC)."
Write-Host "Instalando en segundo plano, puede tardar unos segundos..."
try {
    $proc = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argumentos `
                          -WindowStyle Hidden -Verb RunAs -Wait -PassThru -ErrorAction Stop
}
catch {
    Write-Host "Instalación FALLIDA. (Elevación cancelada o no disponible)"
    exit 1
}

# Mostrar lo que informó el proceso elevado
if (Test-Path $log) {
    Get-Content $log -Encoding UTF8 | ForEach-Object { Write-Host "  $_" }
    Remove-Item $log -Force -ErrorAction SilentlyContinue
}

if ($proc.ExitCode -eq 0) {
    Write-Host "Instalación COMPLETA."
}
else {
    Write-Host "Instalación FALLIDA."
    exit 1
}

Write-Host "Abre una nueva terminal para verificar la instalación o actualización!"
exit 0
