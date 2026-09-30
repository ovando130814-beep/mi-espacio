<#
  Sube TODO tu espacio (archivos + registro.csv + indice.html) a GitHub
  y lo deja publicado en la nube para verlo desde cualquier lugar.

  El borrado en la nube funciona igual: primero borras en local con Eliminar.ps1
  y luego ejecutas este script. Lo que ya no esta aqui, desaparece alla.

  Ejemplos:
    .\Subir-A-La-Nube.ps1                       # sube todo (primera vez = crea todo)
    .\Subir-A-La-Nube.ps1 -Mensaje "agrego manual"   # sube con mensaje propio
    .\Subir-A-La-Nube.ps1 -Estado                # solo dice en que va
    .\Subir-A-La-Nube.ps1 -BorrarEnLaNube        # avisa si algo se borro en local

  La primera vez te pide: usuario de GitHub, nombre del repositorio y un
  TOKEN (Personal Access Token con permiso 'repo'). Se guarda en
  %USERPROFILE%\.miespacio-github.json  (fuera de la carpeta, no se sube).
#>
param(
  [string]$Mensaje = '',
  [switch]$Estado,
  [switch]$Diagnostico,
  [switch]$Abrir,
  [switch]$BorrarEnLaNube,
  [switch]$Reconfigurar
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raiz      = Split-Path -Parent $PSScriptRoot
$cfgPath   = Join-Path $env:USERPROFILE '.miespacio-github.json'
$apiRoot   = 'https://api.github.com'

function Guardar-Config($cfg) {
  $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $cfgPath -Encoding UTF8
}
function Leer-Config {
  if (Test-Path $cfgPath) { return Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json }
  return $null
}
function Pedir($texto, $oculto = $false) {
  if ($oculto) { return [Runtime.InteropServices.Marshal]::PtrToStringAuto(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR((Read-Host $texto -AsSecureString))) }
  $v = Read-Host $texto
  return $v.Trim()
}

$cfg = Leer-Config
if ($Reconfigurar -and (Test-Path $cfgPath)) { Remove-Item $cfgPath -Force; $cfg = $null }

if (-not $cfg -or -not $cfg.token -or -not $cfg.usuario) {
  Write-Host "=== Configuracion inicial de GitHub ===" -ForegroundColor Cyan
  Write-Host "Busca tu token en: GitHub > Settings > Developer settings > Personal access tokens"
  Write-Host "(necesita el permiso 'repo' en un token classic)"
  $usuario = Pedir 'Usuario de GitHub'
  $repo    = Pedir 'Nombre del repositorio (ej. mi-espacio)'
  $token   = Pedir 'Token (no se guarda en la carpeta ni se sube a GitHub)' $true
  $cfg = [pscustomobject]@{ usuario = $usuario; repo = $repo; token = $token }
  Guardar-Config $cfg
  Write-Host "Guardado en $cfgPath" -ForegroundColor Green
}

$user = $cfg.usuario; $repo = $cfg.repo; $token = $cfg.token
$hdrs = @{ Authorization = "token $token"; Accept = 'application/vnd.github+json'
           'User-Agent' = 'MiEspacio' }
$webUrl  = "https://$user.github.io/$repo/"
$gitUrl  = $webUrl
$apiRepo = "$apiRoot/repos/$user/$repo"

function Llamar-Api([string]$metodo, [string]$url, $cuerpo = $null) {
  $p = @{ Method = $metodo; Headers = $hdrs; Uri = $url }
  if ($cuerpo) { $p.Body = ($cuerpo | ConvertTo-Json -Depth 6); $p.ContentType = 'application/json' }
  try { return Invoke-RestMethod @p }
  catch {
    $r = $_.Exception.Response
    if ($r) {
      $cod = [int]$r.StatusCode
      if ($cod -eq 404) { return $null }
      $leer = $r.GetResponseStream(); if ($leer) { $leer.Position = 0 }
      $txt = (New-Object IO.StreamReader($leer)).ReadToEnd()
      throw "GitHub respondio $cod en ${url}: $txt"
    }
    throw
  }
}

if ($Estado) {
  $existe = Llamar-Api 'GET' $apiRepo
  if (-not $existe) { Write-Host 'El repositorio todavia NO existe en GitHub.' }
  else {
    Write-Host ("Repositorio: {0}/{1}" -f $user,$repo)
    Write-Host ("Privacidad : {0}" -f $(if($existe.private){'privado'}else{'publico'}))
    Write-Host ("Web        : {0}" -f $webUrl)
    $pags = Llamar-Api 'GET' "$apiRepo/pages"
    Write-Host ("Pages      : {0}" -f $(if($pags){'activa -> ' + $pags.html_url}else{'desactivada'}))
  }
  return
}

if ($Diagnostico) {
  Write-Host "========= DIAGNOSTICO PASO A PASO =========" -ForegroundColor Cyan

  Write-Host "[1] Cuenta y token..."
  try {
    $yo = Llamar-Api 'GET' "$apiRoot/user"
    Write-Host ("    OK  sesion valida como: {0}" -f $yo.login) -ForegroundColor Green
    if ($yo.login -ne $user) {
      Write-Host ("    AVISO: el usuario del config ('{0}') no coincide con el token ('{1}')." -f $user,$yo.login) -ForegroundColor Yellow
      $user = $yo.login
      $cfg.usuario = $yo.login; Guardar-Config $cfg
      $webUrl = "https://$user.github.io/$repo/"; $gitUrl = "$webUrl" ; $apiRepo = "$apiRoot/repos/$user/$repo"
      Write-Host "    Corregido automaticamente con el usuario del token."
    }
  } catch {
    Write-Host "    FALLO: token invalido o sin permisos." -ForegroundColor Red
    Write-Host "    Solucion: crea un token nuevo con el permiso 'repo' y usa -Reconfigurar"
    return
  }

  Write-Host "[2] Repositorio..."
  $existe = Llamar-Api 'GET' $apiRepo
  if (-not $existe) {
    Write-Host "    FALLO: no existe $user/$repo -> por eso el 404." -ForegroundColor Red
    Write-Host "    Solucion: ejecuta  .\Subir-A-La-Nube.ps1  (sin parametros) para crearlo y subir."
    return
  }
  Write-Host ("    OK  existe ({0})" -f $(if($existe.private){'privado'}else{'publico'})) -ForegroundColor Green

  Write-Host "[3] Contenido local..."
  $hayIdx   = Test-Path (Join-Path $Raiz 'index.html')
  $hayReg   = Test-Path (Join-Path $Raiz 'registro.csv')
  Write-Host ("    index.html: {0}   registro.csv: {1}" -f $(if($hayIdx){'si'}else{'NO'}), $(if($hayReg){'si'}else{'NO'}))
  if (-not $hayIdx -or -not $hayReg) {
    Write-Host "    FALLO: falta el contenido. Ejecuta .\Generar-Indice.ps1" -ForegroundColor Red; return
  }
  Write-Host "    OK" -ForegroundColor Green

  Write-Host "[4] Subida a GitHub..."
  git -C $Raiz remote remove origin 2>$null | Out-Null
  git -C $Raiz remote add origin "https://x-access-token:$token@github.com/$user/$repo.git" 2>&1 | Out-Null
  git -C $Raiz add -A 2>&1 | Out-Null
  $pend = @(git -C $Raiz status --porcelain)
  if ($pend.Count -gt 0) {
    git -C $Raiz commit -q -m ("Actualizacion " + (Get-Date -Format 'yyyy-MM-dd HH:mm')) 2>&1 | Out-Null
    Write-Host ("    Subiendo {0} cambio(s)..." -f $pend.Count)
  }
  $pushOut = git -C $Raiz push -u origin main 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    Write-Host "    FALLO al subir:" -ForegroundColor Red; Write-Host $pushOut
    return
  }
  Write-Host "    OK  contenido en GitHub" -ForegroundColor Green

  Write-Host "[5] Web publicada (GitHub Pages)..."
  $pages = Llamar-Api 'GET' "$apiRepo/pages"
  if (-not $pages) {
    Write-Host "    Pages NO activada. Activando..." -ForegroundColor Yellow
    try {
      $null = Llamar-Api 'POST' "$apiRepo/pages" @{ source = @{ branch='main'; path='/' } }
      Write-Host "    OK  Pages activada (tarda 1-3 minutos en estar visible)" -ForegroundColor Green
    } catch {
      Write-Host "    No se pudo activar sola: $_" -ForegroundColor Yellow
      Write-Host "    Activala tu mismo en: https://github.com/$user/$repo/settings/pages"
      Write-Host "      Source: Deploy from a branch | Branch: main | Folder: / (root) | Save"
    }
  } else { Write-Host "    OK  Pages activa" -ForegroundColor Green }

  Write-Host "[6] Comprobando tu direccion..."
  $codigo = $null
  try { $r = Invoke-WebRequest -Uri $gitUrl -UseBasicParsing -MaximumRedirection 5; $codigo = [int]$r.StatusCode }
  catch { $codigo = [int]$_.Exception.Response.StatusCode }
  if ($codigo -eq 200) {
    Write-Host "    OK  TU ESPACIO FUNCIONA -> $gitUrl" -ForegroundColor Green
  } else {
    Write-Host "    Aun responde ${codigo}: la publicacion tarda 1-3 minutos." -ForegroundColor Yellow
    Write-Host "    Espera y vuelve a ejecutar:  .\Subir-A-La-Nube.ps1 -Diagnostico"
  }

  [IO.File]::WriteAllText((Join-Path $Raiz 'MI-DIRECCION.txt'), $gitUrl, [Text.UTF8Encoding]::new($true))
  Write-Host "===========================================" -ForegroundColor Cyan
  return
}

