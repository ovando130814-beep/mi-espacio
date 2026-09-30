<#
  Sube TODO tu espacio (archivos + registro.csv + indice.html) a GitHub
  y lo deja publicado en la nube para verlo desde cualquier lugar.

  USA LLAVES SSH -> NO CADUCA NUNCA.
  La web publicada no depende de ningun token: aunque no vuelvas a subir nada,
  la pagina sigue en linea.

  El borrado en la nube es igual: borras en local con Eliminar.ps1 y ejecutas
  este script. Lo que ya no esta aqui, desaparece alla.

  Ejemplos:
    .\Subir-A-La-Nube.ps1                       # sube todo
    .\Subir-A-La-Nube.ps1 -Diagnostico          # te dice paso a paso que falla
    .\Subir-A-La-Nube.ps1 -Estado                # direccion web y estado
    .\Subir-A-La-Nube.ps1 -BorrarEnLaNube        # lista que se va a borrar alla
    .\Subir-A-La-Nube.ps1 -Reconfigurar          # cambiar usuario/repositorio
#>
param(
  [string]$Mensaje = '',
  [switch]$Estado,
  [switch]$Diagnostico,
  [switch]$Abrir,
  [switch]$BorrarEnLaNube,
  [switch]$Reconfigurar
)

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raiz      = Split-Path -Parent $PSScriptRoot
$cfgPath   = Join-Path $env:USERPROFILE '.miespacio-github.json'
$apiRoot   = 'https://api.github.com'
$sshDir    = Join-Path $env:USERPROFILE '.ssh'
$sshKey    = Join-Path $sshDir 'id_ed25519'

function Guardar-Config($cfg) {
  $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $cfgPath -Encoding UTF8
}
function Leer-Config {
  if (Test-Path $cfgPath) { return Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json }
  return $null
}
function Pedir([string]$texto) { return ((Read-Host $texto).Trim()) }
function Pedir-Secret([string]$texto) {
  return [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR((Read-Host $texto -AsSecureString)))
}

# ----------------------------------------------------------------- 0. config
$cfg = Leer-Config
if ($Reconfigurar -and (Test-Path $cfgPath)) { Remove-Item $cfgPath -Force; $cfg = $null }

if (-not $cfg -or -not $cfg.usuario -or -not $cfg.repo) {
  Write-Host "=== Configuracion de GitHub (una sola vez) ===" -ForegroundColor Cyan
  $usuario = Pedir 'Tu usuario de GitHub'
  $repo    = Pedir 'Nombre del repositorio en minusculas (ej. mi-espacio)'
  $cfg = [pscustomobject]@{ usuario = $usuario; repo = $repo; token = '' }
  Guardar-Config $cfg
}

$user = $cfg.usuario; $repo = $cfg.repo
$token = ''
if ($cfg.PSObject.Properties['token']) { $token = [string]$cfg.token }

$webUrl = "https://$user.github.io/$repo/"
$gitUrl = $webUrl
$apiRepo = "$apiRoot/repos/$user/$repo"
$sshRemote = "git@github.com:$user/$repo.git"

$hdrs = @{ Authorization = "token $token"; Accept = 'application/vnd.github+json'
           'User-Agent' = 'MiEspacio' }

