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

