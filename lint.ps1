# ESLint без npm/cmd (політики «command prompt disabled»).
# Приклад: .\lint.ps1 .
#          .\lint.ps1 . --fix
$Root = $PSScriptRoot
Set-Location $Root
$eslint = Join-Path $Root 'node_modules/eslint/bin/eslint.js'
if (-not (Test-Path $eslint)) {
    Write-Error 'Спочатку виконайте npm install у каталозі проєкту.'
    exit 1
}
& node $eslint @args
exit $LASTEXITCODE
