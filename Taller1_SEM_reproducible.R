# =============================================================
# Taller 1 - Fase 1 | Modelación de Ecuaciones Estructurales | USTA
# Integrantes: Roa, Aldana y Rodríguez | Fecha: 20-10-2026
# Fuente: DANE, Encuesta de Cultura Política (ECP) 2023.
# Proyecto: abrir Taller1_SEM_ECP2023.Rproj y ejecutar este archivo.
# Rutas relativas; conserva los ZIP originales en datos_crudos/.
# =============================================================

set.seed(2026)
options(stringsAsFactors = FALSE, scipen = 999)

# 0. Requisitos y rutas -------------------------------------------------------
if (!dir.exists("datos_crudos") || !file.exists("Taller1_SEM_ECP2023.Rproj")) {
  stop("Abra Taller1_SEM_ECP2023.Rproj y ejecute este script desde la carpeta del proyecto.")
}

paquetes <- c("lavaan", "psych", "GPArotation", "writexl")
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) {
  message("Instalando paquetes requeridos: ", paste(faltan, collapse = ", "))
  utils::install.packages(faltan, repos = "https://cloud.r-project.org")
}
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) {
  stop("No se pudieron instalar: ", paste(faltan, collapse = ", "),
       ". Instálelos desde RStudio y vuelva a ejecutar.")
}

dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
dir.create(file.path("outputs", "01a15760-d284-7790-91e9-a88837c249b8"),
           showWarnings = FALSE, recursive = TRUE)


# --- Sección 1: 00_inspeccion_base.R ---
# Taller 1 SEM - Encuesta de Cultura Politica (ECP), 2023
# Inspeccion inicial de los archivos crudos descargados de ANDA-DANE.
# Abrir Taller1_SEM_ECP2023.Rproj antes de ejecutar para trabajar con rutas relativas.

set.seed(2026)

# 1. Rutas de los archivos crudos --------------------------------------------
rutas_zip <- c(
  democracia = file.path("datos_crudos", "Democracia.zip"),
  participacion = file.path("datos_crudos", "Participacion.zip"),
  capital_social = file.path("datos_crudos", "Capital_social.zip"),
  caracteristicas_generales = file.path(
    "datos_crudos", "Caracteristicas_generales.zip"
  )
)

faltantes <- rutas_zip[!file.exists(rutas_zip)]
if (length(faltantes) > 0) {
  stop("No se encontraron estos ZIP: ", paste(faltantes, collapse = ", "))
}

# 2. Lectura de los CSV directamente desde cada ZIP ---------------------------
leer_csv_zip <- function(ruta_zip) {
  miembros <- utils::unzip(ruta_zip, list = TRUE)[["Name"]]
  # Los nombres dentro de los ZIP DANE usan acentos. En Windows pueden llegar
  # como bytes de otra codificación; useBytes evita fallar al buscar la extensión ASCII.
  miembros_csv <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE,
                                 useBytes = TRUE)]

  if (length(miembros_csv) != 1) {
    stop("Se esperaba un solo CSV dentro de: ", ruta_zip)
  }

  conexion <- unz(ruta_zip, miembros_csv[[1]], open = "r")
  on.exit(close(conexion), add = TRUE)

  datos <- utils::read.csv(
    conexion,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA")
  )

  attr(datos, "csv_interno") <- miembros_csv[[1]]
  datos
}

modulos <- lapply(rutas_zip, leer_csv_zip)

# 3. Revision de identificadores y estructura --------------------------------
id_persona <- c(
  "DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO"
)

