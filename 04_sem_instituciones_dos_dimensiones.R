# SEM exploratorio: integra la alternativa institucional de dos dimensiones.
# Ejecutar desde Taller1_SEM_ECP2023.Rproj. La estructura aprobada sigue siendo
# la referencia y se vuelve a estimar en la misma muestra para comparación.

if (!requireNamespace("lavaan", quietly = TRUE)) {
  stop("Falta lavaan. Instálelo en RStudio con install.packages('lavaan').")
}

rutas_zip <- c(
  democracia = file.path("datos_crudos", "Democracia.zip"),
  participacion = file.path("datos_crudos", "Participacion.zip"),
  capital_social = file.path("datos_crudos", "Capital_social.zip")
)
faltantes <- rutas_zip[!file.exists(rutas_zip)]
if (length(faltantes)) stop("No se encontraron: ", paste(faltantes, collapse = ", "))

leer_csv_zip <- function(ruta_zip) {
  miembros <- utils::unzip(ruta_zip, list = TRUE)$Name
  miembros <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE,
                             useBytes = TRUE)]
  if (length(miembros) != 1) stop("Se esperaba un CSV dentro de ", ruta_zip)
  conexion <- unz(ruta_zip, miembros[[1]], open = "r")
  on.exit(close(conexion), add = TRUE)
  utils::read.csv(conexion, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

modulos <- lapply(rutas_zip, leer_csv_zip)
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
if (any(vapply(modulos, function(x) anyDuplicated(x[ids]) > 0, logical(1)))) {
  stop("Hay IDs duplicados; detener la integración de módulos.")
}
datos <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE),
                modulos)

items_interpersonal <- paste0("P2025S", 4:7)
items_institucionales <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items_modelo <- c(items_interpersonal, items_institucionales, items_conocimiento)
no_encontrados <- setdiff(items_modelo, names(datos))
if (length(no_encontrados)) stop("Faltan variables: ", paste(no_encontrados, collapse = ", "))

for (v in c(items_interpersonal, items_institucionales)) {
  datos[[v]][datos[[v]] == 99] <- NA
}
for (v in items_conocimiento) {
  datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                       ifelse(datos[[v]] == 2, 0, NA_real_))
}
datos[items_modelo] <- lapply(datos[items_modelo], function(x) {
  niveles <- if (all(stats::na.omit(x) %in% 0:1)) c(0, 1) else 1:5
  ordered(x, levels = niveles)
})

casos_completos <- stats::complete.cases(datos[items_modelo])
analisis <- datos[casos_completos, c(ids, items_modelo), drop = FALSE]
cat("Muestra analítica común:", nrow(analisis), "de", nrow(datos), "\n")
if (nrow(analisis) < 200) stop("La muestra completa queda por debajo de 200 casos.")

medicion_comun <- paste(
  "ConfianzaInterpersonal =~ P2025S4 + P2025S5 + P2025S6 + P2025S7",
  paste0("ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")),
  sep = "\n"
)

# Factor 1: representación política, gobierno y organización electoral.
# Factor 2: justicia, control, protección de derechos y seguridad pública.
# La segunda dimensión es deliberadamente amplia y se considera exploratoria.
medicion_dos_dimensiones <- paste(
  "ConfianzaRepresentacionGobierno =~ P5263S2 + P5263S4 + P5263S6 + P5263S8 + P5263S10 + P5263S12 + P5263S14 + P5263S15",
  "ConfianzaJusticiaControlProteccionSeguridad =~ P5263S1 + P5263S3 + P5263S5 + P5263S7 + P5263S9 + P5263S11 + P5263S13",
  sep = "\n"
)

modelo_referencia <- paste(
  medicion_comun,
  paste0("ConfianzaInstitucional =~ ", paste(items_institucionales, collapse = " + ")),
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaInstitucional",
  "ConfianzaInterpersonal ~~ ConfianzaInstitucional",
  sep = "\n"
)

modelo_dos_dimensiones <- paste(
  medicion_comun,
  medicion_dos_dimensiones,
  paste0("ConocimientoMecanismos ~ ConfianzaInterpersonal + ",
         "ConfianzaRepresentacionGobierno + ",
         "ConfianzaJusticiaControlProteccionSeguridad"),
  "ConfianzaInterpersonal ~~ ConfianzaRepresentacionGobierno",
  "ConfianzaInterpersonal ~~ ConfianzaJusticiaControlProteccionSeguridad",
  "ConfianzaRepresentacionGobierno ~~ ConfianzaJusticiaControlProteccionSeguridad",
  sep = "\n"
)

modelos <- list(
  referencia_aprobada = modelo_referencia,
  institucional_dos_dimensiones = modelo_dos_dimensiones
)
nombres_fm <- c("chisq.scaled", "df.scaled", "pvalue.scaled", "cfi.robust",
                "tli.robust", "rmsea.robust", "cfi.scaled", "tli.scaled",
                "rmsea.scaled", "srmr")
ajustes <- lapply(modelos, function(sintaxis) {
  lavaan::sem(sintaxis, data = analisis, ordered = items_modelo,
              estimator = "WLSMV", missing = "listwise")
})

resumen <- do.call(rbind, lapply(names(ajustes), function(nombre) {
  fit <- ajustes[[nombre]]
  fm <- lavaan::fitMeasures(fit)
  data.frame(
    modelo = nombre,
    n = nrow(analisis),
    convergio = isTRUE(lavaan::inspect(fit, "converged")),
    as.list(fm[intersect(nombres_fm, names(fm))]),
    check.names = FALSE
  )
}))

parametros <- do.call(rbind, lapply(names(ajustes), function(nombre) {
  pe <- lavaan::parameterEstimates(ajustes[[nombre]], standardized = TRUE)
  pe$modelo <- nombre
  pe
}))
parametros_ruta <- parametros[parametros$op == "~", , drop = FALSE]
covarianzas_latentes <- parametros[
  parametros$op == "~~" & parametros$lhs != parametros$rhs &
    parametros$lhs %in% c("ConfianzaInterpersonal", "ConfianzaInstitucional",
                          "ConfianzaRepresentacionGobierno",
                          "ConfianzaJusticiaControlProteccionSeguridad") &
    parametros$rhs %in% c("ConfianzaInterpersonal", "ConfianzaInstitucional",
                          "ConfianzaRepresentacionGobierno",
                          "ConfianzaJusticiaControlProteccionSeguridad"),
  , drop = FALSE
]

dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(resumen, "salidas/04_comparacion_sem.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(parametros_ruta, "salidas/04_rutas_sem.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(covarianzas_latentes, "salidas/04_covarianzas_latentes.csv",
                 row.names = FALSE, fileEncoding = "UTF-8")
writeLines(modelo_dos_dimensiones, "salidas/04_sintaxis_sem_alternativo.txt",
           useBytes = TRUE)

cat("\nCOMPARACIÓN SEM (WLSMV)\n")
print(resumen, row.names = FALSE)
cat("\nRutas estructurales estandarizadas\n")
print(parametros_ruta[, c("modelo", "lhs", "op", "rhs", "est", "se", "pvalue", "std.all")],
      row.names = FALSE)
cat("\nCorrelaciones entre factores exógenos\n")
print(covarianzas_latentes[, c("modelo", "lhs", "rhs", "est", "se", "pvalue", "std.all")],
      row.names = FALSE)
cat("\nEl SEM con dos dimensiones institucionales es exploratorio; la estructura\n")
cat("aprobada sigue siendo la referencia y estos resultados son asociaciones.\n")