function Llamar-Api([string]$metodo, [string]$url, $cuerpo = $null) {
  if (-not $token) { return $null }
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

# ----------------------------------------------------------------- SSH
function Get-Estado-SSH {
  $res = @{ clave = $false; registrada = $false; usuario = ''; pub = '' }
  if (Test-Path $sshKey) {
    $res.clave = $true
    if (Test-Path "$sshKey.pub") { $res.pub = (Get-Content "$sshKey.pub" -Raw).Trim() }
    $salida = ''
    try { $salida = (& ssh -o BatchMode=yes -T git@github.com 2>&1 | Out-String) }
    catch { $salida = $_.Exception.Message }
    if ($salida -match 'Hi\s+([A-Za-z0-9-]+)!') {
      $res.registrada = $true
      $res.usuario = $Matches[1]
    }
  }
  return $res
}

function Asegurar-Clave {
  if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Force -Path $sshDir | Out-Null }
  if (-not (Test-Path $sshKey)) {
    Write-Host "  Creando llave SSH (no caduca nunca)..."
    $null = & ssh-keygen -t ed25519 -C "miespacio-$user" -N '' -f $sshKey 2>&1
    if (-not (Test-Path $sshKey)) { throw "No se pudo crear la llave. Revisa que git este instalado." }
    Write-Host "  Llave creada en $sshKey" -ForegroundColor Green
  }
  # Evita la pregunta "Are you sure you want to continue connecting?"
  $known = Join-Path $sshDir 'known_hosts'
  $tiene = $false
  if (Test-Path $known) { $tiene = (Get-Content $known -Raw) -match 'github\.com' }
  if (-not $tiene) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $scan = & ssh-keyscan -T 5 github.com 2>$null } finally { $ErrorActionPreference = $prev }
    if ($scan) { Add-Content -Path $known -Value $scan }
  }
}

function Configurar-Remoto {
  git -C $Raiz remote remove origin 2>&1 | Out-Null
  git -C $Raiz remote add origin $sshRemote 2>&1 | Out-Null
}

# --------------------------------------------------------------- utilidades
function Preparar-Git {
  if (-not (Test-Path (Join-Path $Raiz '.git'))) {
    git -C $Raiz init -b main 2>&1 | Out-Null
    Write-Host "  Repositorio local creado."
  }
  if (-not (Test-Path (Join-Path $Raiz '.gitignore'))) {
    Set-Content -Path (Join-Path $Raiz '.gitignore') -Encoding UTF8 -Value @(
      '*.tmp','~$*','Thumbs.db','Desktop.ini','_tmp_check.txt')
  }
  if (-not (Test-Path (Join-Path $Raiz '.nojekyll'))) { Set-Content -Path (Join-Path $Raiz '.nojekyll') -Value '' }
  $ident = git -C $Raiz config user.email
  if (-not $ident) {
    git -C $Raiz config user.name  "$user"
    git -C $Raiz config user.email "$user@users.noreply.github.com"
  }
}

function Obtener-Cambios {
  git -C $Raiz add -A 2>&1 | Out-Null
  return @(git -C $Raiz status --porcelain)
}

function Subir-Commits([string]$texto) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { $push = git -C $Raiz push -u origin main 2>&1 | Out-String }
  finally { $ErrorActionPreference = $prev }
  if ($LASTEXITCODE -ne 0) { return $push }
  return ''
}

# ================================================================ ESTADO
if ($Estado) {
  $ssh = Get-Estado-SSH
  Write-Host ("Usuario    : {0}" -f $user)
  Write-Host ("Repositorio: {0}" -f $repo)
  Write-Host ("Direccion  : {0}" -f $webUrl)
  if ($ssh.registrada) { Write-Host ("SSH        : OK ({0}) - no caduca" -f $ssh.usuario) -ForegroundColor Green }
  elseif ($ssh.clave)  { Write-Host "SSH        : llave creada pero NO registrada en GitHub" -ForegroundColor Yellow }
  else                 { Write-Host "SSH        : sin llave" -ForegroundColor Yellow }
  $pags = Llamar-Api 'GET' "$apiRepo/pages"
  if ($pags) { Write-Host ("Web        : activa -> {0}" -f $pags.html_url) -ForegroundColor Green }
  else { Write-Host "Web        : sin datos (sin token o Pages sin activar)" }
  return
}

