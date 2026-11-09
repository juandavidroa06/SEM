"""Verificaciones de coherencia de los productos agregados antes de empaquetar.

Requiere solo la biblioteca estándar de Python. No reestima modelos.
"""
from pathlib import Path
import csv
import math
import re
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent


def rows(name):
    with (ROOT / "salidas" / name).open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def near(a, b, tol=1e-8):
    assert math.isclose(float(a), float(b), rel_tol=tol, abs_tol=tol), (a, b)


loads = [r for r in rows("08_cargas_afc_estandarizadas.csv") if r["op"] == "=~"]
assert len(loads) == 25
for r in loads:
    assert float(r["se"]) > 0
    assert float(r["ci.lower"]) < float(r["est.std"]) < float(r["ci.upper"])
    near(float(r["est.std"]) / float(r["se"]), r["z"])
wald = rows("08_invarianza_wald_rutas.csv")
assert len(wald) == 2
for r in wald:
    assert float(r["p_holm"]) >= float(r["p.value"])
assert all(float(r["p_holm"]) > .05 for r in wald)
assert all(r["convergio"] == "TRUE" for r in rows("08_ajuste_sem.csv"))
assert all(r["admisible"] == "TRUE" for r in rows("08_revision_medicion.csv"))
territorial = rows("08_sensibilidad_territorial.csv")
assert len(territorial) == 2 and all(int(r["n"]) == 46392 for r in territorial)
assert sum(int(r["n"]) for r in rows("08_grupos_region.csv")) == 46392
near(rows("08_diseno_muestral.csv")[0]["suma_FEX_P"], 37076519, tol=1e-6)
for r in rows("08_tamanos_efecto.csv"):
    near(float(r["R2_unico_incremental"]) / (1 - float(r["R2_completo"])), r["f2_incremental"])
ns = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
with zipfile.ZipFile(ROOT / "outputs/Taller2_SEM_resultados.xlsx") as z:
    assert z.testzip() is None
    book = ET.fromstring(z.read("xl/workbook.xml"))
    sheet_names = {e.attrib["name"] for e in book.findall("s:sheets/s:sheet", ns)}
    assert {"ajuste", "medicion", "discriminante", "hipotesis", "efectos", "invarianza",
            "territorial", "revision_medicion", "tamanos_efecto"} <= sheet_names
    for name in z.namelist():
        if name.startswith("xl/worksheets/") and name.endswith(".xml"):
            sheet = ET.fromstring(z.read(name))
            assert not sheet.findall('.//s:c[@t="e"]', ns), f"Error Excel en {name}"
tex = (ROOT / "articulo/articulo.tex").read_text(encoding="utf-8")
for match in re.findall(r"\\input\{([^}]+)\}", tex):
    assert (ROOT / "articulo" / match).is_file(), match
assert "modelo_sem <- '" in tex
assert "\\documentclass[11pt,letterpaper]{article}" in tex
assert "\\onehalfspacing" in tex and "\\affil[1]" in tex
assert "\\guia" not in tex and "\\begin{filecontents" not in tex
assert "diagnóstico conservador" not in tex
assert not re.search(r"[ \t]+$", tex, re.M)
print("Coherencia verificada: cargas e incertidumbre, Holm, sensibilidad territorial, tamaños de efecto, Excel e insumos LaTeX.")
