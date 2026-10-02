<#
  Genera indice.html a partir de registro.csv
  Uso:  .\Generar-Indice.ps1
#>
param([string]$Raiz = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
$csvPath  = Join-Path $Raiz 'registro.csv'
$tplPath  = Join-Path $Raiz '_scripts\plantilla.html'
$outPath  = Join-Path $Raiz 'indice.html'

if (-not (Test-Path $csvPath)) { throw "No se encuentra $csvPath" }
if (-not (Test-Path $tplPath)) { throw "No se encuentra $tplPath" }

$filas = Import-Csv -Path $csvPath -Encoding UTF8 |
         Where-Object { $_.Titulo -and $_.Titulo.Trim() -ne '' }

$permitidas = @('Personal','URL-Trabajo','Manual','Imagen-Sistema','Nota','Actividad')
$mapa = @{
  'personales'='Personal'; 'personal'='Personal'
  'url'='URL-Trabajo'; 'urls'='URL-Trabajo'; 'url-trabajo'='URL-Trabajo'; 'trabajo'='URL-Trabajo'
  'manual'='Manual'; 'manuales'='Manual'
  'imagen'='Imagen-Sistema'; 'imagenes'='Imagen-Sistema'; 'imagen-sistema'='Imagen-Sistema'
  'nota'='Nota'; 'notas'='Nota'; 'evento'='Nota'; 'eventos'='Nota'
  'actividad'='Actividad'; 'actividades'='Actividad'
}

$objetos = foreach ($f in $filas) {
  $cat = ([string]$f.Categoria).Trim()
  if ($mapa.ContainsKey($cat.ToLower())) { $cat = $mapa[$cat.ToLower()] }
  if ($permitidas -notcontains $cat)     { $cat = 'Nota' }

  $fecha = ([string]$f.Fecha).Trim()
  if ($fecha -match '^(\d{4})-(\d{2})-(\d{2})') {
    $fecha = '{0}-{1}-{2}' -f $Matches[1],$Matches[2],$Matches[3]
  } else {
    $d = $null
    if ([datetime]::TryParse($fecha, [ref]$d)) { $fecha = $d.ToString('yyyy-MM-dd') } else { $fecha = '' }
  }

  [pscustomobject]@{
    f = $fecha
    c = $cat
    t = ([string]$f.Titulo).Trim()
    u = ([string]$f.Ubicacion).Trim()
    m = ([string]$f.Motivo).Trim()
    e = ([string]$f.Evento).Trim()
  }
}

$json = $objetos | ConvertTo-Json -Compress -Depth 5
if (-not $json) { $json = '[]' }
if ($json -notmatch '^\[') { $json = '[' + $json + ']' }
$json = $json.Replace('</', '<\/')

$plantilla = Get-Content -Path $tplPath -Raw -Encoding UTF8
$html = $plantilla.Replace('__CATALOGO_JSON__', $json)

$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outPath, $html, $utf8Bom)

# GitHub Pages solo sirve index.html en la raiz: lo generamos igual.
$idxOut = Join-Path $Raiz 'index.html'
[System.IO.File]::WriteAllText($idxOut, $html, $utf8Bom)

Write-Host ("Indice generado: {0}" -f $outPath)
Write-Host ("Elementos: {0}" -f @($objetos).Count)
