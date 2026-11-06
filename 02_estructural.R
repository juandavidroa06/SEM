# Taller 2, etapa 2: SEM principal y sensibilidades
set.seed(2026)
source("00_preparacion.R")
if (!requireNamespace("lavaan", quietly = TRUE))
  stop("Se requiere lavaan. Instálelo antes de ejecutar; este script no instala paquetes.")
sem <- do.call(lavaan::sem, c(list(model = modelo_sem), opts))
rival <- do.call(lavaan::sem, c(list(model = modelo_rival), opts))
fit_names <- c("chisq", "chisq.scaled", "df", "pvalue", "pvalue.scaled", "cfi.robust", "tli.robust",
  "rmsea.robust", "rmsea.ci.lower.robust", "rmsea.ci.upper.robust", "cfi.scaled",
  "tli.scaled", "rmsea.scaled", "rmsea.ci.lower", "rmsea.ci.upper", "cfi", "tli", "rmsea", "srmr")
fitrow <- function(f, nm) { m <- lavaan::fitMeasures(f); data.frame(modelo=nm,n=nrow(datos),
  convergio=lavaan::inspect(f,"converged"),as.list(m[intersect(fit_names,names(m))]),check.names=FALSE) }
alt <- do.call(lavaan::sem, c(list(model = modelo_alt), opts))
utils::write.csv(do.call(rbind,list(fitrow(sem,"SEM_referencia"),fitrow(alt,"SEM_institucional_2D_exploratorio"),fitrow(rival,"SEM_rival_inverso"))),
  "salidas/08_ajuste_sem.csv",row.names=FALSE,fileEncoding="UTF-8")
pe <- lavaan::parameterEstimates(sem, standardized=TRUE, ci=TRUE)
rutas <- pe[pe$op=="~" & pe$lhs=="ConocimientoMecanismos",]
rutas$hipotesis <- ifelse(rutas$rhs=="ConfianzaInterpersonal","H1","H2")
rutas$p_unilateral_signo_positivo <- ifelse(rutas$est>=0,rutas$pvalue/2,1-rutas$pvalue/2)
rutas$decision_unilateral <- ifelse(rutas$p_unilateral_signo_positivo<.05,"apoyo estadistico al signo positivo","sin apoyo estadistico al signo positivo")
utils::write.csv(rutas,"salidas/08_hipotesis.csv",row.names=FALSE,fileEncoding="UTF-8")
utils::write.csv(lavaan::standardizedSolution(sem,ci=TRUE),"salidas/08_solucion_estandarizada.csv",row.names=FALSE,fileEncoding="UTF-8")
utils::write.csv(data.frame(constructo="ConocimientoMecanismos",R2=unname(lavaan::lavInspect(sem,"r2")["ConocimientoMecanismos"])),"salidas/08_R2.csv",row.names=FALSE)

# Sensibilidad de casos completos frente a estimación con información por pares.
cc <- datos[complete.cases(datos[items]), , drop=FALSE]
fit_cc <- function(d, weighted) lavaan::sem(modelo_sem,data=d,ordered=items,estimator="WLSMV",missing="pairwise",
  sampling.weights=if(weighted) "FEX_P" else NULL)
mods <- list(casos_completos_sin_pesos=fit_cc(cc,FALSE),casos_completos_FEX_P=fit_cc(cc,TRUE),pares_FEX_P=sem)
sens <- do.call(rbind,lapply(names(mods),function(nm){q<-lavaan::parameterEstimates(mods[[nm]],standardized=TRUE,ci=TRUE);q<-q[q$op=="~"&q$lhs=="ConocimientoMecanismos",];q$especificacion<-nm;q[,c("especificacion","rhs","est","se","z","pvalue","std.all","ci.lower","ci.upper")] }))
utils::write.csv(sens,"salidas/08_sensibilidad_pesos_faltantes.csv",row.names=FALSE,fileEncoding="UTF-8")
dir.create("articulo/tablas",recursive=TRUE,showWarnings=FALSE)
if(requireNamespace("knitr",quietly=TRUE)) writeLines(knitr::kable(sens,format="latex",booktabs=TRUE,digits=3),"articulo/tablas/sensibilidad.tex")

# Aproximación Kish; no sustituye la corrección por UPM y estrato.
w<-datos$FEX_P; deff<-1+(stats::sd(w)/mean(w))^2
peff<-pe[pe$op=="~"&pe$lhs=="ConocimientoMecanismos",]
sens_deff<-data.frame(ruta=peff$rhs,B=peff$est,EE_original=peff$se,deff_kish=deff,EE_inflado=peff$se*sqrt(deff))
sens_deff$z<-sens_deff$B/sens_deff$EE_inflado;sens_deff$p<-2*stats::pnorm(-abs(sens_deff$z))
sens_deff$IC95_inf<-sens_deff$B-1.96*sens_deff$EE_inflado;sens_deff$IC95_sup<-sens_deff$B+1.96*sens_deff$EE_inflado
utils::write.csv(sens_deff,"salidas/08_sensibilidad_deff.csv",row.names=FALSE,fileEncoding="UTF-8")
utils::write.csv(lavaan::parameterEstimates(rival,standardized=TRUE),"salidas/08_parametros_rival.csv",row.names=FALSE,fileEncoding="UTF-8")
capture.output(sessionInfo(),file="salidas/02_sessionInfo.txt")
sessionInfo()
