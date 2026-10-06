# admin-go-powershell

> Scripts de PowerShell para instalar y actualizar **Go** en Windows, o simplemente para saltar entre versiones.

Port a PowerShell del proyecto [admin-go-bash](https://github.com/rdcarranza/admin-go-bash), pensado para entornos **Windows**.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![Go](https://img.shields.io/badge/Go-cualquier%20versi%C3%B3n-00ADD8?logo=go&logoColor=white)
![Platform](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)
![License](https://img.shields.io/badge/license-AGPL--3.0-blue)

---

## Características

- Instala cualquier versión de Go indicando solo el número (`1.21.5`).
- Actualiza o cambia de versión reemplazando la instalada, con confirmación previa.
- Descarga el `.zip` oficial desde [go.dev/dl](https://go.dev/dl/).
- Detecta la arquitectura automáticamente (`amd64`, `arm64` o `386`).
- Crea el directorio de trabajo (`bin`, `src`, `instaladores`) en `%USERPROFILE%\go`.
- Agrega Go al `PATH` del sistema.
- Solicita elevación (UAC) solo cuando hace falta, el equivalente a `sudo`.

## Requisitos

- Windows 10 / 11
- PowerShell 5.1 o superior (incluido en Windows) o PowerShell 7+
- Conexión a internet
- Permisos de administrador (se piden por UAC durante la instalación)

## Instalación de los scripts

```powershell
git clone https://github.com/<tu-usuario>/admin-go-powershell.git
cd admin-go-powershell
```

Si Windows bloquea la ejecución de scripts, tenés dos opciones:

```powershell
# Opción 1: desbloquear los archivos descargados
Get-ChildItem *.ps1 | Unblock-File

# Opción 2: ejecutar saltando la política solo para ese comando
powershell -ExecutionPolicy Bypass -File .\instalar-go.ps1 1.21.5
```

## Uso

> Ejecutá los scripts principales **sin** privilegios de administrador. Ellos mismos piden la elevación cuando corresponde.

### Instalación

```powershell
.\instalar-go.ps1 <version>
```

Crea automáticamente el directorio de trabajo en `%USERPROFILE%\go`.

```powershell
.\instalar-go.ps1 1.21.5
```

### Instalación con directorio de trabajo propio

```powershell
.\instalar-go.ps1 <version> <dir_trabajo>
```

```powershell
.\instalar-go.ps1 1.21.5 C:\Users\usuario\go
```

### Actualización

```powershell
.\actualizar-go.ps1 <version>
```

```powershell
.\actualizar-go.ps1 1.22.1
```

Si ya tenés instalada la misma versión, el script te avisa y no hace cambios. Si es distinta, pide confirmación antes de reemplazarla.

Al terminar, abrí una **terminal nueva** para que se aplique el `PATH` actualizado y verificá con:

```powershell
go version
```

## Estructura del proyecto

| Script | Descripción | Admin |
| --- | --- | :---: |
| `instalar-go.ps1` | Punto de entrada para una instalación nueva. | No |
| `actualizar-go.ps1` | Punto de entrada para actualizar o cambiar de versión. | No |
| `descargar-go.ps1` | Descarga el `.zip` de la versión indicada. | No |
| `instalar-inst-go.ps1` | Instala Go (instalación nueva). Lo invoca `instalar-go.ps1`. | Sí |
| `instalar-act-go.ps1` | Reemplaza la versión instalada. Lo invoca `actualizar-go.ps1`. | Sí |
| `configurar-go.ps1` | Agrega `Go\bin` al `PATH` del sistema. | Sí |

### Flujo

```text
instalar-go.ps1 ──► descargar-go.ps1
        │
        └─ (UAC) ─► instalar-inst-go.ps1 ──► configurar-go.ps1

actualizar-go.ps1 ─► descargar-go.ps1
        │
        └─ (UAC) ─► instalar-act-go.ps1 ───► configurar-go.ps1
```

## Rutas utilizadas

| Qué | Dónde |
| --- | --- |
| Go instalado | `C:\Program Files\Go` |
| Instaladores descargados | `%USERPROFILE%\go\instaladores` |
| Directorio de trabajo | `%USERPROFILE%\go` (`bin`, `src`) |

## Diferencias con la versión bash

| Linux (bash) | Windows (PowerShell) |
| --- | --- |
| `go<v>.linux-amd64.tar.gz` | `go<v>.windows-<arq>.zip` |
| `wget` | `Invoke-WebRequest` |
| `tar xzf` | `Expand-Archive` |
| `/usr/local/go` | `C:\Program Files\Go` |
| `/etc/profile.d/go.sh` | `PATH` de la máquina (variable de entorno) |
| `sudo` | Elevación por UAC (`Start-Process -Verb RunAs`) |

## Solución de problemas

**"La ejecución de scripts está deshabilitada en este sistema"**
Usá `Unblock-File` o `-ExecutionPolicy Bypass`, como se explica arriba.

**"ERROR: en la descarga del instalador"**
Revisá que la versión exista en [go.dev/dl](https://go.dev/dl/) y que tengas conexión.

**`go` no se reconoce como comando**
Cerrá y abrí una terminal nueva. El `PATH` del sistema solo se recarga en sesiones nuevas.

**La ventana de administrador se cierra enseguida**
No debería: espera un Enter al final. Si falla antes, ejecutá el script elevado manualmente desde una consola de administrador para ver el error.

## Licencia

Distribuido bajo la licencia **AGPL-3.0**, igual que el proyecto original. Ver [LICENSE](https://github.com/rdcarranza/admin-go-bash/blob/main/LICENSE).

## Créditos

Proyecto original: [rdcarranza/admin-go-bash](https://github.com/rdcarranza/admin-go-bash).