# ---------------------------------------------------------- 1. repositorio
Write-Host "[1/5] Comprobando repositorio..." -ForegroundColor Cyan
$existe = Llamar-Api 'GET' $apiRepo
if (-not $existe) {
  Write-Host "  Creando $user/$repo (publico)..."
  $null = Llamar-Api 'POST' "$apiRoot/user/repos" @{
    name = $repo; private = $false; has_issues = $false; has_wiki = $false
    description = 'Mi espacio personal: archivos, URLs, manuales y notas, ordenados por fecha y motivo.'
  }
  Write-Host "  Repositorio creado." -ForegroundColor Green
} else {
  if ($existe.private) { Write-Host "  El repositorio es PRIVADO: la web no sera visible sin inicio de sesion." -ForegroundColor Yellow }
}

# ---------------------------------------------------------- 2. git local
Write-Host "[2/5] Preparando git local..." -ForegroundColor Cyan
$gitDir = Join-Path $Raiz '.git'
if (-not (Test-Path $gitDir)) {
  git -C $Raiz init -b main 2>&1 | Out-Null
  Write-Host "  Repositorio local creado."
}
if (-not (Test-Path (Join-Path $Raiz '.gitignore'))) {
  Set-Content -Path (Join-Path $Raiz '.gitignore') -Encoding UTF8 -Value @(
    '*.tmp','~$*','Thumbs.db','Desktop.ini','_tmp_check.txt')
}
if (-not (Test-Path (Join-Path $Raiz '.nojekyll'))) {
  Set-Content -Path (Join-Path $Raiz '.nojekyll') -Value ''
}