revisar_modulo <- function(datos, nombre) {
  ids_ausentes <- setdiff(id_persona, names(datos))
  if (length(ids_ausentes) > 0) {
    stop("Faltan identificadores en ", nombre, ": ",
         paste(ids_ausentes, collapse = ", "))
  }

  ids <- datos[id_persona]
  data.frame(
    modulo = nombre,
    csv_en_zip = attr(datos, "csv_interno"),
    n_filas = nrow(datos),
    n_variables = ncol(datos),
    filas_con_id_incompleto = sum(!complete.cases(ids)),
    ids_duplicados = sum(duplicated(ids)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

diagnostico <- do.call(
  rbind,
  Map(revisar_modulo, modulos, names(modulos))
)

ids_por_modulo <- lapply(modulos, function(datos) {
  unique(datos[id_persona])
})
ids_comunes <- Reduce(
  function(x, y) merge(x, y, by = id_persona, all = FALSE, sort = FALSE),
  ids_por_modulo
)

diagnostico$ids_presentes_en_los_4_modulos <- nrow(ids_comunes)

# 4. Guardado del diagnostico --------------------------------------------------
dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
write.csv(
  diagnostico,
  file = file.path("salidas", "00_diagnostico_modulos.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

print(diagnostico, row.names = FALSE)
cat("\nEl diagnostico se guardo en salidas/00_diagnostico_modulos.csv\n")
cat("Este script no selecciona ni recodifica indicadores todavia.\n")


# --- Sección 2: 01_perfil_indicadores.R ---
# Taller 1 SEM - perfil inicial de indicadores ECP 2023
# Ejecutar desde el proyecto Taller1_SEM_ECP2023.Rproj
# Solo usa R base. No estima todavía el modelo SEM.

rutas_zip <- c(
  democracia = file.path("datos_crudos", "Democracia.zip"),
  participacion = file.path("datos_crudos", "Participacion.zip"),
  capital_social = file.path("datos_crudos", "Capital_social.zip")
)

faltantes <- rutas_zip[!file.exists(rutas_zip)]
if (length(faltantes)) stop("No se encontraron: ", paste(faltantes, collapse = ", "))

leer_csv_zip <- function(ruta_zip) {
  miembro <- utils::unzip(ruta_zip, list = TRUE)$Name
  # Los nombres de archivo del ZIP pueden contener acentos con codificación
  # distinta a la configuración regional activa de Windows.
  miembro <- miembro[grepl("\\.csv$", miembro, ignore.case = TRUE,
                           useBytes = TRUE)]
  if (length(miembro) != 1) stop("Se esperaba un CSV en ", ruta_zip)
  conexion <- unz(ruta_zip, miembro[[1]], open = "r")
  on.exit(close(conexion), add = TRUE)
  utils::read.csv(conexion, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

mods <- lapply(rutas_zip, leer_csv_zip)
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
if (any(vapply(mods, function(x) anyDuplicated(x[ids]) > 0, logical(1)))) {
  stop("Hay identificadores duplicados; revisar unión antes de continuar.")
}

base <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE), mods)

# Indicadores propuestos: confianza generalizada/interpersonal
vars_confianza_personas <- paste0("P2025S", 4:7)
# y confianza en instituciones/actores del Estado
vars_confianza_institucional <- paste0("P5263S", 1:15)
# Constructo endógeno propuesto: conocimiento de mecanismos ciudadanos
vars_conocimiento <- paste0("P5376S", 1:6)
vars <- c(vars_confianza_personas, vars_confianza_institucional, vars_conocimiento)
no_encontradas <- setdiff(vars, names(base))
if (length(no_encontradas)) stop("No se encontraron indicadores: ",
                                  paste(no_encontradas, collapse = ", "))

# 99 = No sabe/No informa en las baterías de confianza. P5263S6 y S12
# también tienen valores faltantes estructurales para algunas personas.
for (v in c(vars_confianza_personas, vars_confianza_institucional)) {
  base[[v]][base[[v]] == 99] <- NA
}
# En la batería P5376: 1 = Sí conoce, 2 = No conoce. Se recodifica a 1/0.
for (v in vars_conocimiento) {
  base[[v]] <- ifelse(base[[v]] == 1, 1,
                      ifelse(base[[v]] == 2, 0, NA_real_))
}

etiquetas <- c(
  P2025S4 = "Confianza en personas desconocidas",
  P2025S5 = "Confianza en vecinos(as)",
  P2025S6 = "Confianza en amistades",
  P2025S7 = "Confianza en personas de otra nacionalidad",
  P5263S1 = "Confianza en Procuraduría General de la Nación",
  P5263S2 = "Confianza en Alcaldía Municipal/Distrital",
  P5263S3 = "Confianza en Fuerzas Militares",
  P5263S4 = "Confianza en Congreso de la República",
  P5263S5 = "Confianza en jueces y magistrados",
  P5263S6 = "Confianza en Asamblea departamental",
  P5263S7 = "Confianza en Contraloría",
  P5263S8 = "Confianza en concejos municipales/distritales",
  P5263S9 = "Confianza en Policía",
  P5263S10 = "Confianza en partidos o movimientos políticos",
  P5263S11 = "Confianza en Defensoría del Pueblo",
  P5263S12 = "Confianza en Gobernación",
  P5263S13 = "Confianza en Fiscalía General de la Nación",
  P5263S14 = "Confianza en Registraduría Nacional del Estado Civil",
  P5263S15 = "Confianza en Presidencia de la República",
  P5376S1 = "Conoce revocatoria del mandato",
  P5376S2 = "Conoce iniciativa popular legislativa o normativa",
  P5376S3 = "Conoce referendo aprobatorio o derogatorio",
  P5376S4 = "Conoce plebiscito",
  P5376S5 = "Conoce consulta popular",
  P5376S6 = "Conoce cabildo abierto"
)

perfil <- do.call(rbind, lapply(vars, function(v) {
  x <- base[[v]]
  frecuencia <- table(x, useNA = "no")
  data.frame(
    variable = v,
    etiqueta = if (v %in% names(etiquetas)) unname(etiquetas[[v]]) else "Ver formulario/diccionario",
    n = length(x),
    n_validos = sum(!is.na(x)),
    n_perdidos = sum(is.na(x)),
    porcentaje_perdido = round(mean(is.na(x)) * 100, 2),
    distribucion = paste(paste(names(frecuencia), as.integer(frecuencia), sep = ":"),
                         collapse = " | "),
    stringsAsFactors = FALSE
  )
}))

# La cifra de casos completos solo es un diagnóstico preliminar; no se usa aún
# para eliminar registros ni definir la estrategia de estimación.
perfil$n_completos_en_indicadores <- sum(complete.cases(base[vars]))

dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(perfil, file.path("salidas", "01_perfil_indicadores.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
print(perfil, row.names = FALSE)
cat("\nCasos completos en la lista candidata:",
    sum(complete.cases(base[vars])), "de", nrow(base), "\n")
cat("Perfil guardado en salidas/01_perfil_indicadores.csv\n")


# --- Sección 3: 02_estimacion_sem.R ---
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


# --- Sección 4: 03_comparacion_medicion.R ---
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


# --- Sección 5: 04_sem_instituciones_dos_dimensiones.R ---
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


# --- Sección 6: 05_calidad_descriptivos.R ---
# Taller 1 SEM - calidad y descripción de indicadores ECP 2023
# Ejecutar desde Taller1_SEM_ECP2023.Rproj. Solo utiliza R base.
# Little MCAR y Mardia son aproximaciones normales sobre categorías numéricas;
# se interpretan con cautela porque los indicadores son ordinales/binarios.

set.seed(2026)

# 1. Lectura reproducible de los archivos crudos -----------------------------
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
  con <- unz(ruta_zip, miembros[[1]], open = "r")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

modulos <- lapply(rutas_zip, leer_csv_zip)
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
if (any(vapply(modulos, function(x) anyDuplicated(x[ids]) > 0, logical(1)))) {
  stop("Hay IDs duplicados en un módulo.")
}
base_cruda <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE,
                                          sort = FALSE), modulos)
if (anyDuplicated(base_cruda[ids]) > 0) stop("Hay IDs duplicados tras integrar módulos.")

vars_personas <- paste0("P2025S", 4:7)
vars_inst <- paste0("P5263S", 1:15)
vars_conoc <- paste0("P5376S", 1:6)
vars <- c(vars_personas, vars_inst, vars_conoc)
no_encontradas <- setdiff(vars, names(base_cruda))
if (length(no_encontradas)) stop("No se encontraron indicadores: ",
                                  paste(no_encontradas, collapse = ", "))

# 2. Validación de rangos y recodificación -----------------------------------
permitidos <- setNames(vector("list", length(vars)), vars)
for (v in c(vars_personas, vars_inst)) permitidos[[v]] <- c(1:5, 99)
for (v in vars_conoc) permitidos[[v]] <- c(1:2, 99)

validacion <- do.call(rbind, lapply(vars, function(v) {
  x <- base_cruda[[v]]
  invalidos <- !is.na(x) & !(x %in% permitidos[[v]])
  data.frame(
    variable = v,
    n = length(x),
    n_original_na = sum(is.na(x)),
    codigos_99 = sum(!is.na(x) & x == 99),
    n_fuera_de_rango = sum(invalidos),
    codigos_fuera_de_rango = paste(sort(unique(x[invalidos])), collapse = " | "),
    stringsAsFactors = FALSE
  )
}))

datos <- base_cruda[c(ids, vars)]
for (v in c(vars_personas, vars_inst)) datos[[v]][datos[[v]] == 99] <- NA_real_
for (v in vars_conoc) {
  datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                       ifelse(datos[[v]] == 2, 0, NA_real_))
}
X <- as.data.frame(datos[vars])
X[] <- lapply(X, as.numeric)

# 3. Duplicados, faltantes por variable/persona y patrones --------------------
duplicados_ids <- sum(duplicated(datos[ids]))
faltantes_variable <- data.frame(
  variable = vars,
  n_faltantes = colSums(is.na(X)),
  porcentaje_faltantes = round(100 * colMeans(is.na(X)), 3),
  stringsAsFactors = FALSE
)
faltantes_persona <- data.frame(
  id = seq_len(nrow(X)),
  n_faltantes = rowSums(is.na(X)),
  porcentaje_faltantes = round(100 * rowMeans(is.na(X)), 3)
)
faltantes_persona <- cbind(datos[ids], faltantes_persona[-1])
resumen_faltantes_persona <- data.frame(
  n = nrow(X),
  media_items_faltantes = mean(rowSums(is.na(X))),
  mediana_items_faltantes = median(rowSums(is.na(X))),
  max_items_faltantes = max(rowSums(is.na(X))),
  completos = sum(complete.cases(X)),
  porcentaje_completos = round(100 * mean(complete.cases(X)), 3)
)

mascara <- apply(ifelse(is.na(X), "1", "0"), 1, paste0, collapse = "")
patrones <- sort(table(mascara), decreasing = TRUE)
tabla_patrones <- data.frame(
  patron = names(patrones),
  n = as.integer(patrones),
  porcentaje = round(100 * as.integer(patrones) / nrow(X), 3),
  stringsAsFactors = FALSE
)
tabla_patrones$n_items_observados <- vapply(strsplit(tabla_patrones$patron, ""),
                                            function(z) sum(z == "0"), integer(1))
tabla_patrones$items_ausentes <- vapply(strsplit(tabla_patrones$patron, ""),
                                        function(z) paste(vars[z == "1"],
                                                          collapse = " | "),
                                        character(1))

# 4. Little MCAR: EM normal multivariado implementado en base R ---------------
# La prueba contrasta MCAR frente a diferencias de medias entre patrones.
# Debido a la escala ordinal/binaria y a la posible no aplicabilidad de S6/S12,
# se interpreta como diagnóstico aproximado, no como clasificación definitiva.
nearest_pd <- function(S, floor = 1e-7) {
  S <- (S + t(S)) / 2
  e <- eigen(S, symmetric = TRUE)
  e$vectors %*% diag(pmax(e$values, floor), nrow = length(e$values)) %*% t(e$vectors)
}

little_mcar_em <- function(x, maxit = 300, tol = 1e-7) {
  x <- as.matrix(x)
  storage.mode(x) <- "double"
  n <- nrow(x); p <- ncol(x)
  if (any(colSums(!is.na(x)) == 0)) stop("Algún indicador está completamente ausente.")
  pat <- apply(is.na(x), 1, paste0, collapse = "")
  grupos <- split(seq_len(n), factor(pat, levels = unique(pat)))
  mu <- colMeans(x, na.rm = TRUE)
  S <- stats::cov(x, use = "pairwise.complete.obs")
  S[!is.finite(S)] <- 0
  diag(S) <- ifelse(diag(S) > 0, diag(S), 1)
  S <- nearest_pd(S)
  convergio <- FALSE

  for (iter in seq_len(maxit)) {
    sum_x <- rep(0, p)
    sum_xx <- matrix(0, p, p)
    for (ii in grupos) {
      obs <- which(!is.na(x[ii[1], ]))
      mis <- setdiff(seq_len(p), obs)
      ni <- length(ii)
      ex <- matrix(rep(mu, ni), nrow = ni, byrow = TRUE)
      cond_cov <- matrix(0, p, p)
      if (length(obs)) {
        xo <- x[ii, obs, drop = FALSE]
        ex[, obs] <- xo
        if (length(mis)) {
          Soo <- S[obs, obs, drop = FALSE]
          Som <- S[obs, mis, drop = FALSE]
          B <- tryCatch(solve(Soo, Som), error = function(e) {
            solve(Soo + diag(1e-6, nrow(Soo)), Som)
          })
          ex[, mis] <- sweep(xo, 2, mu[obs], "-") %*% B +
            matrix(mu[mis], nrow = ni, ncol = length(mis), byrow = TRUE)
          cond_cov[mis, mis] <- S[mis, mis, drop = FALSE] -
            t(B) %*% Som
        }
      } else {
        cond_cov <- S
      }
      sum_x <- sum_x + colSums(ex)
      sum_xx <- sum_xx + crossprod(ex) + ni * cond_cov
    }
    mu_new <- sum_x / n
    S_new <- sum_xx / n - tcrossprod(mu_new)
    S_new <- nearest_pd(S_new)
    delta <- max(abs(mu_new - mu), abs(S_new - S))
    mu <- mu_new; S <- S_new
    if (delta < tol) { convergio <- TRUE; break }
  }

  chi <- 0
  observed_variables_by_pattern <- 0
  for (ii in grupos) {
    obs <- which(!is.na(x[ii[1], ]))
    k <- length(obs)
    observed_variables_by_pattern <- observed_variables_by_pattern + k
    if (!k) next
    d <- colMeans(x[ii, obs, drop = FALSE]) - mu[obs]
    Soo <- S[obs, obs, drop = FALSE]
    chi <- chi + length(ii) * drop(t(d) %*% solve(Soo, d))
  }
  # Little (1988): sum of observed variables across distinct patterns minus p.
  df <- observed_variables_by_pattern - p
  list(statistic = chi, df = df, p.value = stats::pchisq(chi, df,
                                                        lower.tail = FALSE),
       patterns = length(grupos), n = n, p = p, iterations = iter,
       converged = convergio)
}

vars_little <- setdiff(vars, c("P5263S6", "P5263S12"))
prueba_little <- tryCatch(little_mcar_em(X[vars_little]), error = function(e) {
  list(error = conditionMessage(e))
})
little_full <- tryCatch(little_mcar_em(X), error = function(e) {
  list(error = conditionMessage(e))
})
formatear_little <- function(resultado, muestra) {
  if (!is.null(resultado$error)) {
    return(data.frame(muestra = muestra, estado = "error",
                      detalle = resultado$error, stringsAsFactors = FALSE))
  }
  data.frame(
    muestra = muestra,
    estado = if (resultado$converged) "converged" else "not_converged",
    estadistico_chi_cuadrado = resultado$statistic,
    gl = resultado$df,
    p_valor = resultado$p.value,
    p_valor_mostrado = if (resultado$p.value < 2.2e-16) "< 2.2e-16" else
      format(resultado$p.value, scientific = TRUE, digits = 4),
    patrones = resultado$patterns,
    n = resultado$n,
    p_indicadores = resultado$p,
    iteraciones = resultado$iterations
  )
}
little_out <- rbind(
  formatear_little(prueba_little, "23 items; omits Assembly and Governor office (Bogota not applicable)"),
  formatear_little(little_full, "25 items; includes Assembly and Governor office")
)

# 5. Patrones constantes por batería y distancias multivariadas ----------------
es_constante_completa <- function(d) {
  z <- as.matrix(d)
  completos <- stats::complete.cases(z)
  resultado <- rep(NA, nrow(z))
  resultado[completos] <- apply(z[completos, , drop = FALSE], 1,
                                function(r) length(unique(r)) == 1)
  resultado
}
baterias <- list(
  confianza_personas = vars_personas,
  confianza_institucional = vars_inst,
  conocimiento = vars_conoc
)
constantes <- do.call(rbind, lapply(names(baterias), function(nm) {
  vv <- baterias[[nm]]
  cc <- stats::complete.cases(X[vv])
  constante <- es_constante_completa(X[vv])
  data.frame(
    bateria = nm, n_total = nrow(X), n_completa_bateria = sum(cc),
    perfiles_constantes = sum(constante %in% TRUE),
    porcentaje_de_completos = if (sum(cc))
      round(100 * sum(constante %in% TRUE) / sum(cc), 3) else NA_real_
  )
}))

Xcc <- X[complete.cases(X), , drop = FALSE]
idscc <- datos[complete.cases(X), ids, drop = FALSE]
p <- ncol(Xcc)
Scc <- stats::cov(Xcc)
dist2 <- tryCatch(stats::mahalanobis(Xcc, colMeans(Xcc), Scc),
                  error = function(e) rep(NA_real_, nrow(Xcc)))
umbral <- stats::qchisq(0.999, df = p)
multivariado <- data.frame(
  n_completos = nrow(Xcc), p_indicadores = p,
  umbral_chi2_0_999 = umbral,
  casos_sobre_umbral = sum(dist2 > umbral, na.rm = TRUE),
  porcentaje_sobre_umbral = round(100 * mean(dist2 > umbral, na.rm = TRUE), 3),
      nota = "Exploratory flag only: ordinal/binary categories are not multivariate normal. Do not exclude cases using this threshold alone."
)
casos_distancia <- cbind(idscc, distancia_mahalanobis2 = dist2,
                         supera_umbral = dist2 > umbral)
casos_distancia <- casos_distancia[order(casos_distancia$distancia_mahalanobis2,
                                         decreasing = TRUE), , drop = FALSE]
casos_distancia <- head(casos_distancia, 100)

# 6. Descriptivos, distribuciones, piso/techo y Mardia ------------------------
momentos <- function(x) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 3) return(c(asimetria = NA_real_, curtosis_exceso = NA_real_))
  m <- mean(x); m2 <- mean((x - m)^2)
  c(asimetria = mean((x - m)^3) / m2^(3/2),
    curtosis_exceso = mean((x - m)^4) / m2^2 - 3)
}

descriptivos <- do.call(rbind, lapply(vars, function(v) {
  x <- X[[v]]
  obs <- x[!is.na(x)]
  es_binaria <- v %in% vars_conoc
  niveles <- if (es_binaria) c(0, 1) else 1:5
  f <- table(factor(obs, levels = niveles))
  mo <- momentos(obs)
  data.frame(
    variable = v, n = length(x), n_valido = length(obs), n_perdido = sum(is.na(x)),
    porcentaje_perdido = round(100 * mean(is.na(x)), 3),
    media = mean(obs), desviacion = stats::sd(obs), mediana = stats::median(obs),
    minimo = min(obs), maximo = max(obs),
    asimetria = mo["asimetria"], curtosis_exceso = mo["curtosis_exceso"],
    porcentaje_categoria_minima = 100 * f[1] / length(obs),
    porcentaje_categoria_maxima = 100 * f[length(f)] / length(obs),
    frecuencias = paste(names(f), as.integer(f), sep = ":", collapse = " | "),
    stringsAsFactors = FALSE
  )
}))

# Mardia requiere una matriz completa y variables continuas. Se calcula sobre
# una submuestra reproducible para evitar una matriz n x n de gran tamaño.
n_mardia <- min(2000L, nrow(Xcc))
set.seed(2026)
indices_mardia <- if (nrow(Xcc) > n_mardia) sample(seq_len(nrow(Xcc)), n_mardia) else seq_len(nrow(Xcc))
Xm <- as.matrix(Xcc[indices_mardia, , drop = FALSE])
mu_m <- colMeans(Xm)
Z <- sweep(Xm, 2, mu_m, "-")
Sm <- stats::cov(Xm)
mardia <- tryCatch({
  R <- chol(Sm)
  W <- Z %*% solve(R)
  D <- tcrossprod(W)
  d2 <- rowSums(W^2)
  b1p <- mean(D^3)
  b2p <- mean(d2^2)
  gl_skew <- p * (p + 1) * (p + 2) / 6
  chi_skew <- n_mardia * b1p / 6
  z_kurt <- (b2p - p * (p + 2)) / sqrt(8 * p * (p + 2) / n_mardia)
  data.frame(
    n_completo_total = nrow(Xcc), n_submuestra = n_mardia, p = p,
    b1p_asimetria = b1p, chi2_asimetria = chi_skew,
    gl_asimetria = gl_skew,
    p_asimetria = stats::pchisq(chi_skew, gl_skew, lower.tail = FALSE),
    p_asimetria_mostrado = if (stats::pchisq(chi_skew, gl_skew,
                                              lower.tail = FALSE) < 2.2e-16)
      "< 2.2e-16" else format(stats::pchisq(chi_skew, gl_skew,
                                            lower.tail = FALSE),
                              scientific = TRUE, digits = 4),
    b2p_curtosis = b2p, referencia_bajo_normalidad = p * (p + 2),
    z_curtosis = z_kurt,
    p_curtosis = 2 * stats::pnorm(abs(z_kurt), lower.tail = FALSE),
    p_curtosis_mostrado = if (2 * stats::pnorm(abs(z_kurt),
                                                lower.tail = FALSE) < 2.2e-16)
      "< 2.2e-16" else format(2 * stats::pnorm(abs(z_kurt),
                                                lower.tail = FALSE),
                              scientific = TRUE, digits = 4),
    nota = "Approximation using numeric ordinal/binary codes; do not assume continuous normality."
  )
}, error = function(e) data.frame(error = conditionMessage(e)))

# 7. Reportes gráficos en base R ---------------------------------------------
dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
png(file.path("salidas", "05_mapa_faltantes.png"), width = 1800, height = 900,
    res = 140)
orden <- order(rowSums(is.na(X)), decreasing = TRUE)
sub <- head(orden, min(1500, length(orden)))
image(x = seq_along(vars), y = seq_along(sub),
      z = t(1 * is.na(as.matrix(X[sub, vars, drop = FALSE]))),
      col = c("#2C7FB8", "#D7301F"), axes = FALSE,
      xlab = "Indicadores", ylab = "Personas (hasta 1.500, ordenadas por faltantes)",
      main = "Mapa de datos faltantes: azul = observado; rojo = faltante")
axis(1, at = seq_along(vars), labels = vars, las = 2, cex.axis = 0.65)
dev.off()

png(file.path("salidas", "05_distribuciones_indicadores.png"),
    width = 1800, height = 1200, res = 140)
par(mfrow = c(5, 5), mar = c(3, 3, 2, 1), oma = c(0, 0, 2, 0))
for (v in vars) {
  es_binaria <- v %in% vars_conoc
  lev <- if (es_binaria) c(0, 1) else 1:5
  f <- table(factor(X[[v]], levels = lev))
  barplot(100 * f / sum(f), main = v, xlab = "Categoría", ylab = "%",
          col = "steelblue", cex.names = 0.7)
}
mtext("Response percentages by indicator", outer = TRUE, cex = 1.2)
dev.off()

# 8. Exportación de resultados ------------------------------------------------
write.csv(validacion, "salidas/05_validacion_rangos.csv", row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(faltantes_variable, "salidas/05_faltantes_por_indicador.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(faltantes_persona, "salidas/05_faltantes_por_persona.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(resumen_faltantes_persona, "salidas/05_resumen_faltantes_persona.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(tabla_patrones, "salidas/05_patrones_faltantes.csv", row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(little_out, "salidas/05_prueba_little_mcar.csv", row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(constantes, "salidas/05_patrones_constantes.csv", row.names = FALSE,
          fileEncoding = "UTF-8")
write.csv(multivariado, "salidas/05_atipicos_multivariados_resumen.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(casos_distancia, "salidas/05_atipicos_multivariados_casos.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(descriptivos, "salidas/05_descriptivos_indicadores.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(mardia, "salidas/05_normalidad_mardia.csv", row.names = FALSE,
          fileEncoding = "UTF-8")

cat("Registros analíticos:", nrow(X), " | indicadores:", ncol(X),
    " | IDs duplicados:", duplicados_ids, "\n")
cat("Casos completos:", sum(complete.cases(X)), "de", nrow(X), "\n")
cat("Little MCAR:\n"); print(little_out, row.names = FALSE)
cat("Perfiles constantes por batería:\n"); print(constantes, row.names = FALSE)
cat("Distancia de Mahalanobis (exploratoria):\n"); print(multivariado, row.names = FALSE)
cat("Mardia (submuestra reproducible):\n"); print(mardia, row.names = FALSE)
cat("\nResultados y gráficos guardados en salidas/05_*\n")
sessionInfo()


# --- Sección 7: 06_asociacion_afe.R ---
# Taller 1 SEM - asociaciones, confiabilidad y estructura exploratoria
# Ejecutar desde Taller1_SEM_ECP2023.Rproj. Requiere psych y GPArotation.
.libPaths(c("C:/Users/juanr/AppData/Local/R/win-library/4.6", .libPaths()))
if (!requireNamespace("psych", quietly = TRUE)) stop("Instale psych: install.packages('psych').")
if (!requireNamespace("GPArotation", quietly = TRUE)) stop("Instale GPArotation: install.packages('GPArotation').")

set.seed(20261020)
dir.create("salidas", showWarnings = FALSE)
rutas_zip <- c(democracia = "datos_crudos/Democracia.zip",
               participacion = "datos_crudos/Participacion.zip",
               capital_social = "datos_crudos/Capital_social.zip")
if (any(!file.exists(rutas_zip))) stop("Falta uno o mas ZIP de datos_crudos.")

leer_csv_zip <- function(ruta) {
  miembros <- utils::unzip(ruta, list = TRUE)$Name
  miembros <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE, useBytes = TRUE)]
  if (length(miembros) != 1) stop("Se esperaba un CSV dentro de ", ruta)
  con <- unz(ruta, miembros[[1]], open = "r")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}
modulos <- lapply(rutas_zip, leer_csv_zip)
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
if (any(vapply(modulos, function(x) anyDuplicated(x[ids]) > 0, logical(1))))
  stop("Hay identificadores duplicados en un modulo.")
datos <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE), modulos)
g_inter <- paste0("P2025S", 4:7)
g_inst <- paste0("P5263S", 1:15)
g_conoc <- paste0("P5376S", 1:6)
items <- c(g_inter, g_inst, g_conoc)
if (length(setdiff(items, names(datos)))) stop("No se encontraron todos los indicadores.")
for (v in c(g_inter, g_inst)) datos[[v]][datos[[v]] == 99] <- NA
for (v in g_conoc) datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                                         ifelse(datos[[v]] == 2, 0, NA_real_))
X <- as.data.frame(datos[items])
X[] <- lapply(X, as.numeric)
X <- X[complete.cases(X), , drop = FALSE]
N <- nrow(X)
cat("Casos completos:", N, "de", nrow(datos), "\n")

