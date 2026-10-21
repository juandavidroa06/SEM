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
