<#
  Revisa registro.csv antes de subirlo a la nube.

  Evita los fallos que rompen el catalogo:
    - filas vacias (el fallo que dejo el catalogo en blanco)
    - titulos o categorias sin nada
    - fechas invalidas
    - referencias a archivos que ya no existen
    - registros repetidos y rutas raras

  Uso:
    .\Validar-Catalogo.ps1             # solo revisa e imprime el informe
    .\Validar-Catalogo.ps1 -Corregir   # corrige lo automatico y luego revisa
    .\Validar-Catalogo.ps1 -Silencioso # no imprime nada (para otros scripts)

  Codigo de salida: 0 = todo bien | 1 = hay errores que impiden subir
#>
param(
  [string]$Raiz = (Split-Path -Parent $PSScriptRoot),
  [switch]$Corregir,
  [switch]$Silencioso
)

$ErrorActionPreference = 'Continue'

$csvPath = Join-Path $Raiz 'registro.csv'
$Columnas = @('Fecha','Categoria','Titulo','Tipo','Ubicacion','URL','Motivo','Evento')
$Permitidas = @('Personal','URL-Trabajo','Manual','Imagen-Sistema','Nota')
$MapaCat = @{
  'personales'='Personal'; 'personal'='Personal'
  'url'='URL-Trabajo'; 'urls'='URL-Trabajo'; 'url-trabajo'='URL-Trabajo'; 'trabajo'='URL-Trabajo'
  'manual'='Manual'; 'manuales'='Manual'
  'imagen'='Imagen-Sistema'; 'imagenes'='Imagen-Sistema'; 'imagen-sistema'='Imagen-Sistema'
  'nota'='Nota'; 'notas'='Nota'; 'evento'='Nota'; 'eventos'='Nota'
}

function Salida([string]$txt, [string]$color = 'Gray') {
  if (-not $Silencioso) { Write-Host $txt -ForegroundColor $color }
}

# ------------------------------------------------------- utilidades de CSV
function Split-Fila([string]$linea) {
  $campos = New-Object System.Collections.Generic.List[string]
  $campo  = New-Object System.Text.StringBuilder
  $comillas = $false
  for ($i = 0; $i -lt $linea.Length; $i++) {
    $c = $linea[$i]
    if ($comillas) {
      if ($c -eq '"') {
        if (($i + 1) -lt $linea.Length -and $linea[$i+1] -eq '"') { [void]$campo.Append('"'); $i++ }
        else { $comillas = $false }
      } else { [void]$campo.Append($c) }
    } else {
      if ($c -eq '"') { $comillas = $true }
      elseif ($c -eq ',') { $campos.Add($campo.ToString()); [void]$campo.Clear() }
      else { [void]$campo.Append($c) }
    }
  }
  $campos.Add($campo.ToString())
  $arr = $campos.ToArray()
  return ,$arr
}

function Get-Bloques([string[]]$lineas) {
  # une los renglones que traen saltos de linea dentro de comillas
  $bloques = @()
  $actual = $null
  $cuenta = 0
  foreach ($l in $lineas) {
    if ($null -eq $actual) { $actual = $l }
    else { $actual = $actual + "`n" + $l }
    $cuenta += ([regex]::Matches($l, '"')).Count
    if (($cuenta % 2) -eq 0) { $bloques += $actual; $actual = $null; $cuenta = 0 }
  }
  if ($null -ne $actual) { $bloques += $actual }
  return ,$bloques
}

function Get-Filas([string]$ruta) {
  $lineas = [IO.File]::ReadAllLines($ruta)
  $bloques = Get-Bloques $lineas
  $cab = @()
  $filas = @()
  $n = 0
  foreach ($b in $bloques) {
    $n++
    $campos = Split-Fila $b
    if ($n -eq 1) { $cab = $campos; continue }
    $o = [ordered]@{ _n = $n; _cols = $campos.Count }
    for ($i = 0; $i -lt $Columnas.Count; $i++) {
      $v = ''
      if ($i -lt $campos.Count) { $v = $campos[$i] }
      $o[$Columnas[$i]] = $v
    }
    $filas += [pscustomobject]$o
  }
  [pscustomobject]@{ Cabecera = $cab; Filas = $filas; Bloques = $bloques.Count }
}

