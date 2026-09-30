<#
  ACTIVA LA WEB UNA VEZ, con un token temporal.

  1. Creas un token de corta vida (7 dias) con el permiso 'repo'
  2. Ejecutas este script y lo pegas cuando lo pide (oculto)
  3. El script activa GitHub Pages, espera a que se publique y te dice
     si tu direccion ya responde
  4. Borras el token en GitHub -> ya no lo necesitas NUNCA MAS

  Tu llave SSH (que no caduca) se encarga del resto: subir y borrar.

  Uso:
    .\Activar-Web.ps1
    .\Activar-Web.ps1 -Comprobar      # solo comprueba si la web ya responde
#>
param([switch]$Comprobar)

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Raiz    = Split-Path -Parent $PSScriptRoot
$cfgPath = Join-Path $env:USERPROFILE '.miespacio-github.json'
$apiRoot = 'https://api.github.com'

if (-not (Test-Path $cfgPath)) { Write-Host "Falta la configuracion. Ejecuta antes .\Subir-A-La-Nube.ps1"; return }
$cfg   = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$user  = $cfg.usuario; $repo = $cfg.repo
$webUrl = "https://$user.github.io/$repo/"
$apiRepo = "$apiRoot/repos/$user/$repo"

function Verificar-Web {
  $codigo = $null
  try { $r = Invoke-WebRequest -Uri $webUrl -UseBasicParsing -MaximumRedirection 5; $codigo = [int]$r.StatusCode }
  catch { $codigo = [int]$_.Exception.Response.StatusCode }
  return $codigo
}

if ($Comprobar) {
  $c = Verificar-Web
  Write-Host ("{0} -> {1}" -f $webUrl, $c)
  if ($c -eq 200) { Write-Host "TU ESPACIO ESTA EN LA NUBE. Ya puedes abrirlo desde cualquier lugar." -ForegroundColor Green }
  else { Write-Host "Todavia no responde. Espera 2-3 minutos y vuelve a ejecutar con -Comprobar." -ForegroundColor Yellow }
  return
}

Write-Host "=== ACTIVAR LA WEB (una sola vez) ===" -ForegroundColor Cyan
Write-Host "Direccion: $webUrl"
Write-Host ""
Write-Host "Si aun no tienes el token, crealo aqui (7 dias, permiso solo 'repo'):" -ForegroundColor Yellow
Write-Host "  https://github.com/settings/tokens/new" -ForegroundColor Yellow
Write-Host ""

$secure = Read-Host "Pega el token (no se ve mientras escribes)"
$token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
           [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$token = $token.Trim().Trim('"')
if (-not $token) { Write-Host "No escribiste nada. Cancelado."; return }

$hdrs = @{ Authorization = "token $token"; Accept = 'application/vnd.github+json'
           'User-Agent' = 'MiEspacio' }

Write-Host ""
Write-Host "[1] Comprobando el token..." -ForegroundColor Cyan
try {
  $yo = Invoke-RestMethod -Uri "$apiRoot/user" -Headers $hdrs -Method Get
  Write-Host ("      OK sesion valida como {0}" -f $yo.login) -ForegroundColor Green
} catch {
  $cod = [int]$_.Exception.Response.StatusCode
  Write-Host "      FALLO: token invalido o sin permiso (respuesta $cod)." -ForegroundColor Red
  Write-Host "      Revisa que empiece por ghp_ y que tenga el permiso 'repo'."
  return
}

Write-Host "[2] Activando GitHub Pages..." -ForegroundColor Cyan
$pags = $null
try { $pags = Invoke-RestMethod -Uri "$apiRepo/pages" -Headers $hdrs -Method Get }
catch { }

if ($pags) {
  Write-Host "      Ya estaba activa." -ForegroundColor Green
} else {
  $cuerpo = @{ source = @{ branch = 'main'; path = '/' } } | ConvertTo-Json -Depth 5
  try {
    $null = Invoke-RestMethod -Uri "$apiRepo/pages" -Headers $hdrs -Method Post `
                              -ContentType 'application/json' -Body $cuerpo
    Write-Host "      Pages ACTIVADA." -ForegroundColor Green
  } catch {
    $cod = [int]$_.Exception.Response.StatusCode
    if ($cod -eq 409) { Write-Host "      Ya existia (409): seguimos." -ForegroundColor Green }
    else {
      $leer = $_.Exception.Response.GetResponseStream()
      if ($leer) { $leer.Position = 0 }
      $txt = (New-Object IO.StreamReader($leer)).ReadToEnd()
      Write-Host "      No se pudo activar (HTTP $cod): $txt" -ForegroundColor Red
      Write-Host "      Activala a mano: https://github.com/$user/$repo/settings/pages"
      Write-Host "        Source: Deploy from a branch | Branch: main | Folder: / (root) | Save"
      return
    }
  }
}

Write-Host "[3] Esperando a que se publique (hasta 3 minutos)..." -ForegroundColor Cyan
$ok = $false
for ($i = 1; $i -le 36; $i++) {
  $c = Verificar-Web
  if ($c -eq 200) { $ok = $true; break }
  Write-Host -NoNewline "."
  Start-Sleep -Seconds 5
}
Write-Host ""

[IO.File]::WriteAllText((Join-Path $Raiz 'MI-DIRECCION.txt'), $webUrl + "`r`n", [Text.UTF8Encoding]::new($true))

if ($ok) {
  Write-Host ""
  Write-Host "============================================" -ForegroundColor Green
  Write-Host " TU ESPACIO ESTA EN LA NUBE" -ForegroundColor Green
  Write-Host "   $webUrl" -ForegroundColor Cyan
  Write-Host " Guardada en: MI-DIRECCION.txt" -ForegroundColor Cyan
  Write-Host "============================================" -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "Pages quedo activada pero la pagina tarda unos minutos mas." -ForegroundColor Yellow
  Write-Host "Comprueba con:  .\Activar-Web.ps1 -Comprobar" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "ULTIMO PASO - borra el token, ya no lo necesitas:" -ForegroundColor Yellow
Write-Host "  https://github.com/settings/tokens" -ForegroundColor Yellow
Write-Host "  (busca el token que acabas de usar y pulsa Delete)"
Write-Host ""
Write-Host "A partir de ahora todo se sube con tu llave SSH, que no caduca." -ForegroundColor Cyan
