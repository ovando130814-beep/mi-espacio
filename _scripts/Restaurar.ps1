<#
  Restaura elementos de papelera.json de vuelta a registro.csv
  y regenera indice.html / index.html.

  Ejemplos:
    .\Restaurar.ps1             # muestra la papelera y elige
    .\Restaurar.ps1 -Id 2       # restaura el numero 2 de la lista
    .\Restaurar.ps1 -Todo       # restaura todo lo que hay en la papelera
    .\Restaurar.ps1 -Lista      # solo muestra que hay, sin restaurar
#>
param(
  [int]$Id = 0,
  [switch]$Todo,
  [switch]$Lista,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Stop'
$Raiz    = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $Raiz 'registro.csv'
$papPath = Join-Path $Raiz 'papelera.json'
. (Join-Path $PSScriptRoot 'Papelera.ps1')

$papelera = @(Get-Papelera $papPath)
if ($papelera.Count -eq 0) { Write-Host "La papelera esta vacia."; return }

Write-Host "PAPELERA:"
for ($i = 0; $i -lt $papelera.Count; $i++) {
  $p = $papelera[$i]
  Write-Host ("[{0}] {1}  {2}  -  {3}   (quitado: {4})" -f ($i+1), $p.f, $p.c, $p.t, $p.fb)
}
if ($Lista) { return }

$elegidos = @()
if ($Todo) {
  $elegidos = @($papelera)
} elseif ($Id -gt 0) {
  if ($Id -gt $papelera.Count) { throw "El Id $Id no existe (hay $($papelera.Count))." }
  $elegidos = @($papelera[$Id-1])
} else {
  if ($papelera.Count -eq 1) { $elegidos = @($papelera[0]) }
  else {
    $sel = Read-Host "Cual restauras? (numero, 0 para cancelar)"
    if ($sel -eq '0' -or -not $sel) { Write-Host "Cancelado."; return }
    if ([int]$sel -lt 1 -or [int]$sel -gt $papelera.Count) { throw "Numero invalido." }
    $elegidos = @($papelera[[int]$sel - 1])
  }
}
foreach ($e in $elegidos) { Write-Host ("  - " + $e.t) }
if (-not $Silencioso) {
  $ok = Read-Host "Lo restauramos? (s/N)"
  if ($ok -notmatch '^[sS]') { Write-Host "Cancelado."; return }
}

# --- catalogo actual -------------------------------------------------------
$filas = @()
if (Test-Path $csvPath) { $filas = @(Import-Csv -Path $csvPath -Encoding UTF8) }

function Get-Tipo([string]$u) {
  if (-not $u) { return '' }
  $nom = (($u -split '\?')[0] -split '/')[-1]
  return ($nom -split '\.')[-1]
}

$nuevas = @($filas)
foreach ($e in $elegidos) {
  $dup = $nuevas | Where-Object { $_.Fecha -eq $e.f -and $_.Titulo -eq $e.t -and $_.Ubicacion -eq $e.u }
  if ($dup) { Write-Host ("Ya estaba en el catalogo, no se duplica: " + $e.t); continue }
  $nuevas += [pscustomobject]@{
    Fecha = [string]$e.f; Categoria = [string]$e.c; Titulo = [string]$e.t
    Tipo = Get-Tipo ([string]$e.u); Ubicacion = [string]$e.u
    URL = $(if ([string]$e.u -match '^https?://') { [string]$e.u } else { '' })
    Motivo = [string]$e.m; Evento = [string]$e.e
  }
}

# --- escribir catalogo -----------------------------------------------------
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$lineas = @('Fecha,Categoria,Titulo,Tipo,Ubicacion,URL,Motivo,Evento')
$nuevas | ForEach-Object {
  $vals = @($_.Fecha,$_.Categoria,$_.Titulo,$_.Tipo,$_.Ubicacion,$_.URL,$_.Motivo,$_.Evento) |
          ForEach-Object { '"' + ([string]$_).Replace('"','""') + '"' }
  $lineas += ($vals -join ',')
}
[IO.File]::WriteAllText($csvPath, ($lineas -join "`r`n") + "`r`n", $utf8Bom)

# --- vaciar lo restaurado de la papelera -----------------------------------
$trest = @($elegidos | ForEach-Object { $_.t })
$quedan = @($papelera | Where-Object { $trest -notcontains $_.t })
Set-Papelera $papPath $quedan

& (Join-Path $PSScriptRoot 'Generar-Indice.ps1') -Raiz $Raiz
Write-Host ("Restaurados: {0}  |  catalogo: {1} registros  |  papelera: {2}." -f `
  $elegidos.Count, $nuevas.Count, $quedan.Count)
