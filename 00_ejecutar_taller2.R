# Punto de entrada canónico. Ejecutar desde la raíz del proyecto:
# Rscript 00_ejecutar_taller2.R
# Los seis ZIP oficiales deben estar en datos_crudos/. No instala paquetes.
set.seed(2026)
# Algunas consolas heredan C.UTF-8, nombre no válido de locale en Windows.
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")
lib_usuario <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library",
  paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1]))
if (dir.exists(lib_usuario)) .libPaths(c(lib_usuario, .libPaths()))
requeridos <- c("lavaan", "semTools", "psych", "knitr", "writexl")
faltan <- requeridos[!vapply(requeridos, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) stop("Instale antes los paquetes: ", paste(faltan, collapse = ", "))
scripts <- c("00_diagnosticos_articulo.R", "01_afc.R", "02_estructural.R",
  "03_multigrupo.R", "04_exportar_resultados.R")
# Permite regenerar la presentación a partir de salidas ya verificadas.
solo_exportar <- "--solo-exportar" %in% commandArgs(trailingOnly = TRUE)
if (solo_exportar) scripts <- "04_exportar_resultados.R"
for (script in scripts) {
  cat("\n===", script, "===\n")
  source(script, local = new.env(parent = globalenv()), encoding = "UTF-8")
  gc()
}
capture.output(sessionInfo(), file = "salidas/sessionInfo_taller2.txt")
for (f in list.files("salidas", pattern = "sessionInfo.*\\.txt$", full.names = TRUE))
  writeLines(trimws(readLines(f, warn = FALSE), which = "right"), f, useBytes = TRUE)
cat("\nAnálisis y tablas regenerados. Compile articulo/articulo.tex con pdflatex y bibtex.\n")
sessionInfo()