# Matriz policorica completa: adecuada para indicadores ordinales y dicotomicos.
cat("Calculando matriz policorica completa...\n")
pc <- psych::polychoric(X, progress = FALSE, smooth = TRUE, global = TRUE)
R <- pc$rho
dimnames(R) <- list(items, items)
write.csv(R, "salidas/06_matriz_policorica.csv", fileEncoding = "UTF-8")
min_eig <- min(eigen(R, symmetric = TRUE, only.values = TRUE)$values)
write.csv(data.frame(n = N, p = ncol(R), eigenvalue_minimo = min_eig),
          "salidas/06_diagnostico_matriz.csv", row.names = FALSE)

# Mapa de calor con los indicadores ordenados por constructo.
png("salidas/06_mapa_calor_policoricas.png", width = 2200, height = 1900, res = 180)
par(mar = c(10, 10, 4, 2))
pal <- grDevices::colorRampPalette(c("#2166AC", "#F7F7F7", "#B2182B"))(101)
image(seq_len(ncol(R)), seq_len(nrow(R)), t(R[nrow(R):1, ]), zlim = c(-1, 1),
      col = pal, axes = FALSE, xlab = "", ylab = "", main = "Matriz policorica")
axis(1, at = seq_along(items), labels = items, las = 2, cex.axis = .62)
axis(2, at = seq_along(items), labels = rev(items), las = 2, cex.axis = .62)
abline(v = c(4.5, 19.5), h = c(6.5, 21.5), lwd = 2, lty = 2)
dev.off()

