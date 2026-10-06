\xef\xbb\xbf# instalar-act-go.ps1  (actualización - requiere administrador)
# Uso: .\instalar-act-go.ps1 <version> <dir_instaladores> [<version_instalada>]
param(
    [Parameter(Position = 0)][string]$Version,
    [Parameter(Position = 1)][string]$DirInstaladores,
    [Parameter(Position = 2)][string]$GoVersion = '',   # opcional
    [switch]$Pausa                                       # pausa final (ventana elevada)
)

function Invoke-Actualizacion {
    $esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $esAdmin) {
        Write-Host "Se requieren permisos de ADMINISTRADOR para instalar GO"
        Write-Host "Intenta ejecutando PowerShell como administrador."
        return 1
    }

    $DIR    = $env:ProgramFiles
    $GOROOT = Join-Path $DIR 'Go'

    # Verificar si existe una versión anterior
    $confirm = ''
    if (Test-Path $GOROOT) {
        if ($GoVersion -eq '') {
            Write-Host "Se instalará la versión: go$Version!"
            $confirm = Read-Host "Desea eliminar la versión instalada? [SI (enter) ó NO]"
        }
        else {
            if ($Version -eq $GoVersion) {
                Write-Host "La versión: go$Version ya se encuentra instalada!"
                return 2
            }
            Write-Host "Se reemplazará la versión: go$GoVersion por go$Version!"
            $confirm = Read-Host "Desea eliminar la versión: $GoVersion? [SI (enter) ó NO]"
        }
        Write-Host "confirmación: $confirm"
        if ($confirm -in @('', 's', 'si')) {
            Remove-Item -Path $GOROOT -Recurse -Force
        }
        else {
            Write-Host "Actualización INTERRUMPIDA."
            return 2
        }
    }
    else {
        Write-Host "NO se encuentra versión de GO instalada!"
    }

    # Instalar versión indicada
    $arqSo = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $arq = switch ($arqSo) { 'ARM64' { 'arm64' } 'x86' { '386' } default { 'amd64' } }
    $archi = Join-Path $DirInstaladores "go$Version.windows-$arq.zip"

    Write-Host "Instalando versión: go$Version desde el archivo $archi ..."
    try {
        Expand-Archive -Path $archi -DestinationPath $DIR -Force -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: no se pudo extraer $archi"
        return 1
    }

    # Configurar entorno para Golang
    & (Join-Path $PSScriptRoot 'configurar-go.ps1')
    return 0
}

$codigo = Invoke-Actualizacion
if ($Pausa) { Read-Host "Presione Enter para cerrar" | Out-Null }
exit $codigo