$ident = git -C $Raiz config user.email
if (-not $ident) {
  git -C $Raiz config user.name  "$user"
  git -C $Raiz config user.email "$user@users.noreply.github.com"
}

# remoto con token (solo en .git/config local, nunca se sube)
git -C $Raiz remote remove origin 2>$null | Out-Null
git -C $Raiz remote add origin "https://x-access-token:$token@github.com/$user/$repo.git" 2>&1 | Out-Null

# ---------------------------------------------------------- 3. cambios
Write-Host "[3/5] Analizando cambios..." -ForegroundColor Cyan
git -C $Raiz add -A 2>&1 | Out-Null
$status = git -C $Raiz status --porcelain
$pendientes = @($status)
$archivosSubidos = @($status | Where-Object { $_ -match '^\s*D' }).Count

if ($BorrarEnLaNube -and $archivosSubidos -gt 0) {
  Write-Host "  Se borraran de la nube $archivosSubidos archivo(s):" -ForegroundColor Yellow
  $status | Where-Object { $_ -match '^\s*D' } | ForEach-Object { Write-Host "    $_" }
}

if ($pendientes.Count -eq 0) {
  Write-Host "  Sin cambios: la nube ya esta al dia." -ForegroundColor Green
  $nada = $true
} else {
  Write-Host ("  {0} cambio(s) pendiente(s):" -f $pendientes.Count)
  $pendientes | Select-Object -First 25 | ForEach-Object { Write-Host "    $_" }
  if ($pendientes.Count -gt 25) { Write-Host "    ... y mas" }
}