# Alfa ordinal, omega total y correlacion corregida item-resto por bateria.
grupos <- list(Confianza_interpersonal = g_inter,
               Confianza_institucional = g_inst,
               Conocimiento_mecanismos = g_conoc)
fiab <- list(); itemresto <- list()
for (g in names(grupos)) {
  vv <- grupos[[g]]
  al <- psych::alpha(R[vv, vv, drop = FALSE], n.obs = N,
                     check.keys = FALSE, warnings = FALSE)
  om <- tryCatch(suppressWarnings(psych::omega(R[vv, vv, drop = FALSE],
                           nfactors = 1, n.obs = N, plot = FALSE, fm = "minres")),
                 error = function(e) e)
  omega_total <- if (inherits(om, "error")) NA_real_ else as.numeric(om$omega.tot)
  omega_error <- if (inherits(om, "error")) conditionMessage(om) else ""
  fiab[[g]] <- data.frame(constructo = g, n_items = length(vv), n = N,
      alpha_policorico = as.numeric(al$total$raw_alpha),
      omega_total = omega_total, error_omega = omega_error)
  st <- al$item.stats
  itemresto[[g]] <- data.frame(constructo = g, variable = rownames(st),
      correlacion_item_resto = st$r.drop, stringsAsFactors = FALSE)
}
write.csv(do.call(rbind, fiab), "salidas/06_confiabilidad.csv", row.names = FALSE)
write.csv(do.call(rbind, itemresto), "salidas/06_correlacion_item_resto.csv", row.names = FALSE)

