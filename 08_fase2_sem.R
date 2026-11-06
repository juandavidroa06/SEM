# Taller 2 - Fases 2 y 3 (analisis ponderado y multigrupo)
# Ejecutar desde Taller1_SEM_ECP2023.Rproj. Los ZIP oficiales permanecen locales.
# La encuesta publica FEX_P a nivel de vivienda; se enlaza por DIRECTORIO.
# No se inventa cluster/estrato: esos identificadores no aparecen en los archivos
# anonimizados usados. Por tanto, los errores estandar no son plenamente
# corregidos por el diseno complejo; ver 08_hallazgos_muestreo_efectos.md.

set.seed(2026)

# Usa las bibliotecas R configuradas en el equipo; no presupone rutas locales.
lib_usuario <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library",
                         paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1]))
if (nzchar(Sys.getenv("USERPROFILE")) && dir.exists(lib_usuario)) .libPaths(c(lib_usuario, .libPaths()))

leer_csv_zip <- function(ruta_zip) {
  miembros <- utils::unzip(ruta_zip, list = TRUE)$Name
  miembros <- miembros[grepl("\\.csv$", miembros, ignore.case = TRUE,
                             useBytes = TRUE)]
  if (length(miembros) != 1) stop("Se esperaba un CSV en: ", ruta_zip)
  con <- unz(ruta_zip, miembros[[1]], open = "r")
  on.exit(close(con), add = TRUE)
  utils::read.csv(con, check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c("", "NA"))
}

zip_dir <- "datos_crudos"
archivos <- c("Democracia.zip", "Participacion.zip", "Capital_social.zip",
              "Caracteristicas_generales.zip",
              "Caracteriasticas generales 2.zip")
faltan <- file.path(zip_dir, archivos)[!file.exists(file.path(zip_dir, archivos))]
if (length(faltan)) stop("Faltan archivos: ", paste(faltan, collapse = ", "))
ids <- c("DIRECTORIO", "NRO_ENCUESTA", "HOGAR_NUMERO", "PERSONA_NUMERO")
mods <- lapply(file.path(zip_dir, archivos), leer_csv_zip)
if (any(vapply(mods, function(x) anyDuplicated(x[ids]) > 0, logical(1)))) {
  stop("Hay claves persona duplicadas; no se puede integrar con seguridad.")
}
datos <- Reduce(function(x, y) merge(x, y, by = ids, all = FALSE, sort = FALSE), mods)

# Tabla de viviendas: una fila por DIRECTORIO y un factor FEX_P por vivienda.
viviendas <- leer_csv_zip(file.path(zip_dir, "Tabla de viviendas.zip"))
if (anyDuplicated(viviendas$DIRECTORIO)) stop("DIRECTORIO duplicado en Tabla de viviendas.")
viviendas$FEX_P <- as.numeric(gsub(",", ".", as.character(viviendas$FEX_P),
                                   fixed = TRUE))
datos <- merge(datos, viviendas[c("DIRECTORIO", "FEX_P", "REGION", "P3")],
               by = "DIRECTORIO", all.x = TRUE, sort = FALSE)
if (anyNA(datos$FEX_P) || any(!is.finite(datos$FEX_P)) || any(datos$FEX_P <= 0)) {
  stop("FEX_P ausente, no numerico o no positivo tras unir por DIRECTORIO.")
}
if (!"P220" %in% names(datos)) stop("No se encontro P220 (sexo) para multigrupo.")

items_interpersonal <- paste0("P2025S", 4:7)
items_institucional <- paste0("P5263S", 1:15)
items_conocimiento <- paste0("P5376S", 1:6)
items <- c(items_interpersonal, items_institucional, items_conocimiento)
if (length(setdiff(items, names(datos)))) stop("No se encontraron todos los indicadores del modelo.")
for (v in c(items_interpersonal, items_institucional)) {
  datos[[v]][datos[[v]] == 99] <- NA
}
for (v in items_conocimiento) {
  datos[[v]] <- ifelse(datos[[v]] == 1, 1,
                       ifelse(datos[[v]] == 2, 0, NA_real_))
}
for (v in items) {
  niveles <- if (v %in% items_conocimiento) c(0, 1) else 1:5
  datos[[v]] <- ordered(datos[[v]], levels = niveles)
}
datos$sexo <- factor(datos$P220, levels = c(1, 2),
                     labels = c("Hombre", "Mujer"))
datos$region <- factor(datos$REGION, levels = 1:5,
                       labels = c("Bogota", "Caribe", "Oriental", "Central", "Pacifico"))

