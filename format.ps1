# Prettier без cmd.exe / npx (політики «command prompt disabled»).
# Використання: .\format.ps1 --write .
# Або: .\format.ps1 --check .
$Root = $PSScriptRoot
Set-Location $Root
$prettier = Join-Path $Root 'node_modules/prettier/bin/prettier.cjs'
if (-not (Test-Path $prettier)) {
    Write-Error 'Спочатку виконайте npm install у каталозі проєкту.'
    exit 1
}
& node $prettier @args
exit $LASTEXITCODE