# Adecuacion de la matriz para analisis factorial.
kmo <- psych::KMO(R)
bart <- psych::cortest.bartlett(R, n = N, diag = TRUE)
write.csv(data.frame(KMO_global = unname(kmo$MSA),
    Bartlett_chi2 = unname(bart$chisq), Bartlett_gl = unname(bart$df),
    Bartlett_p = unname(bart$p.value), n = N, p = ncol(R)),
    "salidas/06_KMO_Bartlett.csv", row.names = FALSE)
write.csv(data.frame(variable = names(kmo$MSAi), MSA_individual = unname(kmo$MSAi)),
          "salidas/06_KMO_individual.csv", row.names = FALSE)

# Analisis paralelo categorico: 2.500 casos y 30 iteraciones reproducibles.
n_pa <- min(2500L, N)
set.seed(20261020)
X_pa <- X[sample.int(N, n_pa), , drop = FALSE]
cat("Analisis paralelo policorico con n =", n_pa, "y 30 iteraciones...\n")
png("salidas/06_analisis_paralelo.png", width = 1800, height = 1300, res = 150)
pa <- psych::fa.parallel(X_pa, fa = "fa", fm = "minres", cor = "poly",
    n.iter = 30, quant = .95, sim = TRUE, plot = TRUE, correct = .5,
    use = "complete")