dir.create("salidas", showWarnings = FALSE, recursive = TRUE)
completos <- complete.cases(datos[items])
neff_kish <- function(w) sum(w)^2 / sum(w^2)
diseno <- data.frame(
  indicador = c("Personas integradas", "Personas con 25 indicadores completos"),
  n_no_ponderado = c(nrow(datos), sum(completos)),
  suma_FEX_P = c(sum(datos$FEX_P), sum(datos$FEX_P[completos])),
  n_efectivo_Kish_solo_por_pesos = c(neff_kish(datos$FEX_P),
                                      neff_kish(datos$FEX_P[completos]))
)
utils::write.csv(diseno, "salidas/08_diseno_muestral.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(as.data.frame(table(datos$region, useNA = "ifany")),
                 "salidas/08_grupos_region.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
grupos_sexo <- do.call(rbind, lapply(levels(datos$sexo), function(g) {
  ix <- !is.na(datos$sexo) & datos$sexo == g
  data.frame(sexo = g, n = sum(ix), suma_FEX_P = sum(datos$FEX_P[ix]),
             n_efectivo_Kish_solo_por_pesos = neff_kish(datos$FEX_P[ix]))
}))
utils::write.csv(grupos_sexo, "salidas/08_grupos_sexo.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")

if (!requireNamespace("lavaan", quietly = TRUE)) {
  stop("Diagnosticos ponderados guardados. Para estimar los modelos instale lavaan.")
}
if (!requireNamespace("semTools", quietly = TRUE)) {
  stop("Falta semTools para confiabilidad, HTMT e invariancia ordinal.")
}

modelo_medicion <- paste(
  paste0("ConfianzaInterpersonal =~ ", paste(items_interpersonal, collapse = " + ")),
  paste0("ConfianzaInstitucional =~ ", paste(items_institucional, collapse = " + ")),
  paste0("ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")),
  sep = "\n"
)
modelo_sem <- paste(modelo_medicion,
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaInstitucional",
  "ConfianzaInterpersonal ~~ ConfianzaInstitucional", sep = "\n")
modelo_alt <- paste(
  paste0("ConfianzaInterpersonal =~ ", paste(items_interpersonal, collapse = " + ")),
  paste0("ConocimientoMecanismos =~ ", paste(items_conocimiento, collapse = " + ")),
  "ConfianzaRepresentacionGobierno =~ P5263S2 + P5263S4 + P5263S6 + P5263S8 + P5263S10 + P5263S12 + P5263S14 + P5263S15",
  "ConfianzaJusticiaControlProteccionSeguridad =~ P5263S1 + P5263S3 + P5263S5 + P5263S7 + P5263S9 + P5263S11 + P5263S13",
  "ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaRepresentacionGobierno + ConfianzaJusticiaControlProteccionSeguridad",
  "ConfianzaInterpersonal ~~ ConfianzaRepresentacionGobierno",
  "ConfianzaInterpersonal ~~ ConfianzaJusticiaControlProteccionSeguridad",
  "ConfianzaRepresentacionGobierno ~~ ConfianzaJusticiaControlProteccionSeguridad",
  sep = "\n")
opts <- list(data = datos, ordered = items, estimator = "WLSMV",
             missing = "pairwise", sampling.weights = "FEX_P")
afc <- do.call(lavaan::cfa, c(list(model = modelo_medicion), opts))
sem <- do.call(lavaan::sem, c(list(model = modelo_sem), opts))
alt <- do.call(lavaan::sem, c(list(model = modelo_alt), opts))

fit_names <- c("chisq", "chisq.scaled", "df", "pvalue", "pvalue.scaled", "cfi.robust", "tli.robust",
               "rmsea.robust", "rmsea.ci.lower.robust", "rmsea.ci.upper.robust",
               "cfi.scaled", "tli.scaled", "rmsea.scaled", "rmsea.ci.lower", "rmsea.ci.upper", "cfi", "tli", "rmsea", "srmr")
fits <- list(AFC_correlacionado = afc, SEM_referencia = sem,
             SEM_institucional_2D_exploratorio = alt)
fit_table <- do.call(rbind, lapply(names(fits), function(nm) {
  f <- fits[[nm]]; m <- lavaan::fitMeasures(f)
  data.frame(modelo = nm, n = sum(lavaan::lavInspect(f, "nobs")),
             convergio = lavaan::inspect(f, "converged"),
             as.list(m[intersect(fit_names, names(m))]), check.names = FALSE)
}))
utils::write.csv(fit_table, "salidas/08_ajuste.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(lavaan::parameterEstimates(afc, standardized = TRUE),
                 "salidas/08_parametros_afc.csv", row.names = FALSE, fileEncoding = "UTF-8")
