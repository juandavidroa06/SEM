# Taller 2: preparación reproducible de datos y especificaciones
# Ejecutar desde el proyecto RStudio; no versionar datos_crudos ni base integrada.
set.seed(2026)
# Si existe, agrega la biblioteca estándar de paquetes de usuario de Windows.
lib_usuario <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library",
                         paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1]))
if (nzchar(Sys.getenv("USERPROFILE")) && dir.exists(lib_usuario))
  .libPaths(c(lib_usuario, .libPaths()))

leer_csv_zip <- function(ruta_zip) {
  miembros <- utils::unzip(ruta_zip, list = TRUE)$Name
  miembros <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE, useBytes = TRUE)]
  if (length(miembros) != 1L) stop("Se esperaba un CSV en: ", ruta_zip)
  con <- unz(ruta_zip, miembros[[1]], open = "r")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

archivos <- c("Democracia.zip", "Participacion.zip", "Capital_social.zip",
              "Caracteristicas_generales.zip", "Caracteriasticas generales 2.zip")
rutas <- file.path("datos_crudos", archivos)
if (any(!file.exists(rutas))) stop("Faltan ZIP en datos_crudos/: ",
  paste(archivos[!file.exists(rutas)], collapse = ", "))
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
mods <- lapply(rutas, leer_csv_zip)
if (any(vapply(mods, function(x) anyDuplicated(x[ids]) > 0L, logical(1))))
  stop("Hay claves persona duplicadas en los módulos.")
datos <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE), mods)

# Taller 1 no tenía FEX_P en los cuatro ZIP temáticos; aquí se incorpora la
# Tabla de viviendas y se enlaza por DIRECTORIO, tal como permite el DANE.
viviendas <- leer_csv_zip(file.path("datos_crudos", "Tabla de viviendas.zip"))
if (anyDuplicated(viviendas$DIRECTORIO)) stop("DIRECTORIO duplicado en viviendas.")
viviendas$FEX_P <- as.numeric(gsub(",", ".", as.character(viviendas$FEX_P), fixed = TRUE))
datos <- merge(datos, viviendas[c("DIRECTORIO", "FEX_P", "REGION", "P3")],
               by = "DIRECTORIO", all.x = TRUE, sort = FALSE)
if (anyNA(datos$FEX_P) || any(!is.finite(datos$FEX_P)) || any(datos$FEX_P <= 0))
  stop("FEX_P ausente, inválido o no positivo tras el enlace.")

items_interpersonal <- paste0("P2025S", 4:7)
items_institucional <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items <- c(items_interpersonal, items_institucional, items_conocimiento)
if (length(setdiff(items, names(datos)))) stop("Faltan indicadores aprobados en los módulos.")
for (v in c(items_interpersonal, items_institucional)) datos[[v]][datos[[v]] == 99] <- NA
for (v in items_conocimiento)
  datos[[v]] <- ifelse(datos[[v]] == 1, 1, ifelse(datos[[v]] == 2, 0, NA_real_))
for (v in items) datos[[v]] <- ordered(datos[[v]],
  levels = if (v %in% items_conocimiento) c(0, 1) else 1:5)
datos$sexo <- factor(datos$P220, levels = c(1, 2), labels = c("Hombre", "Mujer"))

modelo_medicion <- paste(
  paste0("ConfianzaInterpersonal =~ ", paste(items_interpersonal, collapse = " + ")),
  paste0("ConfianzaInstitucional =~ ", paste(items_institucional, collapse = " + ")),
  paste0("ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")),
  sep = "\n")
modelo_sem <- paste(modelo_medicion,
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaInstitucional",
  "ConfianzaInterpersonal ~~ ConfianzaInstitucional", sep = "\n")
modelo_rival <- paste(modelo_medicion,
  "ConfianzaInterpersonal ~ ConocimientoMecanismos",
  "ConfianzaInstitucional ~ ConocimientoMecanismos",
  "ConfianzaInterpersonal ~~ ConfianzaInstitucional", sep = "\n")
modelo_alt <- paste(
  paste0("ConfianzaInterpersonal =~ ", paste(items_interpersonal, collapse = " + ")),
  paste0("ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")),
  "ConfianzaRepresentacionGobierno =~ P5263S2 + P5263S4 + P5263S6 + P5263S8 + P5263S10 + P5263S12 + P5263S14 + P5263S15",
  "ConfianzaJusticiaControlProteccionSeguridad =~ P5263S1 + P5263S3 + P5263S5 + P5263S7 + P5263S9 + P5263S11 + P5263S13",
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaRepresentacionGobierno + ConfianzaJusticiaControlProteccionSeguridad",
  "ConfianzaInterpersonal ~~ ConfianzaRepresentacionGobierno",
  "ConfianzaInterpersonal ~~ ConfianzaJusticiaControlProteccionSeguridad",
  "ConfianzaRepresentacionGobierno ~~ ConfianzaJusticiaControlProteccionSeguridad", sep = "\n")
opts <- list(data = datos, ordered = items, estimator = "WLSMV",
             missing = "pairwise", sampling.weights = "FEX_P")
dir.create("salidas", showWarnings = FALSE)
cat("Preparación terminada:", nrow(datos), "personas;", length(items), "indicadores.\n")
sessionInfo()
