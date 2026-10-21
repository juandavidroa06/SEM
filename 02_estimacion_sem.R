# Taller 1 SEM - CFA y SEM de la ECP 2023
# Ejecutar desde Taller1_SEM_ECP2023.Rproj.
# Requiere el paquete lavaan. No instala paquetes ni modifica la base original.

if (!requireNamespace("lavaan", quietly = TRUE)) {
  stop(paste(
    "Falta el paquete 'lavaan'. Instálelo en R con:",
    "install.packages('lavaan', repos='https://cloud.r-project.org')",
    "Luego vuelva a ejecutar este script."
  ))
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
  # Los nombres de archivo del ZIP pueden contener acentos con codificación
  # distinta a la configuración regional activa de Windows.
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
items_institucional <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items_modelo <- c(items_interpersonal, items_institucional, items_conocimiento)
no_encontrados <- setdiff(items_modelo, names(datos))
if (length(no_encontrados)) stop("Faltan variables: ", paste(no_encontrados, collapse = ", "))

# DANE: 99 = No sabe/No informa en las baterías de confianza.
for (v in c(items_interpersonal, items_institucional)) {
  datos[[v]][datos[[v]] == 99] <- NA
}
# P5376S1-S6: DANE codifica 1 = Sí conoce, 2 = No conoce.
for (v in items_conocimiento) {
  datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                       ifelse(datos[[v]] == 2, 0, NA_real_))
}

# Declarar como ordinales los indicadores del modelo; WLSMV es el estimador
# elegido para las variables endógenas categóricas.
items_ordinales <- items_modelo
datos[items_ordinales] <- lapply(datos[items_ordinales], function(x) {
  niveles <- if (all(stats::na.omit(x) %in% 0:1)) c(0, 1) else 1:5
  ordered(x, levels = niveles)
})

# Para que las comparaciones de CFA/SEM usen la misma muestra, se retienen
# casos completos en el conjunto candidato. La estrategia se documentará
# como limitación y se reconsiderará si se aprueba un tratamiento de faltantes.
casos_completos <- stats::complete.cases(datos[items_modelo])
analisis <- datos[casos_completos, c(ids, items_modelo), drop = FALSE]
cat("Casos completos usados:", nrow(analisis), "de", nrow(datos), "\n")
if (nrow(analisis) < 200) stop("La muestra completa queda por debajo de 200 casos.")

modelo_interpersonal <- '
  ConfianzaInterpersonal =~ P2025S4 + P2025S5 + P2025S6 + P2025S7
'
modelo_institucional <- paste0(
  "ConfianzaInstitucional =~ ", paste(items_institucional, collapse = " + ")
)
modelo_conocimiento <- paste0(
  "ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")
)

nombres_fm <- c(
  "chisq", "df", "pvalue", "chisq.scaled", "df.scaled", "pvalue.scaled",
  "cfi", "cfi.scaled", "cfi.robust", "tli", "tli.scaled", "tli.robust",
  "rmsea", "rmsea.scaled", "rmsea.robust", "srmr"
)

ajustar_cfa <- function(modelo, nombre, variables_ordenadas) {
  fit <- lavaan::cfa(
    modelo, data = analisis, ordered = variables_ordenadas,
    estimator = "WLSMV", missing = "listwise"
  )
  todas_fm <- lavaan::fitMeasures(fit)
  fm <- todas_fm[intersect(nombres_fm, names(todas_fm))]
  list(nombre = nombre, fit = fit, medidas = fm)
}

ajustes_cfa <- list(
  ajustar_cfa(modelo_interpersonal, "Confianza interpersonal",
              items_interpersonal),
  ajustar_cfa(modelo_institucional, "Confianza institucional",
              items_institucional),
  ajustar_cfa(modelo_conocimiento, "Conocimiento de mecanismos",
              items_conocimiento)
)

# Tabla de ajuste y cargas estandarizadas de cada CFA.
resumen_ajuste <- do.call(rbind, lapply(ajustes_cfa, function(x) {
  data.frame(constructo = x$nombre, as.list(x$medidas), check.names = FALSE)
}))
resumen_cargas <- do.call(rbind, lapply(ajustes_cfa, function(x) {
  pe <- lavaan::parameterEstimates(x$fit, standardized = TRUE)
  cargas <- pe[pe$op == "=~", c("lhs", "rhs", "est", "se", "pvalue", "std.all")]
  cargas$constructo <- x$nombre
  cargas
}))
indices_modificacion <- do.call(rbind, lapply(ajustes_cfa, function(x) {
  mi <- lavaan::modificationIndices(x$fit)
  mi <- mi[order(mi$mi, decreasing = TRUE), , drop = FALSE]
  mi <- utils::head(mi, 20)
  mi$constructo <- x$nombre
  mi
}))

# Modelo SEM integrado. Las confianzas pueden covariar y predicen el factor
# endógeno de conocimiento. Interpretar como asociación, no como causalidad.
modelo_sem <- paste(
  modelo_interpersonal,
  modelo_institucional,
  modelo_conocimiento,
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaInstitucional",
  "ConfianzaInterpersonal ~~ ConfianzaInstitucional",
  sep = "\n"
)
fit_sem <- lavaan::sem(
  modelo_sem, data = analisis, ordered = items_modelo,
  estimator = "WLSMV", missing = "listwise"
)
medidas_sem <- lavaan::fitMeasures(
  fit_sem
)
parametros_sem <- lavaan::parameterEstimates(fit_sem, standardized = TRUE)

# Guardar resultados reproducibles.
dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(resumen_ajuste, file.path("salidas", "02_ajuste_cfa.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(resumen_cargas, file.path("salidas", "02_cargas_cfa.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(indices_modificacion,
                 file.path("salidas", "02_indices_modificacion_cfa.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(parametros_sem, file.path("salidas", "02_parametros_sem.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(data.frame(medida = names(medidas_sem), valor = unname(medidas_sem)),
                 file.path("salidas", "02_ajuste_sem.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

cat("\nAJUSTE CFA\n")
print(resumen_ajuste, row.names = FALSE)
cat("\nAJUSTE SEM\n")
print(medidas_sem[intersect(nombres_fm, names(medidas_sem))])
cat("\nParámetros estructurales\n")
print(parametros_sem[parametros_sem$op == "~", ], row.names = FALSE)
cat("\nSalidas guardadas en la carpeta salidas/.\n")