dev.off()
n_factores <- as.integer(pa$nfact)
if (length(n_factores) != 1L || is.na(n_factores) || n_factores < 1L)
  stop("El analisis paralelo no devolvio un numero de factores interpretable.")
write.csv(data.frame(n_muestra = n_pa, iteraciones = 30, cuantila = .95,
                     factores_sugeridos = n_factores),
          "salidas/06_resultado_analisis_paralelo.csv", row.names = FALSE)

# AFE MINRES con rotacion oblicua sobre matriz completa.
afe <- psych::fa(R, nfactors = n_factores, n.obs = N, fm = "minres",
                 rotate = "oblimin", residuals = TRUE, SMC = TRUE, warnings = TRUE)
cargas <- as.data.frame(unclass(afe$loadings))
cargas$variable <- rownames(cargas)
cargas$comunalidad <- afe$communality
cargas$complejidad <- afe$complexity
cargas <- cargas[c("variable", setdiff(names(cargas), "variable"))]
write.csv(cargas, "salidas/06_cargas_AFE.csv", row.names = FALSE)
fit_nombres <- c("dof", "chisq", "pval", "RMSEA", "TLI", "BIC", "rms", "crms")
fit_vals <- vapply(fit_nombres, function(nm) {
  z <- afe[[nm]]
  if (is.numeric(z) && length(z) == 1L) as.numeric(z) else NA_real_
}, numeric(1))
write.csv(data.frame(estadistico = fit_nombres, valor = fit_vals),
          "salidas/06_ajuste_AFE.csv", row.names = FALSE)
if (!is.null(afe$Phi)) write.csv(afe$Phi, "salidas/06_correlaciones_factores.csv")
write.csv(as.data.frame(afe$residual), "salidas/06_residuos_AFE.csv")

# Solucion de tres factores fijada por la hipotesis teorica del taller.
afe3 <- psych::fa(R, nfactors = 3, n.obs = N, fm = "minres",
                  rotate = "oblimin", residuals = TRUE, SMC = TRUE, warnings = TRUE)
cargas3 <- as.data.frame(unclass(afe3$loadings))
cargas3$variable <- rownames(cargas3)
cargas3$comunalidad <- afe3$communality
cargas3$complejidad <- afe3$complexity
cargas3 <- cargas3[c("variable", setdiff(names(cargas3), "variable"))]
write.csv(cargas3, "salidas/06_cargas_AFE_3_factores.csv", row.names = FALSE)
write.csv(data.frame(estadistico = fit_nombres, valor = vapply(fit_nombres, function(nm) {
  z <- afe3[[nm]]
  if (is.numeric(z) && length(z) == 1L) as.numeric(z) else NA_real_
}, numeric(1))), "salidas/06_ajuste_AFE_3_factores.csv", row.names = FALSE)
if (!is.null(afe3$Phi)) write.csv(afe3$Phi, "salidas/06_correlaciones_factores_3.csv")
write.csv(as.data.frame(afe3$residual), "salidas/06_residuos_AFE_3_factores.csv")
cat("Listo. Factores sugeridos por paralelo:", n_factores, "\n")
cat("Resultados en salidas/06_*\n")



# --- Sección 8: 07_especificacion_modelo.R ---
# Taller 1 SEM - especificacion teorica del modelo ECP 2023
# Ejecutar desde Taller1_SEM_ECP2023.Rproj.
# No estima el modelo: exporta sintaxis, conteos y parametros para el reporte.
set.seed(20261020)
dir.create("salidas", showWarnings = FALSE, recursive = TRUE)

items_interpersonal <- paste0("P2025S", 4:7)
items_institucional <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items_modelo <- c(items_interpersonal, items_institucional, items_conocimiento)

cargas_libres <- (length(items_interpersonal) - 1L) +
  (length(items_institucional) - 1L) + (length(items_conocimiento) - 1L)
varianzas_residuales_continuas <- length(items_modelo)
phi_libres <- 3L
gamma_libres <- 2L
psi_libres <- 1L
t_covarianzas <- cargas_libres + varianzas_residuales_continuas +
  phi_libres + gamma_libres + psi_libres
k <- length(items_modelo)
momentos_covarianza <- k * (k + 1L) / 2L
gl_covarianza <- momentos_covarianza - t_covarianzas

n_ordinales_5_cat <- length(items_interpersonal) + length(items_institucional)
n_binarios <- length(items_conocimiento)
umbrales <- n_ordinales_5_cat * 4L + n_binarios
estadisticas_ordinales <- choose(k, 2L) + umbrales
parametros_ordinales_libres <- cargas_libres + phi_libres +
  gamma_libres + psi_libres + umbrales
gl_ordinal <- estadisticas_ordinales - parametros_ordinales_libres

modelo_referencia <- paste0(
  "ConfianzaInterpersonal =~ 1*", items_interpersonal[1], " + ",
  paste(items_interpersonal[-1], collapse = " + "), "\n",
  "ConfianzaInstitucional =~ 1*", items_institucional[1], " + ",
  paste(items_institucional[-1], collapse = " + "), "\n",
  "ConocimientoMecanismos =~ 1*", items_conocimiento[1], " + ",
  paste(items_conocimiento[-1], collapse = " + "), "\n",
  "ConocimientoMecanismos ~ gamma_interpersonal*ConfianzaInterpersonal + ",
  "gamma_institucional*ConfianzaInstitucional\n",
  "ConfianzaInterpersonal ~~ phi_interpersonal*ConfianzaInterpersonal\n",
  "ConfianzaInstitucional ~~ phi_institucional*ConfianzaInstitucional\n",
  "ConfianzaInterpersonal ~~ phi_12*ConfianzaInstitucional\n",
  "ConocimientoMecanismos ~~ psi_11*ConocimientoMecanismos"
)

modelo_rival <- paste0(
  "ConfianzaInterpersonal =~ 1*", items_interpersonal[1], " + ",
  paste(items_interpersonal[-1], collapse = " + "), "\n",
  "ConfianzaInstitucional =~ 1*", items_institucional[1], " + ",
  paste(items_institucional[-1], collapse = " + "), "\n",
  "ConocimientoMecanismos =~ 1*", items_conocimiento[1], " + ",
  paste(items_conocimiento[-1], collapse = " + "), "\n",
  "ConfianzaInterpersonal ~ alpha_interpersonal*ConocimientoMecanismos\n",
  "ConfianzaInstitucional ~ alpha_institucional*ConocimientoMecanismos\n",
  "ConocimientoMecanismos ~~ var_conocimiento*ConocimientoMecanismos\n",
  "ConfianzaInterpersonal ~~ psi_interpersonal*ConfianzaInterpersonal\n",
  "ConfianzaInstitucional ~~ psi_institucional*ConfianzaInstitucional\n",
  "ConfianzaInterpersonal ~~ psi_residual_12*ConfianzaInstitucional"
)

conteo <- data.frame(
  parametro = c("Cargas libres", "Varianzas residuales indicadores (covarianzas)",
                "Elementos libres de Phi", "Coeficientes Gamma",
                "Elementos libres de Psi", "t covarianzas", "Momentos de covarianza",
                "gl covarianzas", "Umbrales ordinales", "Estadisticas muestrales ordinales",
                "Parametros libres ordinales (delta)", "gl ordinales esperados"),
  valor = c(cargas_libres, varianzas_residuales_continuas, phi_libres,
            gamma_libres, psi_libres, t_covarianzas, momentos_covarianza,
            gl_covarianza, umbrales, estadisticas_ordinales,
            parametros_ordinales_libres, gl_ordinal)
)
if (t_covarianzas != 53L || gl_covarianza != 272L ||
    parametros_ordinales_libres != 110L || gl_ordinal != 272L) {
  stop("El conteo no coincide con la especificacion documentada.")
}

