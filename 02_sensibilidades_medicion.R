# Se ejecuta desde 02_estructural.R, con datos y modelo principal disponibles.
# Sensibilidad territorial: elimina S6/S12 para todas las personas y conserva
# los mismos registros. Cambia la medición, no solo el tratamiento de NA.
items_23 <- setdiff(items, c("P5263S6", "P5263S12"))
cat("Sensibilidad territorial: estimando el modelo de 23 indicadores...\n")
modelo_23 <- modelo_sem
for (v in c("P5263S6", "P5263S12"))
  modelo_23 <- gsub(paste0(" + ", v), "", modelo_23, fixed = TRUE)
territorial <- lavaan::sem(modelo_23, data = datos, ordered = items_23,
  estimator = "WLSMV", missing = "pairwise", sampling.weights = "FEX_P")
stopifnot(lavaan::lavInspect(territorial, "converged"), lavaan::lavInspect(territorial, "post.check"))
terr_pe <- lavaan::parameterEstimates(territorial, standardized = TRUE, ci = TRUE)
terr_rutas <- terr_pe[terr_pe$op == "~", ]
terr_rutas$n <- nrow(datos)
terr_rutas$R2 <- unname(lavaan::lavInspect(territorial, "r2")["ConocimientoMecanismos"])
utils::write.csv(terr_rutas, "salidas/08_sensibilidad_territorial.csv", row.names = FALSE)
utils::write.csv(fitrow(territorial, "SEM_sin_items_territoriales"),
  "salidas/08_ajuste_territorial.csv", row.names = FALSE)

# Revisión exploratoria de dependencia local, con división interna reproducible.
# La pareja vecinos-amistades (S5/S6) procede del diagnóstico previo de la muestra
# completa. La partición posterior NO constituye una confirmación independiente.
set.seed(2026)
cal <- sample.int(nrow(datos), floor(nrow(datos)/2))
particiones <- list(calibracion = cal, validacion_interna = setdiff(seq_len(nrow(datos)), cal))
revision <- paste(modelo_sem, "P2025S5 ~~ P2025S6", sep = "\n")
ajustes_revision <- list(); rutas_revision <- list(); indice <- 0L
for (particion in names(particiones)) {
  d <- datos[particiones[[particion]], , drop = FALSE]
  for (especificacion in c("referencia", "residual_vecinos_amistades")) {
    cat("Revisión de medición:", particion, especificacion, "\n")
    indice <- indice + 1L
    f <- lavaan::sem(if (especificacion == "referencia") modelo_sem else revision,
      data = d, ordered = items, estimator = "WLSMV", missing = "pairwise",
      sampling.weights = "FEX_P")
    admisible <- lavaan::lavInspect(f, "converged") && lavaan::lavInspect(f, "post.check")
    fm <- lavaan::fitMeasures(f, c("cfi.robust", "tli.robust", "rmsea.robust", "srmr"))
    ajustes_revision[[indice]] <- data.frame(particion, especificacion, n = nrow(d),
      admisible, as.list(fm), check.names = FALSE)
    q <- lavaan::parameterEstimates(f, standardized = TRUE, ci = TRUE)
    q <- q[q$op == "~" & q$lhs == "ConocimientoMecanismos", ]
    q$particion <- particion; q$especificacion <- especificacion
    rutas_revision[[indice]] <- q
  }
}
utils::write.csv(do.call(rbind, ajustes_revision), "salidas/08_revision_medicion.csv", row.names = FALSE)
utils::write.csv(do.call(rbind, rutas_revision), "salidas/08_revision_medicion_rutas.csv", row.names = FALSE)
