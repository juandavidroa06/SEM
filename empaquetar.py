"""Construye el paquete público con una lista explícita de archivos agregados.

Uso: python empaquetar.py (desde cualquier carpeta).
Nunca añade ZIP del DANE, bases individuales ni salidas por persona.
"""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parent
SCRIPTS = [
    "00_ejecutar_taller2.R", "00_diagnosticos_articulo.R", "00_preparacion.R",
    "01_afc.R", "02_estructural.R", "02_sensibilidades_medicion.R",
    "03_multigrupo.R", "04_exportar_resultados.R", "04_diagrama_articulo.R", "04_fuentes_tablas.R",
    "05_calidad_descriptivos.R", "reproducir.ps1", "empaquetar.py", "verificar_resultados.py", "README.md",
    "REVISION_PUBLICACION.md", "Taller1_SEM_ECP2023.Rproj",
]
outputs = list((ROOT / "salidas").glob("08_*.csv"))
outputs += [ROOT / "salidas" / name for name in [
    "05_descriptivos_indicadores.csv", "05_normalidad_mardia.csv",
    "05_prueba_little_mcar.csv", "05_validacion_rangos.csv",
    "05_faltantes_por_indicador.csv", "05_patrones_faltantes.csv",
    "05_patrones_constantes.csv", "05_atipicos_multivariados_resumen.csv",
    "06_matriz_policorica.csv", "00_sessionInfo.txt", "01_sessionInfo.txt",
    "02_sessionInfo.txt", "03_sessionInfo.txt", "sessionInfo_taller2.txt",
]]
files = [ROOT / name for name in SCRIPTS] + outputs
files += [ROOT / "outputs/Taller2_SEM_resultados.xlsx"]
files += [ROOT / "articulo/articulo.tex", ROOT / "articulo/articulo.pdf", ROOT / "articulo/referencias.bib"]
files += [ROOT / "documentacion/Plantilla_Articulo_USTA.tex"]
files += list((ROOT / "articulo/tablas").glob("*.tex"))
files += [ROOT / "articulo/figuras/modelo_sem.pdf", ROOT / "articulo/figuras/modelo_sem.tex"]
files = sorted(set(files))
missing = [str(p.relative_to(ROOT)) for p in files if not p.is_file()]
if missing:
    raise SystemExit("Faltan productos: " + ", ".join(missing))
for p in files:
    if "datos_crudos" in p.parts or any(t in p.name for t in ("por_persona", "casos.csv", "base_analitica")):
        raise SystemExit("Archivo individual excluido: " + str(p))
manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
target = ROOT / "entregables/Taller2_SEM_Roa_Aldana_Rodriguez.zip"
target.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED) as z:
    for p in files:
        z.write(p, p.relative_to(ROOT).as_posix())
    z.writestr("MANIFIESTO_SHA256.json", json.dumps(manifest, indent=2, ensure_ascii=False))
with zipfile.ZipFile(target) as z:
    assert z.testzip() is None
print(f"Paquete verificado: {target} ({len(files)} archivos, sin microdatos)")
