# instalar-act-go.ps1  (actualización - requiere administrador)
# Lo invoca actualizar-go.ps1. También se puede ejecutar a mano desde una consola de administrador.
# Uso: .\instalar-act-go.ps1 <version> <dir_instaladores> [<version_instalada>] [-Confirmado] [-LogFile <ruta>]
param(
    [Parameter(Position = 0)][string]$Version,
    [Parameter(Position = 1)][string]$DirInstaladores,
    [Parameter(Position = 2)][string]$GoVersion = '',   # opcional
    [switch]$Confirmado,                                 # ya se confirmó el reemplazo (no preguntar)
    [string]$LogFile                                     # si se indica, copia los mensajes a este archivo
)

function Escribir([string]$Mensaje) {
    Write-Host $Mensaje
    if ($LogFile) { Add-Content -Path $LogFile -Value $Mensaje -Encoding UTF8 }
}

function Invoke-Actualizacion {
    $esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $esAdmin) {
        Escribir "Se requieren permisos de ADMINISTRADOR para instalar GO"
        return 1
    }

    $DIR    = $env:ProgramFiles
    $GOROOT = Join-Path $DIR 'Go'

    $arqSo = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $arq = switch ($arqSo) { 'ARM64' { 'arm64' } 'x86' { '386' } default { 'amd64' } }
    $archi = Join-Path $DirInstaladores "go$Version.windows-$arq.zip"

    if (-not (Test-Path $archi)) {
        Escribir "ERROR: no se encuentra el instalador $archi"
        return 1
    }

    # Verificar si existe una versión anterior
    if (Test-Path $GOROOT) {
        if (-not $Confirmado) {
            if ($GoVersion -eq '') {
                Escribir "Se instalará la versión: go$Version!"
                $confirm = Read-Host "Desea eliminar la versión instalada? [SI (enter) ó NO]"
            }
            else {
                if ($Version -eq $GoVersion) {
                    Escribir "La versión: go$Version ya se encuentra instalada!"
                    return 2
                }
                Escribir "Se reemplazará la versión: go$GoVersion por go$Version!"
                $confirm = Read-Host "Desea eliminar la versión: $GoVersion? [SI (enter) ó NO]"
            }
            if ($confirm -notin @('', 's', 'si')) {
                Escribir "Actualización INTERRUMPIDA."
                return 2
            }
        }
        Escribir "Eliminando la versión anterior en $GOROOT ..."
        try { Remove-Item -Path $GOROOT -Recurse -Force -ErrorAction Stop }
        catch {
            Escribir "ERROR: no se pudo eliminar $GOROOT (¿hay procesos de Go en ejecución?)"
            return 1
        }
    }
    else {
        Escribir "NO se encuentra versión de GO instalada!"
    }

    # Instalar versión indicada
    Escribir "Instalando versión: go$Version desde el archivo $archi ..."
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($archi, $DIR)
    }
    catch {
        Escribir "ERROR: no se pudo extraer $archi"
        if (Test-Path $GOROOT) { Remove-Item -Path $GOROOT -Recurse -Force -ErrorAction SilentlyContinue }
        return 1
    }

    # Configurar entorno para Golang
    & (Join-Path $PSScriptRoot 'configurar-go.ps1') *>&1 | ForEach-Object { Escribir "$_" }
    return 0
}

try { $codigo = Invoke-Actualizacion }
catch { Escribir "ERROR: $($_.Exception.Message)"; $codigo = 1 }
exit $codigo
