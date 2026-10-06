\xef\xbb\xbf# instalar-go.ps1
# Uso: .\instalar-go.ps1 <version> [dir_trabajo]
# Ejemplo: .\instalar-go.ps1 1.21.5
#          .\instalar-go.ps1 1.21.5 C:\Users\usuario\go
param(
    [Parameter(Position = 0)][string]$Version,     # requerido
    [Parameter(Position = 1)][string]$DirTrabajo   # opcional
)

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($esAdmin) {
    Write-Host "Para instalar GO ejecute sin privilegios este script."
    Write-Host "Intenta con el comando: .\instalar-go.ps1 'x.x.x'"
    exit 1
}

# Validar parámetro 1
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "ERROR: verifique la versión ingresada y vuelva a intentar."
    exit 1
}

# Configuración de usuario
if ($DirTrabajo -and (Test-Path $DirTrabajo)) {
    foreach ($sub in 'bin', 'src', 'instaladores') {
        $d = Join-Path $DirTrabajo $sub
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    $HOMEGO  = Join-Path $DirTrabajo 'go'
    $HOMEGOI = Join-Path $DirTrabajo 'instaladores'
}
else {
    $HOMEGO  = Join-Path $HOME 'go'
    $HOMEGOI = Join-Path $HOMEGO 'instaladores'
    foreach ($sub in 'bin', 'src', 'instaladores') {
        $d = Join-Path $HOMEGO $sub
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
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
Write-Host "Se requieren permisos para continuar, confirme la elevación (UAC)."
$script = Join-Path $PSScriptRoot 'instalar-inst-go.ps1'
$argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$script`"",
                '-Version', $Version, '-DirInstaladores', "`"$HOMEGOI`"", '-Pausa')
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