writeLines(modelo_referencia, "salidas/07_sintaxis_modelo_referencia.txt", useBytes = TRUE)
writeLines(modelo_rival, "salidas/07_sintaxis_modelo_rival.txt", useBytes = TRUE)
utils::write.csv(conteo, "salidas/07_conteo_parametros.csv", row.names = FALSE)
cat("Modelo de referencia y rival exportados a salidas/.\n")
print(conteo, row.names = FALSE)
cat("\nSession info:\n")
print(sessionInfo())



# 2. Lectura focalizada e integración de módulos -----------------------------
leer_csv_zip_entrega <- function(ruta_zip) {
  miembros <- utils::unzip(ruta_zip, list = TRUE)$Name
  miembros <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE,
                             useBytes = TRUE)]
  if (length(miembros) != 1L) {
    stop("Se esperaba un solo CSV dentro de ", ruta_zip,
         "; encontrados: ", length(miembros))
  }
  con <- unz(ruta_zip, miembros[[1]], open = "r")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
vars_interpersonal <- paste0("P2025S", 4:7)
vars_institucional <- paste0("P5263S", 1:15)
vars_mecanismos <- paste0("P5376S", 1:6)
vars_modelo <- c(vars_interpersonal, vars_institucional, vars_mecanismos)
vars_demo <- c("P6008", "P220", "P5785", "P5465", "P6050", "P605",
               "P6160", "P8586", "P6210")

modulos <- list(
  democracia = leer_csv_zip_entrega(file.path("datos_crudos", "Democracia.zip")),
  participacion = leer_csv_zip_entrega(file.path("datos_crudos", "Participacion.zip")),
  capital_social = leer_csv_zip_entrega(file.path("datos_crudos", "Capital_social.zip")),
  caracteristicas = leer_csv_zip_entrega(file.path("datos_crudos", "Caracteristicas_generales.zip"))
)

requeridas_por_modulo <- list(
  democracia = c(ids, vars_institucional),
  participacion = c(ids, vars_mecanismos),
  capital_social = c(ids, vars_interpersonal),
  caracteristicas = c(ids, vars_demo)
)
for (nm in names(modulos)) {
  ausentes <- setdiff(requeridas_por_modulo[[nm]], names(modulos[[nm]]))
  if (length(ausentes)) stop("En módulo ", nm, " faltan: ", paste(ausentes, collapse = ", "))
  modulos[[nm]] <- modulos[[nm]][requeridas_por_modulo[[nm]]]
  if (anyDuplicated(modulos[[nm]][ids])) stop("IDs repetidos en módulo ", nm)
}

base_analitica <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE,
                                               sort = FALSE), modulos)
if (anyDuplicated(base_analitica[ids])) stop("IDs repetidos tras integrar los cuatro módulos")
base_analitica$P6210[base_analitica$P6210 == 99] <- NA_real_
for (v in c(vars_interpersonal, vars_institucional)) {
  base_analitica[[v]][base_analitica[[v]] == 99] <- NA_real_
}
for (v in vars_mecanismos) {
  base_analitica[[v]] <- ifelse(base_analitica[[v]] == 1, 1,
                                ifelse(base_analitica[[v]] == 2, 0, NA_real_))
}
base_analitica$n_items_faltantes <- rowSums(is.na(base_analitica[vars_modelo]))
base_analitica$caso_completo_modelo <- base_analitica$n_items_faltantes == 0L
base_analitica <- base_analitica[c(ids, vars_demo, vars_modelo,
                                   "n_items_faltantes", "caso_completo_modelo")]

# 3. Diccionario de variables ------------------------------------------------
etiquetas <- c(
  P2025S4="Confianza en personas desconocidas", P2025S5="Confianza en vecinos(as)",
  P2025S6="Confianza en amistades", P2025S7="Confianza en personas de otra nacionalidad",
  P5263S1="Confianza en Procuraduría General de la Nación",
  P5263S2="Confianza en Alcaldía Municipal/Distrital", P5263S3="Confianza en Fuerzas Militares",
  P5263S4="Confianza en Congreso de la República", P5263S5="Confianza en jueces y magistrados",
  P5263S6="Confianza en Asamblea departamental", P5263S7="Confianza en Contraloría",
  P5263S8="Confianza en concejos municipales/distritales", P5263S9="Confianza en Policía",
  P5263S10="Confianza en partidos o movimientos políticos", P5263S11="Confianza en Defensoría del Pueblo",
  P5263S12="Confianza en Gobernación", P5263S13="Confianza en Fiscalía General de la Nación",
  P5263S14="Confianza en Registraduría Nacional del Estado Civil",
  P5263S15="Confianza en Presidencia de la República",
  P5376S1="Conoce revocatoria del mandato",
  P5376S2="Conoce iniciativa popular legislativa o normativa",
  P5376S3="Conoce referendo aprobatorio o derogatorio", P5376S4="Conoce plebiscito",
  P5376S5="Conoce consulta popular", P5376S6="Conoce cabildo abierto"
)
enunciados <- c(
  P2025S4="¿Cuánta confianza le inspira la mayoría de las personas desconocidas?",
  P2025S5="¿Cuánta confianza le inspiran sus vecinos(as)?",
  P2025S6="¿Cuánta confianza le inspiran sus amistades?",
  P2025S7="¿Cuánta confianza le inspiran las personas de otra nacionalidad?",
  P5263S1="¿Cuánta confianza le inspira cada institución o actor público?",
  P5376S1="¿Conoce o ha oído hablar de este mecanismo de participación?"
)
demo_labels <- c(P6008="Número de personas en el hogar", P220="Sexo",
  P5785="Edad", P5465="Autoidentificación étnica", P6050="Relación con la jefatura del hogar",
  P605="Estado civil", P6160="Sabe leer y escribir", P8586="Asiste actualmente a institución educativa",
  P6210="Nivel educativo más alto alcanzado")
