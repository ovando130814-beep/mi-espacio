<#
  Pruebas de Validar-Catalogo.ps1
  Crea catalogos de prueba en una carpeta temporal, revisa el codigo de
  salida y que aparezcan (o no) los mensajes esperados.
#>
$ErrorActionPreference = 'Stop'
$validador = 'C:\Users\Administrador\MiEspacio\_scripts\Validar-Catalogo.ps1'
$tmp = Join-Path $env:TEMP ('miespacio-valid-' + (Get-Random))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($true)
$script:fallas = @()

function Ok([bool]$cond, [string]$msg) {
  if ($cond) { Write-Host "  PASS: $msg" -ForegroundColor Green }
  else { Write-Host "  FAIL: $msg" -ForegroundColor Red; $script:fallas += $msg }
}
function Nueva-Carpeta([string]$nombre, [string]$csv) {
  $d = Join-Path $tmp $nombre
  New-Item -ItemType Directory -Force -Path (Join-Path $d '03-Manuales') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $d '05-Notas-y-Eventos') | Out-Null
  [IO.File]::WriteAllText((Join-Path $d 'registro.csv'), $csv, $utf8)
  [IO.File]::WriteAllText((Join-Path $d '03-Manuales\manual-prueba.pdf'), 'hola', $utf8)
  [IO.File]::WriteAllText((Join-Path $d '05-Notas-y-Eventos\a.txt'), 'hola', $utf8)
  return $d
}
function Correr([string]$dir, [switch]$Corregir, [switch]$Silencioso) {
  # OJO: en PowerShell 5.1 el splat de arrays es POSICIONAL; para nombrar
  # parametros hay que usar un hashtable (@{Raiz=...}).
  $par = @{ Raiz = $dir }
  if ($Corregir)   { $par.Corregir   = $true }
  if ($Silencioso) { $par.Silencioso = $true }
  $sal = & $validador @par *>&1 | Out-String
  return [pscustomobject]@{ Codigo = $LASTEXITCODE; Salida = $sal }
}

$NL = "`r`n"
$cab = 'Fecha,Categoria,Titulo,Tipo,Ubicacion,URL,Motivo,Evento'

Write-Host "1) Catalogo correcto" -ForegroundColor Cyan
$csvOk = $cab + $NL +
  '"2026-01-05","Manual","Manual de prueba","pdf","03-Manuales/manual-prueba.pdf","03-Manuales/manual-prueba.pdf","Lo necesito","Inventario"' + $NL +
  '"2026-01-06","Nota","Nota con salto de linea","txt","05-Notas-y-Eventos/a.txt","","linea1' + "`n" + 'linea2","Reunion"' + $NL +
  '"2026-01-07","URL-Trabajo","Portal en linea","web","https://ejemplo.com/planillas","https://ejemplo.com/planillas","","Cierre"' + $NL
$d1 = Nueva-Carpeta 'ok' $csvOk
$r = Correr $d1
Ok ($r.Codigo -eq 0) "sale con codigo 0 (obtenido $($r.Codigo))"
Ok ($r.Salida -match 'Todo bien') "imprime 'Todo bien'"
Ok ($r.Salida -notmatch 'ERROR') "sin errores"
Ok ($r.Salida -notmatch 'salto de linea.*ERROR|ERROR.*salto') "el campo con salto de linea no rompe columnas"

Write-Host "2) Catalogo con todos los fallos" -ForegroundColor Cyan
$csvMal = $cab + $NL +
  '"2026-01-05","Manual","Manual de prueba","pdf","03-Manuales/manual-prueba.pdf","","Bien","E1"' + $NL +
  ',,,,,,,' + $NL +
  '"31/12/2025","manual","Fecha con formato raro","pdf","","","Corregible","E2"' + $NL +
  '"no-fecha","Trucos","Fecha imposible y categoria mala","","","","x","y"' + $NL +
  '"2026-02-02","URL-Trabajo","Portal caido","web","portalcaido.example.com","","x","E3"' + $NL +
  '"2026-01-05","Manual","Manual de prueba","pdf","03-Manuales/manual-prueba.pdf","","repeticion","E4"' + $NL +
  '"2026-02-03","Manual","Falta su archivo","pdf","03-Manuales/no-existe.pdf","","x","y"' + $NL +
  '"2026-02-04","Nota","","txt","05-Notas-y-Eventos/a.txt","","x","y"' + $NL +
  '"2026-02-05","Nota","Con barra invertida","txt","05-Notas-y-Eventos\a.txt","","x","y"' + $NL
