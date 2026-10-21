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
