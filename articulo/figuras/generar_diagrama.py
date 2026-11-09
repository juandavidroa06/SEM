"""Compatibilidad: delega al diagrama canónico en R base, sin valores fijos."""
from pathlib import Path
import os
import shutil
import subprocess

root = Path(__file__).resolve().parents[2]
executable = shutil.which("Rscript")
if not executable and os.name == "nt":
    candidates = sorted((Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "R").glob("R-*/bin/Rscript.exe"))
    executable = str(candidates[-1]) if candidates else None
if not executable:
    raise SystemExit("No se encontró Rscript; agréguelo al PATH.")
subprocess.run([executable, "-e",
    'if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8"); '
    'source("04_diagrama_articulo.R", encoding="UTF-8")'], cwd=root, check=True)
print(root / "articulo/figuras/modelo_sem.pdf")
