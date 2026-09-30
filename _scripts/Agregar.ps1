<#
  Agrega un elemento a registro.csv y regenera indice.html

  Ejemplos:
    .\Agregar.ps1 -Titulo "Manual de configuracion de red" -Categoria Manual `
                  -Fecha 2026-09-30 -Motivo "Lo necesito para la migracion" `
                  -Evento "Proyecto de infraestructura" -Ruta "C:\docs\manual.pdf"

    .\Agregar.ps1 -Titulo "Portal de planillas" -Categoria URL-Trabajo `
                  -URL "https://ejemplo.com/planillas" -Motivo "Consulta mensual"

  -Copia  = copia el archivo a la carpeta correspondiente dentro de MiEspacio
#>
param(
  [Parameter(Mandatory)][string]$Titulo,
  [Parameter(Mandatory)][ValidateSet('Personal','URL-Trabajo','Manual','Imagen-Sistema','Nota')]
                        [string]$Categoria,
  [string]$Fecha = (Get-Date -Format 'yyyy-MM-dd'),
  [string]$Motivo = '',
  [string]$Evento = '',
  [string]$URL = '',
  [string]$Ruta = '',
  [switch]$Copia
)

$ErrorActionPreference = 'Stop'
$Raiz     = Split-Path -Parent $PSScriptRoot
$csvPath  = Join-Path $Raiz 'registro.csv'

$carpeta = switch ($Categoria) {
  'Personal'       { '01-Archivos-Personales' }
  'URL-Trabajo'    { '02-URLs-Trabajo' }
  'Manual'         { '03-Manuales' }
  'Imagen-Sistema' { '04-Imagenes-Sistemas' }
  'Nota'           { '05-Notas-y-Eventos' }
}

# Convierte la ruta a relativa dentro de MiEspacio (así el enlace funciona
# tanto en tu PC como cuando el espacio esté publicado en la nube).
function Get-UbicacionEnlace([string]$rutaAbs) {
  $abs = [IO.Path]::GetFullPath($rutaAbs)
  $raizFull = [IO.Path]::GetFullPath($Raiz).TrimEnd('\') + '\'
  if ($abs.StartsWith($raizFull, [StringComparison]::OrdinalIgnoreCase)) {
    return $abs.Substring($raizFull.Length).Replace('\', '/')
  }
  return 'file:///' + $abs.Replace('\', '/')
}

$ubicacion = $URL

if ($Ruta) {
  if (-not (Test-Path -LiteralPath $Ruta)) { throw "No existe el archivo: $Ruta" }
  $destino = Join-Path $Raiz $carpeta
  if (-not (Test-Path $destino)) { New-Item -ItemType Directory -Force -Path $destino | Out-Null }
  if ($Copia) {
    $nombre = Split-Path -Leaf $Ruta
    $final  = Join-Path $destino $nombre
    if (Test-Path -LiteralPath $final) {
      $base = [IO.Path]::GetFileNameWithoutExtension($nombre)
      $ext  = [IO.Path]::GetExtension($nombre)
      $i = 2
      while (Test-Path -LiteralPath $final) { $final = Join-Path $destino ("{0} ({1}){2}" -f $base,$i,$ext); $i++ }
    }
    Copy-Item -LiteralPath $Ruta -Destination $final
    Write-Host "Copiado a: $final"
    $ubicacion = Get-UbicacionEnlace (Resolve-Path -LiteralPath $final).Path
  } else {
    $ubicacion = Get-UbicacionEnlace (Resolve-Path -LiteralPath $Ruta).Path
  }
  if (-not $Titulo) { $Titulo = Split-Path -Leaf $Ruta }
}

$nueva = [pscustomobject]@{
  Fecha     = $Fecha
  Categoria = $Categoria
  Titulo    = $Titulo
  Tipo      = [IO.Path]::GetExtension($ubicacion).TrimStart('.')
  Ubicacion = $ubicacion
  URL       = $URL
  Motivo    = $Motivo
  Evento    = $Evento
}

$existentes = @()
if (Test-Path $csvPath) { $existentes = @(Import-Csv -Path $csvPath -Encoding UTF8) }
$existentes += $nueva

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$tmp = "$csvPath.tmp"
$lineas = @('Fecha,Categoria,Titulo,Tipo,Ubicacion,URL,Motivo,Evento')
$existentes | ForEach-Object {
  $vals = @($_.Fecha,$_.Categoria,$_.Titulo,$_.Tipo,$_.Ubicacion,$_.URL,$_.Motivo,$_.Evento) |
          ForEach-Object { '"' + ([string]$_).Replace('"','""') + '"' }
  $lineas += ($vals -join ',')
}
[System.IO.File]::WriteAllText($tmp, ($lineas -join "`r`n") + "`r`n", $utf8Bom)
Move-Item -LiteralPath $tmp -Destination $csvPath -Force

& (Join-Path $PSScriptRoot 'Generar-Indice.ps1') -Raiz $Raiz
Write-Host "Agregado: $Titulo  [$Categoria]  ($Fecha)"
