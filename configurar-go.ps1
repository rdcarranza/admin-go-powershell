# configurar-go.ps1
# Agrega el directorio bin de Go al PATH del sistema. Requiere privilegios de administrador.

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host "Se requieren permisos de ADMINISTRADOR para configurar GO."
    exit 1
}

$DIR    = $env:ProgramFiles
$GOROOT = Join-Path $DIR 'Go'
$GOBIN  = Join-Path $GOROOT 'bin'

$pathMaquina = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$entradas = $pathMaquina -split ';' | Where-Object { $_ -ne '' }

if ($entradas | Where-Object { $_.TrimEnd('\') -ieq $GOBIN }) {
    Write-Host "GO ya se encuentra configurado!"
}
else {
    $nuevoPath = (($entradas + $GOBIN) -join ';')
    [Environment]::SetEnvironmentVariable('Path', $nuevoPath, 'Machine')
    Write-Host "Se agregó $GOBIN al PATH del sistema."
}

# Actualizar el PATH de esta sesión y mostrar la versión
if (-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -ieq $GOBIN })) {
    $env:Path = "$env:Path;$GOBIN"
}
& (Join-Path $GOBIN 'go.exe') version

Write-Host "Finaliza correctamente la configuración de GO."
exit 0