function Normalizar-Fecha([string]$f) {
  $f = $f.Trim()
  if ($f -eq '') { return '' }
  if ($f -match '^(\d{4})-(\d{1,2})-(\d{1,2})') {
    return '{0}-{1:D2}-{2:D2}' -f [int]$Matches[1], [int]$Matches[2], [int]$Matches[3]
  }
  foreach ($pat in @('^\d{1,2}/\d{1,2}/\d{4}$', '^\d{1,2}-\d{1,2}-\d{4}$', '^\d{1,2}\.\d{1,2}\.\d{4}$')) {
    if ($f -match $pat) {
      $sep = if ($f -match '/') { '/' } elseif ($f -match '-') { '-' } else { '.' }
      $p = $f -split [regex]::Escape($sep)
      try {
        $n = @()
        foreach ($x in $p) { $n += [int]$x }
        if ($n.Count -eq 3) { return ([datetime]::new($n[2], $n[1], $n[0])).ToString('yyyy-MM-dd') }
      } catch { }
    }
  }
  if ($f -match '^\d{4}/\d{1,2}/\d{1,2}$') { $p = $f -split '/'; return ('{0}-{1:D2}-{2:D2}' -f $p[0],[int]$p[1],[int]$p[2]) }
  return $f
}

function Get-Categoria([string]$c) {
  $c = $c.Trim()
  if ($c -eq '') { return '' }
  if ($MapaCat.ContainsKey($c.ToLower())) { return $MapaCat[$c.ToLower()] }
  return $c
}

