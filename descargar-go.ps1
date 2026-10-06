# descargar-go.ps1
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

$url       = "https://go.dev/dl/$archi"
$diriArchi = Join-Path $DirInstaladores $archi
$temporal  = "$diriArchi.part"

Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Write-Host "Descargando $archi"
Write-Host "  desde:   $url"
Write-Host "  destino: $diriArchi"

$cliente = $null; $respuesta = $null; $entrada = $null; $salida = $null
$ok = $false
$actividad = "Descargando go$Version"

try {
    $cliente = New-Object System.Net.Http.HttpClient
    $cliente.Timeout = [TimeSpan]::FromMinutes(30)

    # ResponseHeadersRead: empieza a recibir sin cargar todo en memoria
    $respuesta = $cliente.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
    $respuesta.EnsureSuccessStatusCode() | Out-Null

    $total = $respuesta.Content.Headers.ContentLength
    if ($total) { Write-Host ("  tamaño:  {0:N1} MB" -f ($total / 1MB)) }

    $entrada = $respuesta.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
    $salida  = [System.IO.File]::Create($temporal)
    $buffer  = New-Object byte[] 81920
    $leidos  = 0L
    $reloj   = [System.Diagnostics.Stopwatch]::StartNew()

    while (($n = $entrada.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $salida.Write($buffer, 0, $n)
        $leidos += $n
        if ($reloj.ElapsedMilliseconds -ge 100) {
            $reloj.Restart()
            if ($total) {
                $pct = [int](($leidos * 100) / $total)
                Write-Progress -Activity $actividad -PercentComplete $pct `
                    -Status ("{0:N1} MB de {1:N1} MB ({2}%)" -f ($leidos / 1MB), ($total / 1MB), $pct)
            }
            else {
                Write-Progress -Activity $actividad -Status ("{0:N1} MB descargados" -f ($leidos / 1MB))
            }
        }
    }
    $ok = $true
}
catch {
    $ok = $false
}
finally {
    if ($salida)    { $salida.Dispose() }
    if ($entrada)   { $entrada.Dispose() }
    if ($respuesta) { $respuesta.Dispose() }
    if ($cliente)   { $cliente.Dispose() }
    Write-Progress -Activity $actividad -Completed
}

if ($ok -and (Test-Path $temporal)) {
    Move-Item -Path $temporal -Destination $diriArchi -Force
    Write-Host "Descarga finalizada correctamente!"
    exit 0
}
else {
    if (Test-Path $temporal) { Remove-Item $temporal -Force -ErrorAction SilentlyContinue }
    Write-Host "ERROR: en la descarga del instalador, verifique la versión ingresada y vuelva a intentar"
    exit 1
}
