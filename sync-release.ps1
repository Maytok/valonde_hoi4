#Requires -Version 5.1
<#
.SYNOPSIS
  Sincroniza el repo de trabajo (GitCaraxes) con el repo distribuible (Caraxes).

.DESCRIPTION
  Copia desde el repo de trabajo hacia el repo distribuible SOLO los archivos
  necesarios para el mod de Hearts of Iron IV: las carpetas de contenido y
  descriptor.mod. Los archivos de desarrollo (.git, .vscode, .editorconfig,
  .gitattributes, .gitmessage, GITFLOW.md, etc.) nunca se copian.

  Las carpetas de contenido se sincronizan en modo espejo (/MIR): los archivos
  que se hayan borrado o renombrado en el repo de trabajo se eliminan tambien
  del repo distribuible, de modo que este queda siempre con el contenido exacto.

.PARAMETER Source
  Ruta del repo de trabajo. Por defecto: ...\mod\GitCaraxes

.PARAMETER Target
  Ruta del repo distribuible. Por defecto: ...\mod\Caraxes

.PARAMETER DryRun
  Ensayo general: muestra que se haria sin copiar ni borrar nada.

.EXAMPLE
  .\sync-release.ps1

  Sincroniza con las rutas por defecto.

.EXAMPLE
  .\sync-release.ps1 -DryRun

  Ensayo general: lista los cambios sin aplicarlos.
#>
[CmdletBinding()]
param(
    [string]$Source = 'C:\Users\sakya\Documents\Paradox Interactive\Hearts of Iron IV\mod\GitCaraxes',
    [string]$Target = 'C:\Users\sakya\Documents\Paradox Interactive\Hearts of Iron IV\mod\Caraxes',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Unicamente estos elementos forman parte del mod distribuible.
$Items = @(
    'common'
    'events'
    'gfx'
    'history'
    'interface'
    'localisation'
    'map'
    'portraits'
    'tutorial'
    'descriptor.mod'
)

if (-not (Test-Path -LiteralPath $Source)) {
    throw "No existe el repo de trabajo: $Source"
}

New-Item -ItemType Directory -Path $Target -Force | Out-Null

$totalChanged = 0
$totalFailed = 0

foreach ($item in $Items) {
    $srcItem = Join-Path $Source $item
    if (-not (Test-Path -LiteralPath $srcItem)) {
        Write-Warning "No existe en el repo de trabajo y se omite: $item"
        continue
    }

    if ((Get-Item -LiteralPath $srcItem).PSIsContainer) {
        # Modo espejo: el destino queda identico a la carpeta fuente.
        $args = @(
            $srcItem
            (Join-Path $Target $item)
            '/MIR'
            '/XJ'
            '/NFL'
            '/NDL'
            '/NJH'
            '/NP'
            '/R:1'
            '/W:1'
        )
        if ($DryRun) {
            $args += '/L'
        } else {
            $args += '/MT:16'
        }

        & robocopy @args | Out-Null
        $rc = $LASTEXITCODE

        # Robocopy: bit 1 = copio archivos, bit 2 = elimino extras; >= 8 = error.
        if ($rc -ge 8) {
            Write-Warning "Error al sincronizar $item (codigo $rc)"
            $totalFailed++
        } else {
            $copied = if ($rc -band 1) { 'si' } else { 'no' }
            $deleted = if ($rc -band 2) { 'si' } else { 'no' }
            Write-Host ("{0,-16} copiados: {1,-3} eliminados: {2}" -f $item, $copied, $deleted)
            if ($rc -band 1) { $totalChanged++ }
        }
    } else {
        # Archivo suelto en la raiz (descriptor.mod).
        $dstFile = Join-Path $Target $item
        $needsCopy = -not (Test-Path -LiteralPath $dstFile)

        if (-not $needsCopy) {
            $hashSrc = (Get-FileHash -LiteralPath $srcItem -Algorithm SHA1).Hash
            $hashDst = (Get-FileHash -LiteralPath $dstFile -Algorithm SHA1).Hash
            $needsCopy = $hashSrc -ne $hashDst
        }

        if ($needsCopy) {
            if ($DryRun) {
                Write-Host ("{0,-16} se copiaria (actualizado)" -f $item)
            } else {
                Copy-Item -LiteralPath $srcItem -Destination $dstFile -Force
                Write-Host ("{0,-16} copiado" -f $item)
            }
            $totalChanged++
        } else {
            Write-Host ("{0,-16} actualizado (sin cambios)" -f $item)
        }
    }
}

# Avisa si el destino tiene elementos de nivel superior que no pertenecen al mod.
$whitelist = $Items | ForEach-Object { $_.ToLowerInvariant() }
$extraItems = Get-ChildItem -LiteralPath $Target -Force | Where-Object {
    $whitelist -notcontains $_.Name.ToLowerInvariant()
}
if ($extraItems) {
    Write-Warning "El destino contiene elementos que no se sincronizan:"
    $extraItems | ForEach-Object { Write-Warning ("  {0}" -f $_.Name) }
}

Write-Host ""
if ($totalFailed -eq 0) {
    Write-Host "Sincronizacion completada. Elementos actualizados: $totalChanged"
} else {
    Write-Warning "Sincronizacion terminada con $totalFailed errores."
}