# ================================================================ DIAGNOSTICO
if ($Diagnostico) {
  Write-Host "========= DIAGNOSTICO PASO A PASO =========" -ForegroundColor Cyan

  Write-Host "[1] Llave SSH (no caduca)..."
  Asegurar-Clave
  $ssh = Get-Estado-SSH
  if ($ssh.registrada) {
    if ($ssh.usuario -ne $user) {
      Write-Host ("    AVISO: la llave pertenece a '{0}' y tu usuario es '{1}'." -f $ssh.usuario,$user) -ForegroundColor Yellow
      $user = $ssh.usuario; $cfg.usuario = $user; Guardar-Config $cfg
      $webUrl = "https://$user.github.io/$repo/"; $gitUrl = $webUrl
      $apiRepo = "$apiRoot/repos/$user/$repo"; $sshRemote = "git@github.com:$user/$repo.git"
      Write-Host "    Corregido automaticamente."
    }
    Write-Host ("    OK  autentica como {0} - NO VENCE NUNCA" -f $ssh.usuario) -ForegroundColor Green
  } else {
    Write-Host "    FALLO: la llave no esta registrada en tu cuenta de GitHub." -ForegroundColor Red
    Write-Host "    Copia esta linea entera:"
    Write-Host ""
    Write-Host ("      " + $ssh.pub) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    y pegala aqui (una sola vez):" -ForegroundColor Cyan
    Write-Host "      https://github.com/settings/ssh/new   (Title: MiEspacio, Key type: Authentication Key)"
    Write-Host "    Luego vuelve a ejecutar este diagnostico."
    return
  }

  Write-Host "[2] Contenido local..."
  foreach ($n in @('index.html','registro.csv')) {
    if (Test-Path (Join-Path $Raiz $n)) { Write-Host "    OK  $n" }
    else { Write-Host "    FALLO: falta $n" -ForegroundColor Red; Write-Host "    Ejecuta .\Generar-Indice.ps1"; return }
  }

  Write-Host "[3] Subiendo a GitHub..."
  Preparar-Git; Configurar-Remoto
  $pend = Obtener-Cambios
  if ($pend.Count -gt 0) {
    git -C $Raiz commit -q -m ("Actualizacion " + (Get-Date -Format 'yyyy-MM-dd HH:mm')) 2>&1 | Out-Null
    Write-Host ("    {0} cambio(s) para subir" -f $pend.Count)
  }
  $err = Subir-Commits ''
  if ($err) {
    Write-Host "    FALLO al subir:" -ForegroundColor Red; Write-Host $err
    if ($err -match 'Permission denied|Could not read from remote|Repository not found|does not appear to be a git repository') {
      Write-Host "    Causa probable: el repositorio no existe o la llave no esta registrada."
      Write-Host "    Crea el repositorio una vez en: https://github.com/new  (nombre: $repo, Public)"
      Write-Host "    y registra la llave en:          https://github.com/settings/ssh/new"
    }
    return
  }
  Write-Host "    OK  contenido en GitHub" -ForegroundColor Green

  Write-Host "[4] Web publicada (GitHub Pages)..."
  $pages = Llamar-Api 'GET' "$apiRepo/pages"
  if (-not $pages) {
    if (-not $token) {
      Write-Host "    Sin token no puedo activarla sola (se hace una vez a mano):" -ForegroundColor Yellow
      Write-Host "      https://github.com/$user/$repo/settings/pages"
      Write-Host "      Source: Deploy from a branch | Branch: main | Folder: / (root) | Save"
    } else {
      Write-Host "    Activando Pages..." -ForegroundColor Yellow
      try {
        $null = Llamar-Api 'POST' "$apiRepo/pages" @{ source = @{ branch='main'; path='/' } }
        Write-Host "    OK  Pages activada" -ForegroundColor Green
      } catch {
        Write-Host "    Activala en: https://github.com/$user/$repo/settings/pages" -ForegroundColor Yellow
      }
    }
  } else { Write-Host "    OK  Pages activa" -ForegroundColor Green }

  Write-Host "[5] Comprobando tu direccion..."
  $codigo = $null
  try { $r = Invoke-WebRequest -Uri $gitUrl -UseBasicParsing -MaximumRedirection 5; $codigo = [int]$r.StatusCode }
  catch { $codigo = [int]$_.Exception.Response.StatusCode }
  if ($codigo -eq 200) {
    Write-Host "    OK  TU ESPACIO FUNCIONA -> $gitUrl" -ForegroundColor Green
  } else {
    Write-Host "    Responde ${codigo}: la publicacion tarda 1-3 minutos." -ForegroundColor Yellow
    Write-Host "    Espera y vuelve a ejecutar:  .\Subir-A-La-Nube.ps1 -Diagnostico"
  }
  [IO.File]::WriteAllText((Join-Path $Raiz 'MI-DIRECCION.txt'), $gitUrl + "`r`n", [Text.UTF8Encoding]::new($true))
  Write-Host "===========================================" -ForegroundColor Cyan
  return
}