$d2 = Nueva-Carpeta 'mal' $csvMal
$r = Correr $d2
Ok ($r.Codigo -eq 1) "sale con codigo 1 (obtenido $($r.Codigo))"
Ok ($r.Salida -match 'VACIA') "detecta la fila vacia"
Ok ($r.Salida -match 'fecha imposible|no es valida') "detecta la fecha imposible"
Ok ($r.Salida -match 'Trucos') "detecta la categoria no permitida"
Ok ($r.Salida -match 'no-existe\.pdf') "detecta el archivo que falta"
Ok ($r.Salida -match 'no tiene titulo') "detecta el registro sin titulo"
Ok ($r.Salida -match 'repetido') "avisa del registro repetido"
Ok ($r.Salida -match 'barra invertida|barras invertidas') "avisa de la barra invertida"
Ok ($r.Salida -match 'no empieza por http') "avisa de la URL sin http"
Ok ($r.Salida -notmatch 'ejemplo\.com') "no se queja del registro bueno"

Write-Host "3) -Corregir arregla lo automatico y sigue detectando lo demas" -ForegroundColor Cyan
$r = Correr $d2 -Corregir
Ok ($r.Salida -match 'Correcciones aplicadas') "aplica correcciones"
Ok (-not ($r.Salida -match 'VACIA')) "ya no hay fila vacia"
Ok ($r.Salida -notmatch '31/12/2025') "ya no aparece la fecha raro"
$tras = Get-Content (Join-Path $d2 'registro.csv') -Raw -Encoding UTF8
Ok ($tras -match '2025-12-31') "quedo convertida como 2025-12-31 en el archivo"
Ok ($r.Salida -notmatch 'barra invertida|barras invertidas') "las barras quedaron corregidas"
Ok ($r.Codigo -eq 1) "sigue saliendo con codigo 1 (queda lo manual)"
Ok ($r.Salida -match 'Trucos') "conserva el error de categoria"
Ok ($r.Salida -match 'no-existe\.pdf') "conserva el error de archivo faltante"
$tras = Get-Content (Join-Path $d2 'registro.csv') -Raw -Encoding UTF8
Ok ($tras -notmatch '(?m)^,+,') "la fila vacia ya no esta en el archivo"

Write-Host "4) Cabecera equivocada" -ForegroundColor Cyan
$csvCab = 'Fecha;Categoria;Titulo' + $NL + '"2026-01-01";"Nota";"X"' + $NL
$d3 = Nueva-Carpeta 'cabecera' $csvCab
$r = Correr $d3
Ok ($r.Codigo -eq 1) "sale con codigo 1"
Ok ($r.Salida -match 'cabecera') "avisla de la cabecera incorrecta"

Write-Host "5) Sin registros (solo cabecera)" -ForegroundColor Cyan
$d4 = Nueva-Carpeta 'vacio' ($cab + $NL)
$r = Correr $d4
Ok ($r.Codigo -eq 0) "un catalogo vacio no tiene errores (obtenido $($r.Codigo))"

Write-Host "6) -Silencioso no imprime nada" -ForegroundColor Cyan
$r = Correr $d1 -Silencioso
Ok ([string]::IsNullOrWhiteSpace($r.Salida)) "no imprime nada"

Write-Host "7) Catalogo inexistente" -ForegroundColor Cyan
$d5 = Join-Path $tmp 'nofile'
New-Item -ItemType Directory -Force -Path $d5 | Out-Null
$r = Correr $d5
Ok ($r.Codigo -eq 1) "sale con codigo 1 cuando no hay registro.csv"

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Write-Host ""
if ($script:fallas.Count -eq 0) { Write-Host "TODAS LAS PRUEBAS PASARON" -ForegroundColor Green; exit 0 }
Write-Host ("FALLARON {0} prueba(s):" -f $script:fallas.Count) -ForegroundColor Red
$script:fallas | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