pe <- lavaan::parameterEstimates(sem, standardized = TRUE)
rutas <- pe[pe$op == "~", , drop = FALSE]
rutas$hipotesis <- ifelse(rutas$rhs == "ConfianzaInterpersonal", "H1", "H2")
rutas$p_unilateral_signo_positivo <- ifelse(
  rutas$est >= 0, rutas$pvalue / 2, 1 - rutas$pvalue / 2)
rutas$decision_unilateral <- ifelse(rutas$p_unilateral_signo_positivo < .05,
  "apoyo estadistico al signo positivo", "sin apoyo estadistico al signo positivo")
utils::write.csv(rutas, "salidas/08_hipotesis.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(lavaan::standardizedSolution(sem, ci = TRUE),
                 "salidas/08_solucion_estandarizada.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
rsq <- lavaan::lavInspect(sem, "r2")
utils::write.csv(data.frame(constructo = "ConocimientoMecanismos",
                            R2 = unname(rsq["ConocimientoMecanismos"])),
                 "salidas/08_R2.csv", row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(semTools::compRelSEM(afc), "salidas/08_confiabilidad.csv",
                 fileEncoding = "UTF-8")
utils::write.csv(semTools::AVE(afc), "salidas/08_AVE.csv", fileEncoding = "UTF-8")
utils::write.csv(as.data.frame(semTools::htmt(modelo_medicion, data = datos,
                                               ordered = items)),
                 "salidas/08_HTMT.csv", fileEncoding = "UTF-8")
utils::write.csv(lavaan::modificationIndices(afc, sort. = TRUE, minimum.value = 10),
                 "salidas/08_indices_modificacion.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
residuos_cor <- lavaan::lavResiduals(afc, type = "cor")$cov
utils::write.csv(as.data.frame(as.table(as.matrix(residuos_cor))),
                 "salidas/08_residuos_correlacion.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
# No hay mediador en el modelo aprobado; no se calcula un efecto indirecto.
# Los betas estandarizados, sus IC y R2 son los tamaños de asociación principales.
r2_full <- lavaan::lavInspect(sem, "r2")["ConocimientoMecanismos"]
beta_tab <- pe[pe$op == "~" & pe$lhs == "ConocimientoMecanismos", , drop = FALSE]
beta <- stats::setNames(beta_tab$std.all, beta_tab$rhs)
r_latente <- lavaan::lavInspect(sem, "cor.lv")[
  "ConfianzaInterpersonal", "ConfianzaInstitucional"]
unicos <- beta^2 * (1 - r_latente^2)
efectos <- data.frame(
  predictor = c("ConfianzaInterpersonal", "ConfianzaInstitucional"),
  R2_completo = as.numeric(r2_full),
  R2_unico_incremental = as.numeric(unicos[c("ConfianzaInterpersonal",
                                              "ConfianzaInstitucional")]),
  f2_incremental = as.numeric(unicos[c("ConfianzaInterpersonal",
                                        "ConfianzaInstitucional")]) / (1 - r2_full)
)
utils::write.csv(efectos, "salidas/08_tamanos_efecto.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(as.data.frame(lavaan::lavTestLRT(afc, sem)),
                 "salidas/08_comparacion_afc_sem.csv", fileEncoding = "UTF-8")

# Invariancia ordinal por sexo: identificacion Wu-Estabrook (2016).
# El grupo es suficientemente grande y evita la pérdida completa de Bogotá
# que causa la no aplicabilidad de dos ítems institucionales.
if (any(table(datos$sexo) < 200)) stop("Grupo de sexo con menos de 200 casos.")
invar <- list()
for (nivel in c("configural", "umbrales", "metrica_ordinal")) {
  iguales <- switch(nivel, configural = character(0), umbrales = "thresholds",
                    metrica_ordinal = c("thresholds", "loadings"))
  syntax <- semTools::measEq.syntax(configural.model = modelo_medicion,
    data = datos, group = "sexo", ordered = items, parameterization = "theta",
    ID.fac = "std.lv", ID.cat = "Wu.Estabrook.2016", group.equal = iguales)
  invar[[nivel]] <- lavaan::cfa(as.character(syntax), data = datos, group = "sexo",
    ordered = items, estimator = "WLSMV", missing = "pairwise",
    sampling.weights = "FEX_P", parameterization = "theta")
}
invar_fit <- do.call(rbind, lapply(names(invar), function(nm) {
  f <- invar[[nm]]; m <- lavaan::fitMeasures(f)
  data.frame(modelo = nm, n = sum(lavaan::lavInspect(f, "nobs")),
             as.list(m[intersect(fit_names, names(m))]), check.names = FALSE)
}))
utils::write.csv(invar_fit, "salidas/08_invarianza_sexo.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(lavaan::parameterEstimates(invar$metrica_ordinal, standardized = TRUE),
                 "salidas/08_invarianza_parametros.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
# Cambios de indices aproximados entre niveles de invarianza.
dif_fit <- data.frame(
  paso = c("configural_a_umbrales", "umbrales_a_metrica_ordinal"),
  delta_CFI_escalado = c(
    lavaan::fitMeasures(invar$umbrales, "cfi.scaled") - lavaan::fitMeasures(invar$configural, "cfi.scaled"),
    lavaan::fitMeasures(invar$metrica_ordinal, "cfi.scaled") - lavaan::fitMeasures(invar$umbrales, "cfi.scaled")),
  delta_RMSEA_escalado = c(
    lavaan::fitMeasures(invar$umbrales, "rmsea.scaled") - lavaan::fitMeasures(invar$configural, "rmsea.scaled"),
    lavaan::fitMeasures(invar$metrica_ordinal, "rmsea.scaled") - lavaan::fitMeasures(invar$umbrales, "rmsea.scaled")),
  delta_SRMR = c(
    lavaan::fitMeasures(invar$umbrales, "srmr") - lavaan::fitMeasures(invar$configural, "srmr"),
    lavaan::fitMeasures(invar$metrica_ordinal, "srmr") - lavaan::fitMeasures(invar$umbrales, "srmr"))
)
utils::write.csv(dif_fit, "salidas/08_invarianza_cambios_ajuste.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
utils::write.csv(as.data.frame(lavaan::lavTestLRT(invar$configural,
  invar$umbrales, invar$metrica_ordinal)),
  "salidas/08_invarianza_diferencias_chi2.csv", fileEncoding = "UTF-8")
# Igualdad de rutas estructurales bajo iguales restricciones de medida.
modelo_sem_etiquetado <- sub(
  "ConocimientoMecanismos ~ ConfianzaInterpersonal \\+ ConfianzaInstitucional",
  "ConocimientoMecanismos ~ b_interpersonal*ConfianzaInterpersonal + b_institucional*ConfianzaInstitucional",
  modelo_sem)
modelo_sem_paths_free <- sub(
  "ConocimientoMecanismos ~ ConfianzaInterpersonal \\+ ConfianzaInstitucional",
  "ConocimientoMecanismos ~ c(b_ip_h, b_ip_m)*ConfianzaInterpersonal + c(b_inst_h, b_inst_m)*ConfianzaInstitucional",
  modelo_sem)
mg_paths_free <- lavaan::sem(modelo_sem_paths_free, data = datos, group = "sexo", ordered = items,
  estimator = "WLSMV", missing = "pairwise", sampling.weights = "FEX_P",
  group.equal = c("thresholds", "loadings"), parameterization = "theta")
mg_paths_equal <- lavaan::sem(modelo_sem_etiquetado, data = datos, group = "sexo",
  ordered = items, estimator = "WLSMV", missing = "pairwise",
  sampling.weights = "FEX_P", group.equal = c("thresholds", "loadings"),
  parameterization = "theta")
utils::write.csv(as.data.frame(lavaan::lavTestLRT(mg_paths_free, mg_paths_equal)),
                 "salidas/08_invarianza_estructural_sexo.csv", fileEncoding = "UTF-8")
wald_paths <- rbind(
  data.frame(hipotesis = "H1: ruta interpersonal igual por sexo",
             as.data.frame(lavaan::lavTestWald(mg_paths_free,
               constraints = "b_ip_h == b_ip_m"))),
  data.frame(hipotesis = "H2: ruta institucional igual por sexo",
             as.data.frame(lavaan::lavTestWald(mg_paths_free,
               constraints = "b_inst_h == b_inst_m")))
)
utils::write.csv(wald_paths, "salidas/08_invarianza_wald_rutas.csv",
                 row.names = FALSE, fileEncoding = "UTF-8")
pe_mg <- lavaan::parameterEstimates(mg_paths_free, standardized = TRUE)
utils::write.csv(pe_mg[pe_mg$op == "~" & pe_mg$lhs == "ConocimientoMecanismos", ],
                 "salidas/08_rutas_por_sexo.csv", row.names = FALSE,
                 fileEncoding = "UTF-8")
capture.output(sessionInfo(), file = "salidas/08_sessionInfo.txt")
cat("Fase 2/3 finalizada. Revise los avisos de diseno muestral en el informe.\n")
