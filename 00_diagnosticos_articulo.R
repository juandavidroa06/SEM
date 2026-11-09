# Diagnósticos de Fase 1 y matriz descriptiva que sustenta el apéndice.
# Genera sus insumos desde los ZIP; no reutiliza resultados preexistentes.
set.seed(2026)
source("05_calidad_descriptivos.R", local = new.env(parent = globalenv()))
source("00_preparacion.R")
if (!requireNamespace("psych", quietly = TRUE)) stop("Se requiere psych.")
X <- as.data.frame(lapply(datos[items], function(x) as.numeric(as.character(x))))
Xcc <- X[complete.cases(X), , drop = FALSE]
rho <- psych::polychoric(Xcc, progress = FALSE, smooth = TRUE, global = TRUE)$rho
utils::write.csv(rho, "salidas/06_matriz_policorica.csv", fileEncoding = "UTF-8")
capture.output(sessionInfo(), file = "salidas/00_sessionInfo.txt")
sessionInfo()