diccionario <- data.frame(
  nombre = c(ids, vars_demo, vars_modelo, "n_items_faltantes", "caso_completo_modelo"),
  etiqueta = c(rep("Identificador DANE de persona", length(ids)), unname(demo_labels[vars_demo]),
    unname(etiquetas[vars_modelo]), "Cantidad de indicadores del modelo sin respuesta",
    "Indicador lógico de respuesta completa en los 25 ítems"),
  enunciado = c(rep("Identificador de la unidad encuestada; combinación de campos del DANE.", length(ids)),
    paste("Variable de caracterización personal/hogar ECP 2023.", unname(demo_labels[vars_demo])),
    vapply(vars_modelo, function(v) {
      if (v %in% names(enunciados)) unname(enunciados[[v]]) else if (grepl("^P5263", v))
        unname(enunciados[["P5263S1"]]) else unname(enunciados[["P5376S1"]])
    }, character(1)),
    "Conteo calculado después de recodificar los valores especiales como faltantes.",
    "TRUE si los 25 indicadores recodificados están observados; FALSE en otro caso."),
  constructo = c(rep("Identificación", length(ids)), rep("Caracterización sociodemográfica", length(vars_demo)),
    rep("Confianza interpersonal", length(vars_interpersonal)),
    rep("Confianza institucional", length(vars_institucional)),
    rep("Familiaridad autorreportada con mecanismos", length(vars_mecanismos)),
    "Calidad de datos", "Calidad de datos"),
  tipo = c(rep("Identificador", length(ids)), rep("Categórica/cuantitativa según variable DANE", length(vars_demo)),
    rep("Ordinal", length(vars_interpersonal) + length(vars_institucional)),
    rep("Dicotómica", length(vars_mecanismos)), "Conteo", "Lógica"),
  categorias_y_codigos = c(rep("Código original DANE; no usar como magnitud.", length(ids)),
    c("Número de personas en el hogar", "1=Hombre; 2=Mujer",
      "Edad en años cumplidos", "1=Indígena; 2=Gitano(a)-rom; 3=Raizal; 4=Palenquero(a); 5=Negro(a)/afrodescendiente; 6=Ninguna de las anteriores",
      "1=Jefatura; 2=Pareja; 3=Hijo(a); 4=Nieto(a); 5=Otro pariente; 6=Servicio doméstico; 7=Pensionista; 8=Trabajador; 9=Otro no pariente",
      "1=Unión <2 años; 2=Unión >=2 años; 3=Casado(a); 4=Separado(a)/divorciado(a); 5=Viudo(a); 6=Soltero(a)",
      "1=Sí; 2=No", "1=Sí; 2=No",
      "1=Ninguno; 2=Preescolar; 3=Primaria; 4=Secundaria; 5=Media; 6=Superior; 7=Posgrado; 99=No sabe/no informa (NA en esta base)"),
    rep("1 a 5; 99=No sabe/No informa antes de recodificar (NA en esta base)",
        length(vars_interpersonal) + length(vars_institucional)),
    rep("1=Sí conoce/ha oído; 0=No conoce (recodificado desde 1/2)", length(vars_mecanismos)),
    "0 a 25", "TRUE/FALSE"),
  sentido = c(rep("No aplica", length(ids) + length(vars_demo)), rep("Directo: más alto = más confianza", length(vars_interpersonal) + length(vars_institucional)),
    rep("Directo: 1 = mayor familiaridad", length(vars_mecanismos)), "No aplica", "No aplica"),
  recodificacion = c(rep("Sin recodificación", length(ids) + length(vars_demo)),
    rep("99 a NA; se conservan 1-5", length(vars_interpersonal) + length(vars_institucional)),
    rep("1 a 1 (sí); 2 a 0 (no); otros códigos a NA", length(vars_mecanismos)),
    "Calculado sobre los 25 indicadores recodificados", "TRUE cuando n_items_faltantes=0"),
  nombre_original_fuente = c(ids, vars_demo, vars_modelo, "Derivada", "Derivada"),
  fuente = c(rep("DANE ECP 2023; ZIP de microdatos", length(ids) + length(vars_demo) + length(vars_modelo)),
    "Cálculo reproducible", "Cálculo reproducible"),
  stringsAsFactors = FALSE, check.names = FALSE
)
diccionario$recodificacion[diccionario$nombre == "P6210"] <- "99 a NA; demás categorías conservadas"

# 4. Metadatos y flujo de registros ------------------------------------------
diag <- utils::read.csv(file.path("salidas", "00_diagnostico_modulos.csv"), check.names = FALSE)
n_completos <- sum(base_analitica$caso_completo_modelo)
metadatos <- data.frame(
  campo = c("Título", "Entidad", "Operación estadística", "Año de referencia",
    "Unidad de observación", "Cobertura", "Diseño muestral declarado", "Tamaño crudo por módulo",
    "Intersección integrada", "Casos completos en 25 indicadores", "Criterio de unión",
    "Recodificación", "Variables de diseño disponibles", "Limitación del diseño",
    "Fecha de descarga de microdatos", "URL del catálogo", "Términos de uso y atribución"),
  valor = c("Taller 1 SEM – ECP Colombia 2023", "Departamento Administrativo Nacional de Estadística (DANE)",
    "Encuesta de Cultura Política (ECP)", "2023", "Persona encuestada de 18 años o más",
    "Cobertura nacional; excluye territorios nacionales y San Andrés, Providencia y Santa Catalina, según ficha metodológica DANE",
    "Probabilístico, estratificado, multietápico y por conglomerados (ficha técnica DANE)",
    paste(paste(diag$modulo, diag$n_filas, sep = "="), collapse = "; "),
    as.character(nrow(base_analitica)), paste0(n_completos, " (", round(100*n_completos/nrow(base_analitica), 2), "%)"),
    "Intersección por DIRECTORIO, NRO_ENCUESTA, HOGAR_NUMERO y PERSONA_NUMERO en cuatro módulos",
    "99 a faltante en confianza; P5376 1=Sí y 2=No se transforman en 1/0; faltantes como NA/celdas vacías",
    "No se identificaron ponderador, estrato ni conglomerado en los cuatro ZIP usados",
    "Estimaciones sin ponderar y sin corrección por diseño complejo; evitar inferencia poblacional basada en errores estándar de diseño",
    "2026-10-19", "https://microdatos.dane.gov.co/index.php/catalog/822",
    "Fuente: Departamento Administrativo Nacional de Estadística: www.dane.gov.co. Los microdatos se descargaron para el trabajo académico. Respetar las condiciones ANDA/DANE; no redistribuir públicamente los microdatos sin autorización escrita previa."),
  stringsAsFactors = FALSE
)
flujo <- data.frame(paso = c("Democracia", "Participación", "Capital social", "Características generales",
  "Intersección de los cuatro módulos", "Casos completos en 25 ítems"),
  registros = c(diag$n_filas[match(c("democracia", "participacion", "capital_social", "caracteristicas_generales"), diag$modulo)],
    nrow(base_analitica), n_completos),
  criterio = c(rep("Filas en archivo crudo del módulo", 4), "Unión interna por cuatro identificadores; sin duplicados", "Completo en los 25 indicadores recodificados"),
  stringsAsFactors = FALSE)
metadatos <- rbind(metadatos, data.frame(campo = paste0("Flujo: ", flujo$paso), valor = as.character(flujo$registros)))

# 5. Exportación del libro Excel ---------------------------------------------
ruta_xlsx <- file.path("outputs", "01a15760-d284-7790-91e9-a88837c249b8", "Taller1_SEM_base.xlsx")
writexl::write_xlsx(list(datos = base_analitica, diccionario = diccionario,
                         metadatos = metadatos), path = ruta_xlsx)
message("Libro generado: ", ruta_xlsx)

# 6. Archivos auxiliares para auditoría y reporte ----------------------------
utils::write.csv(base_analitica, file.path("salidas", "base_analitica.csv"),
                 row.names = FALSE, na = "", fileEncoding = "UTF-8")
utils::write.csv(diccionario, file.path("salidas", "diccionario.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(metadatos, file.path("salidas", "metadatos.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

# 7. Información de la sesión ------------------------------------------------
sessionInfo()
