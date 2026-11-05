param([string]$Iscc)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$bundle = Join-Path $project 'build\windows\x64\runner\Release'
if (!(Test-Path -LiteralPath (Join-Path $bundle 'AvisosYPromedios.exe'))) { throw 'Primero compilá con flutter build windows --release.' }
# Incluir las bibliotecas redistribuibles de Visual C++ junto al ejecutable.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$visualStudio = & $vswhere -latest -prerelease -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$visualStudio) { throw 'No se encontró Visual C++ para preparar sus bibliotecas.' }
$crt = Get-ChildItem -Path (Join-Path $visualStudio 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT') -Directory | Sort-Object FullName -Descending | Select-Object -First 1
if (!$crt) { throw 'No se encontraron las bibliotecas redistribuibles de Visual C++.' }
Get-ChildItem -LiteralPath $crt.FullName -Filter '*.dll' | Copy-Item -Destination $bundle
$notices = Join-Path $project 'build\windows\x64\extracted\firebase_cpp_sdk_windows\NOTICES'
if (Test-Path -LiteralPath $notices) { Copy-Item -LiteralPath $notices -Destination (Join-Path $bundle 'Firebase-NOTICES.txt') }
Copy-Item -LiteralPath (Join-Path $project 'WINDOWS_NATIVO_GUIA.md') -Destination (Join-Path $bundle 'LEEME-Windows.md')
Copy-Item -LiteralPath (Join-Path $project 'windows\third_party\snappy\COPYING') -Destination (Join-Path $bundle 'Snappy-LICENSE.txt')
$zip = Join-Path $project 'build\AP-Windows-Portable.zip'
$archivos = Get-ChildItem -LiteralPath $bundle | Where-Object { $_.Extension -notin @('.lib','.exp','.pdb') }
Compress-Archive -LiteralPath $archivos.FullName -DestinationPath $zip -Force
if ($Iscc) {
  $version = (Select-String -LiteralPath (Join-Path $project 'pubspec.yaml') -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value.Replace('+','.')
  & $Iscc "/DAppVersion=$version" (Join-Path $project 'windows\instalador\ap.iss')
  if ($LASTEXITCODE -ne 0) { throw 'No se pudo compilar el instalador.' }
}
Write-Output "Windows preparado: $zip"