# ================================================================ SUBIR
Write-Host "[1/4] Llave SSH..." -ForegroundColor Cyan
Asegurar-Clave
$ssh = Get-Estado-SSH
if (-not $ssh.registrada) {
  Write-Host "  Tu llave aun no esta registrada en GitHub (se hace UNA vez y no vence nunca)." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  1. Copia esta linea entera:" -ForegroundColor Cyan
  Write-Host ("       " + $ssh.pub) -ForegroundColor Yellow
  Write-Host "  2. Abre: https://github.com/settings/ssh/new" -ForegroundColor Cyan
  Write-Host "     Title: MiEspacio   |   Key type: Authentication Key   |   pega y pulsa Add key"
  Write-Host "  3. Vuelve a ejecutar este comando." -ForegroundColor Cyan
  return
}
Write-Host ("  OK {0} (no caduca)" -f $ssh.usuario) -ForegroundColor Green

Write-Host "[2/4] Preparando git..." -ForegroundColor Cyan
Preparar-Git
Configurar-Remoto

Write-Host "[3/4] Analizando cambios..." -ForegroundColor Cyan
$pendientes = Obtener-Cambios
$borrar = @($pendientes | Where-Object { $_ -match '^\s*D' })
if ($BorrarEnLaNube -and $borrar.Count -gt 0) {
  Write-Host "  Se borraran de la nube $($borrar.Count) archivo(s):" -ForegroundColor Yellow
  $borrar | ForEach-Object { Write-Host "    $_" }
}
if ($pendientes.Count -eq 0) {
  Write-Host "  Sin cambios: la nube ya esta al dia." -ForegroundColor Green
} else {
  Write-Host ("  {0} cambio(s):" -f $pendientes.Count)
  $pendientes | Select-Object -First 25 | ForEach-Object { Write-Host "    $_" }
  if ($pendientes.Count -gt 25) { Write-Host "    ... y mas" }

  if (-not $Mensaje) { $Mensaje = Read-Host 'Mensaje del cambio (Enter para automatico)' }
  if (-not $Mensaje) { $Mensaje = "Actualizacion " + (Get-Date -Format 'yyyy-MM-dd HH:mm') }

  Write-Host "[4/4] Subiendo..." -ForegroundColor Cyan
  git -C $Raiz commit -q -m $Mensaje 2>&1 | Out-Null
  $err = Subir-Commits $Mensaje
  if ($err) {
    Write-Host "ERROR al subir:" -ForegroundColor Red; Write-Host $err
    Write-Host "Ejecuta:  .\Subir-A-La-Nube.ps1 -Diagnostico"
    return
  }
  Write-Host "  Subido." -ForegroundColor Green
}

[IO.File]::WriteAllText((Join-Path $Raiz 'MI-DIRECCION.txt'), $gitUrl + "`r`n", [Text.UTF8Encoding]::new($true))

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " TU ESPACIO ESTA EN LA NUBE" -ForegroundColor Green
Write-Host "   Web    : $gitUrl"
Write-Host "   Repo   : https://github.com/$user/$repo"
Write-Host "   Guardada tambien en: MI-DIRECCION.txt" -ForegroundColor Cyan
Write-Host " (La web no se cae aunque dejes de subir: solo con la cuenta de GitHub)" -ForegroundColor Cyan
Write-Host " Si da 404:  .\Subir-A-La-Nube.ps1 -Diagnostico" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

if ($Abrir) { Start-Process $gitUrl }
