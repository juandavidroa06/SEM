# Notas de fuente en el formato de la plantilla USTA. No modifica estimaciones.
nota_fuente <- paste0(
  "% FUENTE_ECP_2023\n",
  "\\par\\smallskip\\noindent\\parbox{\\linewidth}{\\footnotesize",
  "\\textit{Fuente:} elaboración propia con microdatos de la ECP 2023 del DANE.}\n")
for (ruta in list.files("articulo/tablas", pattern = "\\.tex$", full.names = TRUE)) {
  texto <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (grepl("% FUENTE_ECP_2023", texto, fixed = TRUE)) next
  if (grepl("\\end{table}", texto, fixed = TRUE)) {
    texto <- gsub("\\end{table}", paste0(nota_fuente, "\\end{table}"), texto, fixed = TRUE)
  } else if (grepl("\\end{longtable}", texto, fixed = TRUE)) {
    texto <- gsub("\\end{longtable}", paste0("\\end{longtable}\n", nota_fuente), texto, fixed = TRUE)
  } else next
  writeLines(trimws(texto, which = "right"), ruta, useBytes = TRUE)
}
