\xef\xbb\xbf# actualizar-go.ps1
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

# Configuración de usuario
$HOMEGO  = Join-Path $HOME 'go'
$HOMEGOI = Join-Path $HOMEGO 'instaladores'
foreach ($sub in 'bin', 'src', 'instaladores') {
    $d = Join-Path $HOMEGO $sub
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
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

# Versión actualmente instalada (vacía si Go no está instalado)
$goversion = ''
if (Get-Command go -ErrorAction SilentlyContinue) {
    $salida = (& go version) -join ' '
    if ($salida -match 'go version go(\S+)') { $goversion = $Matches[1] }
}

# Instalar versión descargada (requiere elevación, equivalente a sudo)
Write-Host "Se requieren permisos para continuar, confirme la elevación (UAC)."
$script = Join-Path $PSScriptRoot 'instalar-act-go.ps1'
$argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`"",
                '-Version', $Version, '-DirInstaladores', "`"$HOMEGOI`"")
if ($goversion) { $argumentos += @('-GoVersion', $goversion) }
$argumentos += '-Pausa'

try {
    $proc = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $argumentos `
                          -Verb RunAs -Wait -PassThru -ErrorAction Stop
}
catch {
    Write-Host "Instalación FALLIDA. (Elevación cancelada o no disponible)"
    exit 1
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
