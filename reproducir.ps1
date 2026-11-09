param([switch]$SoloArticulo)
$ErrorActionPreference = 'Stop'
$texInputsAnterior = $env:TEXINPUTS
$texLocal = Join-Path $PSScriptRoot 'tmp/plantilla/texmf/tex'
if (Test-Path -LiteralPath $texLocal) {
    $env:TEXINPUTS = $texLocal.Replace('\','/') + '//;' + $texInputsAnterior
}
Push-Location $PSScriptRoot
try {
    if (-not $SoloArticulo) {
        $rCommand = Get-Command Rscript -ErrorAction SilentlyContinue
        if ($rCommand) { $rExecutable = $rCommand.Source }
        else {
            $rCandidates = Get-ChildItem -LiteralPath "$env:ProgramFiles\R" -Directory -ErrorAction SilentlyContinue |
                Sort-Object Name -Descending
            $rExecutable = $rCandidates | ForEach-Object { Join-Path $_.FullName 'bin\Rscript.exe' } |
                Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        }
        if (-not $rExecutable) { throw 'No se encontró Rscript. Instale R o agréguelo al PATH.' }
        & $rExecutable '00_ejecutar_taller2.R'
        if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis en R.' }
    }
    Push-Location articulo
    try {
        & pdflatex -interaction=nonstopmode -halt-on-error articulo.tex
        if ($LASTEXITCODE -ne 0) { throw 'Falló la primera compilación LaTeX.' }
        & bibtex articulo
        if ($LASTEXITCODE -ne 0) { throw 'Falló BibTeX.' }
        1..2 | ForEach-Object {
            & pdflatex -interaction=nonstopmode -halt-on-error articulo.tex
            if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación final LaTeX.' }
        }
    } finally { Pop-Location }
    Write-Host 'Artículo y resultados locales actualizados. No se ejecutan acciones de Git.'
} finally {
    Pop-Location
    $env:TEXINPUTS = $texInputsAnterior
}
