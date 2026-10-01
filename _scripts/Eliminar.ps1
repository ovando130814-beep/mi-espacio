<#
  Quita un elemento de registro.csv y lo deja en papelera.json (recuperable
  desde la web o con Restaurar.ps1), borrando opcionalmente su archivo fisico.

  Ejemplos:
    .\Eliminar.ps1                          # busca por texto y pregunta
    .\Eliminar.ps1 -Buscar "inventario"     # muestra los que coinciden y elige
    .\Eliminar.ps1 -Id 3                    # pasa por la papelera
    .\Eliminar.ps1 -Id 3 -BorrarArchivo     # papelera + borra el archivo
    .\Eliminar.ps1 -Id 3 -Definitivo        # borra sin papelera (no se recupera)
    .\Eliminar.ps1 -TodoLosEjemplos         # pasa por la papelera las plantillas [Ejemplo]
#>
param(
  [int]$Id = 0,
  [string]$Buscar = '',
  [switch]$BorrarArchivo,
  [switch]$Definitivo,
  [switch]$TodoLosEjemplos,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Stop'
$Raiz    = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $Raiz 'registro.csv'

if (-not (Test-Path $csvPath)) { throw "No se encuentra $csvPath" }
$filas = @(Import-Csv -Path $csvPath -Encoding UTF8)

if ($filas.Count -eq 0) { Write-Host "No hay registros todavia."; return }

# Devuelve la ruta absoluta de un elemento del catalogo
function Get-RutaArchivo([string]$ubic) {
  if (-not $ubic) { return $null }
  $u = $ubic
  if ($u -like 'file:///*') { return ([uri]$u).LocalPath }
  if ($u -match '^[a-zA-Z]:[\\/]') { return $u }
  if ($u -match '^https?://') { return $null }
  return (Join-Path $Raiz ($u -replace '/', '\'))
}

function Show-Lista([object[]]$lista) {
  for ($i = 0; $i -lt $lista.Count; $i++) {
    $r = $lista[$i]
    Write-Host ("[{0}] {1}  {2}  -  {3}" -f ($i+1), $r.Fecha, $r.Categoria, $r.Titulo)
  }
}

$objetivos = @()

if ($TodoLosEjemplos) {
  $objetivos = @($filas | Where-Object { $_.Titulo -like '*[Ejemplo]*' })
  if ($objetivos.Count -eq 0) { Write-Host "No hay registros de ejemplo."; return }
  Write-Host ("Se eliminaran {0} registros de ejemplo." -f $objetivos.Count)
} elseif ($Id -gt 0) {
  if ($Id -gt $filas.Count) { throw "El Id $Id no existe (hay $($filas.Count) registros)." }
  $objetivos = @($filas[$Id-1])
} else {
  $candidatos = $filas
  if ($Buscar) {
    $candidatos = @($filas | Where-Object {
      ($_.Titulo + ' ' + $_.Motivo + ' ' + $_.Evento + ' ' + $_.URL) -like "*$Buscar*" })
  }
  if ($candidatos.Count -eq 0) { Write-Host "Nada coincide con '$Buscar'."; return }
  if ($candidatos.Count -gt 1) {
    Write-Host "Elementos que coinciden:"; Show-Lista $candidatos
    $sel = Read-Host "Cual quieres borrar? (numero, 0 para cancelar)"
    if ($sel -eq '0' -or -not $sel) { Write-Host "Cancelado."; return }
    $objetivos = @($candidatos[[int]$sel - 1])
  } else {
    $objetivos = @($candidatos)
  }
}

foreach ($o in $objetivos) { Write-Host ("  - " + $o.Titulo) }
if (-not $Silencioso) {
  $ok = Read-Host "Seguro que lo borras? (s/N)"
  if ($ok -notmatch '^[sS]') { Write-Host "Cancelado."; return }
}

$titulosEliminar = @($objetivos | ForEach-Object { $_.Titulo })
$nuevas = @($filas | Where-Object { $titulosEliminar -notcontains $_.Titulo })

# Archivos fisicos
if ($BorrarArchivo) {
  foreach ($o in $objetivos) {
    $ruta = Get-RutaArchivo ([string]$o.Ubicacion)
    if ($ruta -and (Test-Path -LiteralPath $ruta)) {
      $dentro = ([IO.Path]::GetFullPath($ruta)).StartsWith(
                  ([IO.Path]::GetFullPath($Raiz).TrimEnd('\') + '\'),
                  [StringComparison]::OrdinalIgnoreCase)
      if ($dentro) { Remove-Item -LiteralPath $ruta -Force; Write-Host "Archivo borrado: $ruta" }
      else { Write-Host "Aviso: fuera de MiEspacio, no se borra: $ruta" }
    } elseif ($ruta) { Write-Host "El archivo no existia: $ruta" }
  }
}

# Papelera: lo borrado aqui se recupera con Restaurar.ps1 o desde la web
. (Join-Path $PSScriptRoot 'Papelera.ps1')
$papPath = Join-Path $Raiz 'papelera.json'
$papelera = @(Get-Papelera $papPath)
if (-not $Definitivo) {
  $ahora = (Get-Date).ToString('yyyy-MM-ddTHH:mm')
  foreach ($o in $objetivos) {
    $papelera += [pscustomobject]@{
      f = [string]$o.Fecha; c = [string]$o.Categoria; t = [string]$o.Titulo
      u = [string]$o.Ubicacion; m = [string]$o.Motivo; e = [string]$o.Evento; fb = $ahora
    }
  }
}
Set-Papelera $papPath $papelera

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$lineas = @('Fecha,Categoria,Titulo,Tipo,Ubicacion,URL,Motivo,Evento')
$nuevas | ForEach-Object {
  $vals = @($_.Fecha,$_.Categoria,$_.Titulo,$_.Tipo,$_.Ubicacion,$_.URL,$_.Motivo,$_.Evento) |
          ForEach-Object { '"' + ([string]$_).Replace('"','""') + '"' }
  $lineas += ($vals -join ',')
}
[System.IO.File]::WriteAllText($csvPath, ($lineas -join "`r`n") + "`r`n", $utf8Bom)

& (Join-Path $PSScriptRoot 'Generar-Indice.ps1') -Raiz $Raiz
Write-Host ("Borrados: {0}  |  quedan {1} registros." -f $objetivos.Count, $nuevas.Count)
if ($Definitivo) {
  Write-Host "Borrado definitivo: no quedo en la papelera."
} else {
  Write-Host ("En papelera: {0} elemento(s). Total en papelera: {1}." -f $objetivos.Count, $papelera.Count)
  Write-Host "Se recupera con Restaurar.ps1 o desde la web (botón 🗑 Papelera)."
}
