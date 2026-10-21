# Taller 1 SEM - comparación de modelos de medida alternativos
# Ejecutar desde Taller1_SEM_ECP2023.Rproj.
# Conserva la especificación aprobada como baseline y compara opciones teóricas.

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

mods <- lapply(rutas_zip, leer_csv_zip)
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
if (any(vapply(mods, function(x) anyDuplicated(x[ids]) > 0, logical(1)))) {
  stop("Hay IDs duplicados; detener la integración de módulos.")
}
datos <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE), mods)

# Lista aprobada: P2025S4-S7, P5263S1-S15 y P5376S1-S6.
# Alternativa ampliada interpersonal agrega familia y colegas (S1-S2).
items_interpersonal_aprobados <- paste0("P2025S", 4:7)
items_interpersonal_ampliados <- c("P2025S1", "P2025S2", items_interpersonal_aprobados)
items_institucionales <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items_comparacion <- c(items_interpersonal_ampliados,
                       items_institucionales, items_conocimiento)
no_encontrados <- setdiff(items_comparacion, names(datos))
if (length(no_encontrados)) stop("Faltan variables: ", paste(no_encontrados, collapse = ", "))

items_confianza <- c(items_interpersonal_ampliados, items_institucionales)
for (v in items_confianza) datos[[v]][datos[[v]] == 99] <- NA
for (v in items_conocimiento) {
  datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                       ifelse(datos[[v]] == 2, 0, NA_real_))
}

# Para comparar especificaciones con la misma muestra, aplicar casos completos
# sobre la unión de indicadores de todos los modelos comparados.
casos_completos <- stats::complete.cases(datos[items_comparacion])
analisis <- datos[casos_completos, c(ids, items_comparacion), drop = FALSE]
cat("Muestra común para comparación:", nrow(analisis), "de", nrow(datos), "\n")
if (nrow(analisis) < 200) stop("La muestra común queda por debajo de 200 casos.")

# Declarar las categorías en orden para lavaan/WLSMV.
vars_ordinales <- items_comparacion
analisis[vars_ordinales] <- lapply(analisis[vars_ordinales], function(x) {
  niveles <- if (all(stats::na.omit(x) %in% 0:1)) c(0, 1) else 1:5
  ordered(x, levels = niveles)
})

# Baselines aprobados y dos alternativas conceptuales por constructo.
modelos <- list(
  interpersonal_aprobado = list(
    etiqueta = "Interpersonal: aprobado, 4 indicadores",
    sintaxis = "ConfianzaInterpersonal =~ P2025S4 + P2025S5 + P2025S6 + P2025S7",
    items = items_interpersonal_aprobados
  ),
  interpersonal_ampliado = list(
    etiqueta = "Interpersonal: ampliado, 6 indicadores",
    sintaxis = paste0("ConfianzaInterpersonal =~ ",
                      paste(items_interpersonal_ampliados, collapse = " + ")),
    items = items_interpersonal_ampliados
  ),
  institucional_aprobado = list(
    etiqueta = "Institucional: aprobado, 1 factor",
    sintaxis = paste0("ConfianzaInstitucional =~ ",
                      paste(items_institucionales, collapse = " + ")),
    items = items_institucionales
  ),
  institucional_dos_dimensiones = list(
    etiqueta = paste(
      "Institucional: representación política, gobierno y organización electoral",
      "vs justicia, control, protección de derechos y seguridad pública"
    ),
    sintaxis = paste(
      "ConfianzaGobiernoRepresentacion =~ P5263S2 + P5263S4 + P5263S6 + P5263S8 + P5263S10 + P5263S12 + P5263S14 + P5263S15",
      "ConfianzaEstadoDerechoControl =~ P5263S1 + P5263S3 + P5263S5 + P5263S7 + P5263S9 + P5263S11 + P5263S13",
      "ConfianzaGobiernoRepresentacion ~~ ConfianzaEstadoDerechoControl",
      sep = "\n"
    ),
    items = items_institucionales
  ),
  conocimiento_aprobado = list(
    etiqueta = "Conocimiento: aprobado, 1 factor",
    sintaxis = paste0("ConocimientoMecanismos =~ ",
                      paste(items_conocimiento, collapse = " + ")),
    items = items_conocimiento
  ),
  conocimiento_dos_familias = list(
    etiqueta = "Conocimiento: iniciativas/acción y consulta/voto",
    sintaxis = paste(
      "ConocimientoIniciativaAccion =~ P5376S1 + P5376S2 + P5376S6",
      "ConocimientoConsultaVoto =~ P5376S3 + P5376S4 + P5376S5",
      "ConocimientoIniciativaAccion ~~ ConocimientoConsultaVoto",
      sep = "\n"
    ),
    items = items_conocimiento
  )
)

nombres_fm <- c(
  "chisq.scaled", "df.scaled", "pvalue.scaled", "cfi.robust", "tli.robust",
  "rmsea.robust", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr"
)

ajustes <- lapply(modelos, function(m) {
  fit <- lavaan::cfa(
    m$sintaxis, data = analisis, ordered = m$items,
    estimator = "WLSMV", missing = "listwise"
  )
  fm <- lavaan::fitMeasures(fit)
  list(modelo = m, fit = fit,
       medidas = fm[intersect(nombres_fm, names(fm))])
})

resumen <- do.call(rbind, lapply(names(ajustes), function(nombre) {
  x <- ajustes[[nombre]]
  data.frame(
    modelo = nombre,
    especificacion = x$modelo$etiqueta,
    n = nrow(analisis),
    convergio = isTRUE(lavaan::inspect(x$fit, "converged")),
    as.list(x$medidas),
    check.names = FALSE
  )
}))

cargas <- do.call(rbind, lapply(names(ajustes), function(nombre) {
  x <- ajustes[[nombre]]
  pe <- lavaan::parameterEstimates(x$fit, standardized = TRUE)
  out <- pe[pe$op == "=~", c("lhs", "rhs", "est", "se", "pvalue", "std.all")]
  out$modelo <- nombre
  out
}))

modificaciones <- do.call(rbind, lapply(names(ajustes), function(nombre) {
  x <- ajustes[[nombre]]
  mi <- lavaan::modificationIndices(x$fit)
  mi <- mi[order(mi$mi, decreasing = TRUE), , drop = FALSE]
  mi <- utils::head(mi, 20)
  mi$modelo <- nombre
  mi
}))

dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(resumen, "salidas/03_comparacion_medicion.csv",
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(cargas, "salidas/03_cargas_alternativas.csv",
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(modificaciones, "salidas/03_indices_modificacion.csv",
                 row.names = FALSE, fileEncoding = "UTF-8")

cat("\nCOMPARACIÓN DE MEDICIÓN (índices robustos WLSMV)\n")
print(resumen, row.names = FALSE)
cat("\nLa comparación es descriptiva: no sustituye el argumento teórico ni constituye una modificación automática del modelo aprobado.\n")
cat("Resultados guardados en salidas/03_*.csv\n")
