# Taller 2, etapa 3: invariancia ordinal y diferencias estructurales por sexo
set.seed(2026)
source("00_preparacion.R")
if (!requireNamespace("lavaan",quietly=TRUE)||!requireNamespace("semTools",quietly=TRUE))
  stop("Se requieren lavaan y semTools. Instálelos antes de ejecutar; este script no instala paquetes.")
if(any(table(datos$sexo)<200))stop("Grupo de sexo con menos de 200 casos.")
fit_names<-c("chisq","chisq.scaled","df","pvalue","pvalue.scaled","cfi.robust","tli.robust","rmsea.robust","rmsea.ci.lower.robust","rmsea.ci.upper.robust","cfi.scaled","tli.scaled","rmsea.scaled","rmsea.ci.lower","rmsea.ci.upper","cfi","tli","rmsea","srmr")
invar<-list()
for(nivel in c("configural","umbrales","metrica_ordinal")){
 iguales<-switch(nivel,configural=character(0),umbrales="thresholds",metrica_ordinal=c("thresholds","loadings"))
 syntax<-semTools::measEq.syntax(configural.model=modelo_medicion,data=datos,group="sexo",ordered=items,
   parameterization="theta",ID.fac="std.lv",ID.cat="Wu.Estabrook.2016",group.equal=iguales)
 invar[[nivel]]<-lavaan::cfa(as.character(syntax),data=datos,group="sexo",ordered=items,estimator="WLSMV",
   missing="pairwise",sampling.weights="FEX_P",parameterization="theta")
}
fitrow<-function(f,nm){m<-lavaan::fitMeasures(f);data.frame(modelo=nm,n=sum(lavaan::lavInspect(f,"nobs")),as.list(m[intersect(fit_names,names(m))]),check.names=FALSE)}
utils::write.csv(do.call(rbind,lapply(names(invar),function(nm)fitrow(invar[[nm]],nm))),"salidas/08_invarianza_sexo.csv",row.names=FALSE,fileEncoding="UTF-8")
utils::write.csv(do.call(rbind,lapply(2:3,function(i){a<-lavaan::fitMeasures(invar[[i-1]]);b<-lavaan::fitMeasures(invar[[i]]);data.frame(paso=names(invar)[i-1],delta_CFI=b["cfi.scaled"]-a["cfi.scaled"],delta_RMSEA=b["rmsea.scaled"]-a["rmsea.scaled"],delta_SRMR=b["srmr"]-a["srmr"])})),"salidas/08_invarianza_cambios_ajuste.csv",row.names=FALSE,fileEncoding="UTF-8")
utils::write.csv(as.data.frame(lavaan::lavTestLRT(invar$configural,invar$umbrales,invar$metrica_ordinal)),"salidas/08_invarianza_diferencias_chi2.csv",fileEncoding="UTF-8")
sem_labels<-sub("ConocimientoMecanismos ~ ConfianzaInterpersonal \\+ ConfianzaInstitucional","ConocimientoMecanismos ~ b_interpersonal*ConfianzaInterpersonal + b_institucional*ConfianzaInstitucional",modelo_sem)
sem_free<-sub("ConocimientoMecanismos ~ ConfianzaInterpersonal \\+ ConfianzaInstitucional","ConocimientoMecanismos ~ c(b_ip_h,b_ip_m)*ConfianzaInterpersonal + c(b_inst_h,b_inst_m)*ConfianzaInstitucional",modelo_sem)
mg_free<-lavaan::sem(sem_free,data=datos,group="sexo",ordered=items,estimator="WLSMV",missing="pairwise",sampling.weights="FEX_P",group.equal=c("thresholds","loadings"),parameterization="theta")
mg_equal<-lavaan::sem(sem_labels,data=datos,group="sexo",ordered=items,estimator="WLSMV",missing="pairwise",sampling.weights="FEX_P",group.equal=c("thresholds","loadings"),parameterization="theta")
utils::write.csv(as.data.frame(lavaan::lavTestLRT(mg_free,mg_equal)),"salidas/08_invarianza_estructural_sexo.csv",fileEncoding="UTF-8")
wald<-rbind(data.frame(hipotesis="H1",as.data.frame(lavaan::lavTestWald(mg_free,constraints="b_ip_h == b_ip_m"))),data.frame(hipotesis="H2",as.data.frame(lavaan::lavTestWald(mg_free,constraints="b_inst_h == b_inst_m"))))
wald$p_bonferroni<-pmin(1,wald$p.value*2);wald$p_holm<-stats::p.adjust(wald$p.value,method="holm")
utils::write.csv(wald,"salidas/08_invarianza_wald_rutas.csv",row.names=FALSE,fileEncoding="UTF-8")
mgpe<-lavaan::parameterEstimates(mg_free,standardized=TRUE);utils::write.csv(mgpe[mgpe$op=="~",],"salidas/08_rutas_por_sexo.csv",row.names=FALSE,fileEncoding="UTF-8")
capture.output(sessionInfo(),file="salidas/03_sessionInfo.txt")
sessionInfo()
