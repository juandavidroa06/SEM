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