# ---------------------------------------------------------- 4. subir
if (-not $nada) {
  if (-not $Mensaje) {
    $Mensaje = Read-Host 'Mensaje del cambio (Enter para uno automatico)'
  }
  if (-not $Mensaje) {
    $Mensaje = "Actualizacion " + (Get-Date -Format 'yyyy-MM-dd HH:mm')
  }
  Write-Host "[4/5] Subiendo a GitHub..." -ForegroundColor Cyan
  git -C $Raiz commit -m $Mensaje 2>&1 | Out-Null
  $push = git -C $Raiz push -u origin main 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR al subir:" -ForegroundColor Red
    Write-Host $push
    Write-Host "Revisa el token (permiso 'repo') o ejecuta con -Reconfigurar."
    return
  }
  Write-Host "  Subido." -ForegroundColor Green
} else {
  Write-Host "[4/5] Nada que subir." -ForegroundColor Cyan
}

# ---------------------------------------------------------- 5. publicar web
Write-Host "[5/5] Comprobando la web publicada..." -ForegroundColor Cyan
$pages = Llamar-Api 'GET' "$apiRepo/pages"
if (-not $pages) {
  Write-Host "  Activando GitHub Pages..."
  try {
    $null = Llamar-Api 'POST' "$apiRepo/pages" @{ source = @{ branch = 'main'; path = '/' } }
    Write-Host "  Pages activada." -ForegroundColor Green
  } catch {
    Write-Host "  No se pudo activar automaticamente: $_" -ForegroundColor Yellow
    Write-Host "  Activala en: https://github.com/$user/$repo/settings/pages (rama: main, carpeta: /)"
  }
} else {
  Write-Host ("  Pages activa: {0}" -f $pages.html_url)
}

# Direccion real guardada en un archivo, para que no tengas que teclearla
$dirFile = Join-Path $Raiz 'MI-DIRECCION.txt'
[IO.File]::WriteAllText($dirFile, $gitUrl + "`r`n", [Text.UTF8Encoding]::new($true))

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " TU ESPACIO ESTA EN LA NUBE" -ForegroundColor Green
Write-Host "   Web    : $gitUrl"
Write-Host "   Repo   : https://github.com/$user/$repo"
Write-Host "   Guardada tambien en: MI-DIRECCION.txt" -ForegroundColor Cyan
Write-Host " Abre esa direccion desde el celular o desde cualquier PC." -ForegroundColor Cyan
Write-Host " (Puede tardar 1-3 minutos en refrescarse la primera vez.)"
Write-Host " Si da 404 otra vez:  .\Subir-A-La-Nube.ps1 -Diagnostico" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

if ($Abrir) { Start-Process $gitUrl }
