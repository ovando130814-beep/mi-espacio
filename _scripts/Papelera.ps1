<#
  Ayudante de papelera.json: lectura y escritura seguras.
  Se usa desde Eliminar.ps1 y Restaurar.ps1 con:
      . (Join-Path $PSScriptRoot 'Papelera.ps1')
#>

function Get-Papelera([string]$Ruta) {
  if (-not (Test-Path $Ruta)) { return @() }
  $crudo = $null
  try { $crudo = Get-Content $Ruta -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch { return @() }

  $salida = @()
  foreach ($x in @($crudo)) {
    if ($null -eq $x) { continue }
    if ($x -is [System.Array]) {
      foreach ($y in @($x)) {
        if ($y -is [System.Management.Automation.PSCustomObject]) { $salida += $y }
      }
    }
    elseif ($x -is [System.Management.Automation.PSCustomObject]) { $salida += $x }
  }
  return $salida
}

function Set-Papelera([string]$Ruta, $Entradas) {
  $lista = @()
  if ($null -ne $Entradas) {
    $lista = @($Entradas | Where-Object { $_ -is [System.Management.Automation.PSCustomObject] })
  }
  $json = ConvertTo-Json -InputObject $lista -Depth 3
  if ([string]::IsNullOrWhiteSpace($json)) { $json = '[]' }
  [IO.File]::WriteAllText($Ruta, $json, (New-Object System.Text.UTF8Encoding($false)))
}