# --------------------------------------------------------------- CORREGIR
if ($Corregir) {
  if (-not (Test-Path $csvPath)) { Salida "No existe $csvPath" 'Red'; exit 1 }
  $lineas = [IO.File]::ReadAllLines($csvPath)
  $bloques = Get-Bloques $lineas
  $cab = Split-Fila $bloques[0]
  $nuevas = @()
  $tocada = $false
  $datosBloques = @()
  if ($bloques.Count -gt 1) { $datosBloques = $bloques[1..($bloques.Count-1)] }
  foreach ($b in $datosBloques) {
    $campos = Split-Fila $b
    $vals = @()
    $vacia = $true
    for ($i = 0; $i -lt $cab.Count; $i++) {
      $v = ''
      if ($i -lt $campos.Count) { $v = $campos[$i] }
      $limpio = $v.Trim()
      if ($limpio -ne '') { $vacia = $false }
      $vals += $limpio
    }
    if ($vacia) { $tocada = $true; continue }   # quita la fila vacia
    $fila = [ordered]@{}
    for ($i = 0; $i -lt $cab.Count; $i++) { $fila[$cab[$i]] = $vals[$i] }

    if ($fila['Fecha']) {
      $nuevaf = Normalizar-Fecha $fila['Fecha']
      if ($nuevaf -ne $fila['Fecha']) { $fila['Fecha'] = $nuevaf; $tocada = $true }
    }
    if ($fila['Categoria']) {
      $nuevac = Get-Categoria $fila['Categoria']
      if ($nuevac -ne $fila['Categoria']) { $fila['Categoria'] = $nuevac; $tocada = $true }
    }
    if ($fila['Ubicacion'] -and $fila['Ubicacion'] -match '\\') {
      $fila['Ubicacion'] = $fila['Ubicacion'].Replace('\','/'); $tocada = $true
    }
    if (-not $fila['URL'] -and $fila['Ubicacion'] -match '^https?://') {
      $fila['URL'] = $fila['Ubicacion']; $tocada = $true
    }
    $nuevas += [pscustomobject]$fila
  }
  if ($tocada) {
    $out = @( ($cab -join ',') )
    foreach ($f in $nuevas) {
      $vals = @()
      foreach ($c in $cab) {
        $v = [string]$f.$c
        $vals += '"' + $v.Replace('"','""') + '"'
      }
      $out += ($vals -join ',')
    }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($csvPath, (($out -join "`r`n") + "`r`n"), $utf8Bom)
    Salida "Correcciones aplicadas a registro.csv (filas en blanco, espacios, fechas, categorias)." 'Yellow'
  } else {
    Salida "No hubo nada automatico que corregir." 'Gray'
  }
}

# --------------------------------------------------------------- VALIDAR
if (-not (Test-Path $csvPath)) { Salida "No existe $csvPath" 'Red'; exit 1 }

$errores = @()
$avisos  = @()

$datos = Get-Filas $csvPath

if (($datos.Cabecera -join ',') -ne ($Columnas -join ',')) {
  $errores += ('La cabecera del archivo no coincide. Esperado: ' + ($Columnas -join ',') +
               ' | Encontrado: ' + ($datos.Cabecera -join ','))
  Salida '=== REVISION DEL CATALOGO ===' 'Cyan'
  foreach ($e in $errores) { Salida "  ERROR: $e" 'Red' }
  Salida 'Corrigelo a mano o restaura una version desde la web (Papelera > Historial).' 'Yellow'
  exit 1
}

$anho = (Get-Date).Year
$vidos = @{}
$n = 0
foreach ($f in $datos.Filas) {
  $n++
  $et = 'Registro ' + $f._n

  if ($f._cols -ne $Columnas.Count) {
    $errores += "${et}: tiene $($f._cols) columnas y deberian ser $($Columnas.Count)."
    continue
  }
  $todoVacio = $true
  foreach ($c in $Columnas) { if ([string]$f.$c -match '\S') { $todoVacio = $false } }
  if ($todoVacio) {
    $errores += "${et}: esta VACIA (sin datos). Esa fila es la que puede dejar el catalogo en blanco."
    continue
  }

  $tit = ([string]$f.Titulo).Trim()
  $cat = Get-Categoria $f.Categoria
  $fec = ([string]$f.Fecha).Trim()
  $ubi = ([string]$f.Ubicacion).Trim()

  if ($tit -eq '') { $errores += "${et}: no tiene titulo." } else { $et = "`"$tit`"" }

  if ($cat -eq '') { $errores += "${et}: no tiene categoria." }
  elseif ($Permitidas -notcontains $cat) { $errores += "${et}: la categoria `"$cat`" no esta permitida (valores: $($Permitidas -join ', '))." }

  if ($fec -ne '') {
    $d = $null
    if ($fec -match '^\d{4}-\d{2}-\d{2}$') {
      try { $d = [datetime]::ParseExact($fec, 'yyyy-MM-dd', $null) } catch { $d = $null }
    }
    if ($null -eq $d) {
      $errores += "${et}: la fecha `"$fec`" no es valida (use AAAA-MM-DD)."
    } elseif ($d.Year -lt 2000 -or $d.Year -gt ($anho + 1)) {
      $avisos += "${et}: la fecha $fec parece equivocada."
    }
  } else { $avisos += "${et}: esta sin fecha." }

  if ($cat -eq 'URL-Trabajo' -and $ubi -ne '' -and $ubi -notmatch '^https?://') {
    $avisos += "${et}: es una URL de trabajo pero `"$ubi`" no empieza por http://"
  }
  if ($ubi -match '\\') { $avisos += "${et}: la ruta usa barras invertidas; use / en lugar de \." }

  $clave = ($tit + '|' + $fec + '|' + $ubi).ToLower()
  if ($tit -ne '') {
    if ($vidos.ContainsKey($clave)) { $avisos += "${et}: parece repetido (mismo titulo, fecha y ubicacion que el registro $($vidos[$clave]))." }
    else { $vidos[$clave] = $f._n }
  }

  # comprobar que el archivo exista
  if ($ubi -ne '' -and $ubi -notmatch '^https?://' -and $ubi -notmatch '^[a-zA-Z]:[\\/]') {
    $ruta = Join-Path $Raiz ($ubi -replace '/', '\')
    if (-not (Test-Path $ruta)) {
      $errores += "${et}: falta el archivo `"$ubi`" en el espacio. Restauralo, corrige la ruta o quita ese registro."
    }
  }
  elseif ($ubi -ne '' -and $ubi -match '^[a-zA-Z]:[\\/]') {
    $avisos += "${et}: la ubicacion `"$ubi`" es de este PC y NO se sube a la nube."
  }
}

Salida '=== REVISION DEL CATALOGO ===' 'Cyan'
foreach ($e in $errores) { Salida "  ERROR: $e" 'Red' }
foreach ($a in $avisos)  { Salida "  aviso: $a" 'Yellow' }
if ($errores.Count -eq 0 -and $avisos.Count -eq 0) {
  Salida "  Todo bien: $($datos.Filas.Count) registro(s) listos para subir." 'Green'
} else {
  Salida "  $($datos.Filas.Count) registro(s) | $($errores.Count) error(es) | $($avisos.Count) aviso(s)" 'Gray'
  if ($errores.Count -gt 0) {
    Salida "  Puedes intentar:  .\Validar-Catalogo.ps1 -Corregir" 'Yellow'
  }
}

if ($errores.Count -gt 0) { exit 1 }
exit 0
