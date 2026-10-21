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

