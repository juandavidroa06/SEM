# Taller 2, etapa 1: AFC ponderado, validez y diagnóstico de medición
set.seed(2026)
source("00_preparacion.R")
if (!requireNamespace("lavaan", quietly = TRUE) || !requireNamespace("semTools", quietly = TRUE))
  stop("Se requieren lavaan y semTools. Instálelos antes de ejecutar; este script no instala paquetes.")
afc <- do.call(lavaan::cfa, c(list(model = modelo_medicion), opts))
stopifnot(lavaan::lavInspect(afc, "converged"), lavaan::lavInspect(afc, "post.check"))
residuos_cor <- lavaan::lavResiduals(afc, type = "cor")$cov
utils::write.csv(as.data.frame(as.table(as.matrix(residuos_cor))),
  "salidas/08_residuos_correlacion.csv", row.names = FALSE)
utils::write.csv(lavaan::lavInspect(afc, "sampstat")$cov,
  "salidas/08_matriz_asociacion_ponderada.csv")
fit_names <- c("chisq", "chisq.scaled", "df", "pvalue", "pvalue.scaled", "cfi.robust", "tli.robust",
  "rmsea.robust", "rmsea.ci.lower.robust", "rmsea.ci.upper.robust",
  "cfi.scaled", "tli.scaled", "rmsea.scaled", "rmsea.ci.lower", "rmsea.ci.upper", "cfi", "tli", "rmsea", "srmr")
m <- lavaan::fitMeasures(afc)
ajuste <- data.frame(modelo = "AFC_correlacionado", n = nrow(datos),
  convergio = lavaan::inspect(afc, "converged"), as.list(m[intersect(fit_names, names(m))]),
  check.names = FALSE)
utils::write.csv(ajuste, "salidas/08_ajuste_afc.csv", row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(lavaan::parameterEstimates(afc, standardized = TRUE),
  "salidas/08_parametros_afc.csv", row.names = FALSE, fileEncoding = "UTF-8")
sol_afc <- lavaan::standardizedSolution(afc, ci = TRUE)
utils::write.csv(sol_afc, "salidas/08_cargas_afc_estandarizadas.csv", row.names = FALSE, fileEncoding = "UTF-8")
cr_obj <- semTools::compRelSEM(afc)
utils::write.csv(cr_obj, "salidas/08_confiabilidad.csv", fileEncoding = "UTF-8")
ave <- semTools::AVE(afc)
utils::write.csv(ave, "salidas/08_AVE.csv", fileEncoding = "UTF-8")
cor_lv <- lavaan::lavInspect(afc, "cor.lv")
fl <- cor_lv
diag(fl) <- sqrt(as.numeric(ave[rownames(fl)]))
utils::write.csv(as.data.frame(fl), "salidas/08_fornell_larcker.csv", fileEncoding = "UTF-8")
htmt <- as.data.frame(semTools::htmt(modelo_medicion, data = datos, ordered = items))
utils::write.csv(htmt, "salidas/08_HTMT.csv", fileEncoding = "UTF-8")
utils::write.csv(lavaan::modificationIndices(afc, sort. = TRUE, minimum.value = 10),
  "salidas/08_indices_modificacion.csv", row.names = FALSE, fileEncoding = "UTF-8")
if (requireNamespace("knitr", quietly = TRUE)) {
  dir.create("articulo/tablas", recursive = TRUE, showWarnings = FALSE)
  cargas <- sol_afc[sol_afc$op == "=~", c("lhs", "rhs", "est.std", "se", "z", "pvalue")]
  cargas$pvalue[as.numeric(cargas$pvalue) < .001] <- "<,001"
  writeLines(knitr::kable(cargas, format = "latex", booktabs = TRUE, longtable = TRUE,
    digits = 3, row.names = FALSE, format.args = list(decimal.mark = ",", big.mark = "."), caption = "Cargas factoriales estandarizadas del AFC ponderado"),
    "articulo/tablas/cargas_estandarizadas.tex")
  cr_mat <- as.matrix(cr_obj)
  ht_mat <- as.matrix(htmt)
  constructos <- rownames(cor_lv)
  if (all(constructos %in% colnames(cr_mat))) {
    cr_vals <- cr_mat[1, constructos]
  } else if (all(constructos %in% rownames(cr_mat))) {
    cr_vals <- cr_mat[constructos, 1]
  } else {
    stop("Los nombres de los constructos de CR no coinciden con cor.lv.")
  }
  fl_tab <- data.frame(constructo = constructos, CR = as.numeric(cr_vals),
    AVE = as.numeric(ave[rownames(cor_lv)]), raiz_AVE = sqrt(as.numeric(ave[rownames(cor_lv)])),
    max_correlacion_latente = vapply(rownames(cor_lv), function(x) max(abs(cor_lv[x, setdiff(colnames(cor_lv), x)])), numeric(1)),
    max_HTMT_no_ponderado = vapply(rownames(cor_lv), function(x) max(abs(ht_mat[x, setdiff(colnames(ht_mat), x)])), numeric(1)))
  writeLines(knitr::kable(fl_tab, format = "latex", booktabs = TRUE, digits = 3, row.names = FALSE,
    format.args = list(decimal.mark = ",", big.mark = "."), caption = "Confiabilidad, AVE y validez discriminante", label = "validez"),
    "articulo/tablas/validez.tex")
  if (file.exists("salidas/05_descriptivos_indicadores.csv")) {
    desc <- utils::read.csv("salidas/05_descriptivos_indicadores.csv", check.names = FALSE)
    writeLines(knitr::kable(desc, format = "latex", booktabs = TRUE, longtable = TRUE, row.names = FALSE,
      digits = 3, format.args = list(decimal.mark = ",", big.mark = "."), caption = "Estadísticos descriptivos por indicador"),
      "articulo/tablas/estadisticos_descriptivos.tex")
  }
  if (file.exists("salidas/06_matriz_policorica.csv")) {
    mat <- utils::read.csv("salidas/06_matriz_policorica.csv", check.names = FALSE, row.names = 1)
    writeLines(knitr::kable(mat, format = "latex", booktabs = TRUE, longtable = TRUE, row.names = FALSE,
      digits = 2, format.args = list(decimal.mark = ",", big.mark = "."), caption = "Matriz policórica no ponderada"),
      "articulo/tablas/matriz_policorica.tex")
  }
}
capture.output(sessionInfo(), file = "salidas/01_sessionInfo.txt")
sessionInfo()
