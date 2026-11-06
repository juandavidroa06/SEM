# Genera el libro local de entrega. Se mantiene fuera de Git si contiene
# derivados de microdatos; nunca incorpora filas individuales.
set.seed(2026)
lib_usuario <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local", "R", "win-library",
                         paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1]))
if (nzchar(Sys.getenv("USERPROFILE")) && dir.exists(lib_usuario)) .libPaths(c(lib_usuario, .libPaths()))
leer<-function(f)if(file.exists(f))utils::read.csv(f,check.names=FALSE,fileEncoding="UTF-8")else data.frame()
unir<-function(xs,tags){xs<-lapply(seq_along(xs),function(i){x<-xs[[i]];if(!nrow(x))return(NULL);names(x)[!nzchar(names(x))]<-"variable";names(x)<-make.unique(names(x),sep="_");x$seccion<-tags[i];x});xs<-Filter(Negate(is.null),xs);if(!length(xs))return(data.frame());cols<-unique(unlist(lapply(xs,names)));do.call(rbind,lapply(xs,function(x){for(n in setdiff(cols,names(x)))x[[n]]<-NA;x[,cols,drop=FALSE]}))}
fit_files<-c("salidas/08_ajuste.csv","salidas/08_ajuste_afc.csv","salidas/08_ajuste_sem.csv","salidas/08_invarianza_sexo.csv")
ajuste<-unir(lapply(fit_files,leer),basename(fit_files))
if(nrow(ajuste)&&"modelo"%in%names(ajuste))ajuste<-ajuste[!duplicated(ajuste$modelo,fromLast=TRUE),,drop=FALSE]
hip<-leer("salidas/08_hipotesis.csv")
param<-leer("salidas/08_parametros_afc.csv"); medicion<-param[param$op=="=~",,drop=FALSE]
cr<-leer("salidas/08_confiabilidad.csv");ave<-leer("salidas/08_AVE.csv")
discriminante<-unir(list(leer("salidas/08_fornell_larcker.csv"),leer("salidas/08_HTMT.csv")),c("Fornell_Larcker","HTMT_no_ponderado"))
efectos <- data.frame()
if (nrow(hip)) {
  campos <- data.frame(
    rhs=hip$rhs, est=hip$est, se=hip$se, z=hip$z, pvalue=hip$pvalue,
    std.all=hip$std.all, ci.lower=hip$ci.lower, ci.upper=hip$ci.upper,
    EE_original=NA_real_, deff=NA_real_
  )
  directo <- data.frame(tipo="directo", nota="Ruta estructural estimada", campos)
  total <- directo
  total$tipo <- "total"
  total$nota <- "Igual al directo: el modelo no especifica mediadores"
  indirecto <- directo
  indirecto$tipo <- "indirecto"
  indirecto$nota <- "No aplica: el modelo aprobado no contiene mediador"
  indirecto[, setdiff(names(indirecto), c("tipo", "nota", "rhs"))] <- NA
  sensibilidad <- leer("salidas/08_sensibilidad_pesos_faltantes.csv")
  sens_rows <- data.frame()
  if (nrow(sensibilidad)) {
    labels <- c(casos_completos_sin_pesos="Casos completos sin pesos",
                casos_completos_FEX_P="Casos completos con FEX_P",
                pares_FEX_P="Pares con FEX_P")
    sens_rows <- data.frame(
      tipo=paste0("sensibilidad: ", unname(labels[sensibilidad$especificacion])),
      nota="Estimacion de sensibilidad; no es el efecto principal",
      rhs=sensibilidad$rhs, est=sensibilidad$est, se=sensibilidad$se,
      z=sensibilidad$z, pvalue=sensibilidad$pvalue, std.all=sensibilidad$std.all,
      ci.lower=sensibilidad$ci.lower, ci.upper=sensibilidad$ci.upper,
      EE_original=NA_real_, deff=NA_real_
    )
  }
  diseno <- leer("salidas/08_sensibilidad_deff.csv")
  deff_rows <- data.frame()
  if (nrow(diseno)) {
    deff_rows <- data.frame(
      tipo="efecto de diseno aproximado",
      nota="Kish; EE inflado por sqrt(deff), sin UPM ni estratos",
      rhs=diseno$ruta, est=diseno$B, se=diseno$EE_inflado, z=diseno$z,
      pvalue=diseno$p, std.all=NA_real_, ci.lower=diseno$IC95_inf,
      ci.upper=diseno$IC95_sup, EE_original=diseno$EE_original,
      deff=diseno$deff_kish
    )
  }
  efectos <- rbind(directo, indirecto, total, sens_rows, deff_rows)
}
inv<-list(secuencia=leer("salidas/08_invarianza_sexo.csv"),cambios=leer("salidas/08_invarianza_cambios_ajuste.csv"),diferencias=leer("salidas/08_invarianza_diferencias_chi2.csv"),Wald=leer("salidas/08_invarianza_wald_rutas.csv"))
if(requireNamespace("knitr",quietly=TRUE)){
 dir.create("articulo/tablas",recursive=TRUE,showWarnings=FALSE)
 resize_tabular<-function(x,width="\\linewidth") {z<-strsplit(x,"\n",fixed=TRUE)[[1]];i<-which(grepl("^\\\\begin\\{tabular\\}",z))[1];j<-tail(which(grepl("^\\\\end\\{tabular\\}",z)),1);if(!is.na(i)&&length(j)) {suffix<-sub("^\\\\begin\\{tabular\\}","",z[i]);z[i]<-paste0("\\resizebox{",width,"}{!}{\\begin{tabular}",suffix);z[j]<-paste0(z[j],"}")};paste(z,collapse="\n")}
 ind<-data.frame(Constructo=c("Confianza interpersonal","Confianza institucional","Familiaridad autorreportada"),Contenido=c("Confianza en personas desconocidas, vecinos, amistades y personas de otra nacionalidad","Confianza en 15 instituciones y actores públicos","Reconocimiento de seis mecanismos formales de participación"),Indicadores=c("P2025S4--P2025S7","P5263S1--P5263S15","P5376S1--P5376S6"),Tratamiento=c("Ordinal 1--5; 99 a faltante","Ordinal 1--5; 99 a faltante; S6/S12 no aplican en Bogotá","Binaria; 1=conoce/ha oído y 0=no conoce"))
 indout<-knitr::kable(ind,format="latex",booktabs=TRUE,row.names=FALSE,caption="Constructos, indicadores y codificación",label="indicadores")
 indout<-sub("\\\\begin\\{tabular\\}\\[t\\]\\{llll\\}","\\\\begin{tabularx}{\\\\textwidth}{p{2.8cm}X p{2.5cm} X}",indout,perl=TRUE);indout<-sub("\\\\end\\{tabular\\}","\\\\end{tabularx}",indout,perl=TRUE)
 writeLines(indout,"articulo/tablas/indicadores.tex")
 vars<-intersect(c("modelo","n","chisq.scaled","df","pvalue.scaled","cfi.robust","tli.robust","rmsea.robust","rmsea.ci.lower.robust","rmsea.ci.upper.robust","srmr","cfi.scaled","tli.scaled","rmsea.scaled"),names(ajuste))
 ajuste_tex<-ajuste[,vars,drop=FALSE];if("pvalue.scaled"%in%names(ajuste_tex))ajuste_tex$pvalue.scaled[as.numeric(ajuste_tex$pvalue.scaled)<.001]<-"<,001"
 if("modelo"%in%names(ajuste_tex))ajuste_tex$modelo<-unname(c(AFC_correlacionado="AFC",SEM_referencia="SEM principal",SEM_institucional_2D_exploratorio="Alternativo 2D",SEM_rival_inverso="Rival inverso",configural="Configural",umbrales="Umbrales",metrica_ordinal="Métrica")[ajuste_tex$modelo])
 names(ajuste_tex)<-c("Modelo","n","Chi2 esc.","gl","p","CFI rob.","TLI rob.","RMSEA rob.","IC inf.","IC sup.","SRMR","CFI esc.","TLI esc.","RMSEA esc.")[seq_along(ajuste_tex)]
 ajuste_tex_out<-knitr::kable(ajuste_tex,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,na="--",format.args=list(decimal.mark=",",big.mark="."),caption="Índices de ajuste de los modelos ponderados",label="ajuste")
 writeLines(c("\\begingroup\\scriptsize\\setlength{\\tabcolsep}{2pt}",resize_tabular(ajuste_tex_out),"\\endgroup"),"articulo/tablas/ajuste.tex")
 if(nrow(hip)){h<-data.frame(H=hip$hipotesis,Ruta=ifelse(hip$rhs=="ConfianzaInterpersonal","Interpersonal","Institucional"),B=hip$est,EE=hip$se,z=hip$z,beta=hip$std.all,p=hip$pvalue,IC_inf=hip$ci.lower,IC_sup=hip$ci.upper);h$p[as.numeric(h$p)<.001]<-"<,001";writeLines(knitr::kable(h,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Hipótesis y parámetros estructurales",label="hipotesis"),"articulo/tablas/hipotesis.tex")}
 sens<-leer("salidas/08_sensibilidad_pesos_faltantes.csv");if(nrow(sens)){s<-data.frame(Especificacion=unname(c(casos_completos_sin_pesos="CC sin pesos",casos_completos_FEX_P="CC con FEX_P",pares_FEX_P="Pares con FEX_P")[sens$especificacion]),Ruta=ifelse(sens$rhs=="ConfianzaInterpersonal","Interpersonal","Institucional"),B=sens$est,EE=sens$se,z=sens$z,p=sens$pvalue,beta=sens$std.all,IC_inf=sens$ci.lower,IC_sup=sens$ci.upper);s$p[as.numeric(s$p)<.001]<-"<,001";writeLines(resize_tabular(knitr::kable(s,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Sensibilidad a pesos y tratamiento de faltantes",label="sensibilidad")),"articulo/tablas/sensibilidad.tex")}
 de<-leer("salidas/08_sensibilidad_deff.csv");if(nrow(de)){d<-data.frame(Ruta=ifelse(de$ruta=="ConfianzaInterpersonal","Interpersonal","Institucional"),B=de$B,EE_original=de$EE_original,deff=de$deff_kish,EE_inflado=de$EE_inflado,z=de$z,p=de$p,IC_inf=de$IC95_inf,IC_sup=de$IC95_sup);d$p[d$p<.001]<-"<,001";writeLines(resize_tabular(knitr::kable(d,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Sensibilidad aproximada al efecto de diseño por desigualdad de pesos",label="deff")),"articulo/tablas/sensibilidad_deff.tex")}
 pa<-leer("salidas/08_parametros_afc.csv");ca<-pa[pa$op=="=~",c("lhs","rhs","std.all","se","z","pvalue"),drop=FALSE];if(nrow(ca)){ca$pvalue[as.numeric(ca$pvalue)<.001]<-"<,001";writeLines(knitr::kable(ca,format="latex",booktabs=TRUE,longtable=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Cargas factoriales estandarizadas del AFC ponderado"),"articulo/tablas/cargas_estandarizadas.tex")}
 if(file.exists("salidas/08_fornell_larcker.csv")&&file.exists("salidas/08_HTMT.csv")){
   fl<-utils::read.csv("salidas/08_fornell_larcker.csv",row.names=1,check.names=FALSE);ht<-utils::read.csv("salidas/08_HTMT.csv",row.names=1,check.names=FALSE)
   cr0<-utils::read.csv("salidas/08_confiabilidad.csv",row.names=1,check.names=FALSE);av0<-utils::read.csv("salidas/08_AVE.csv",row.names=1,check.names=FALSE)
   con<-rownames(fl);av<-as.numeric(av0[con,1]);val<-data.frame(constructo=con,CR=as.numeric(cr0[1,con]),AVE=av,raiz_AVE=sqrt(av),correlacion_latente_maxima=vapply(con,function(x)max(abs(fl[x,setdiff(colnames(fl),x)])),numeric(1)),HTMT_maximo_no_ponderado=vapply(con,function(x)max(abs(ht[x,setdiff(colnames(ht),x)])),numeric(1)))
   names(val)<-c("Constructo","CR","AVE","Raíz AVE","Cor. lat. máx.","HTMT máx. no pond.")
   writeLines(resize_tabular(knitr::kable(val,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Confiabilidad, AVE y validez discriminante",label="validez")),"articulo/tablas/validez.tex")
   dis<-data.frame(Constructo=c("Interpersonal","Institucional","Familiaridad"),fl,ht[,rownames(fl)],check.names=FALSE)
   names(dis)<-c("Constructo","FL-IP","FL-Inst.","FL-Fam.","HTMT-IP","HTMT-Inst.","HTMT-Fam.")
   writeLines(knitr::kable(dis,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Matrices Fornell--Larcker y HTMT",label="discriminante"),"articulo/tablas/discriminante.tex")
 }
 if(file.exists("salidas/05_descriptivos_indicadores.csv")){de<-leer("salidas/05_descriptivos_indicadores.csv");de<-de[,intersect(c("variable","n_valido","porcentaje_perdido","media","desviacion","mediana"),names(de)),drop=FALSE];names(de)<-c("Indicador","n válido","Faltantes %","Media","DE","Mediana");writeLines(knitr::kable(de,format="latex",booktabs=TRUE,longtable=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Estadísticos descriptivos por indicador"),"articulo/tablas/estadisticos_descriptivos.tex")}
 if(file.exists("salidas/06_matriz_policorica.csv")){ma<-utils::read.csv("salidas/06_matriz_policorica.csv",row.names=1,check.names=FALSE);abbr<-function(x)ifelse(grepl("^P2025S",x),paste0("I",sub("P2025S","",x)),ifelse(grepl("^P5263S",x),paste0("T",sub("P5263S","",x)),paste0("K",sub("P5376S","",x))));names(ma)<-abbr(names(ma));ma<-data.frame(Indicador=abbr(rownames(ma)),ma,check.names=FALSE);mat<-knitr::kable(ma,format="latex",booktabs=TRUE,longtable=TRUE,digits=2,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Matriz policórica no ponderada");mat<-sub("\\\\begin\\{longtable\\}","\\\\begingroup\\\\tiny\\\\setlength{\\\\tabcolsep}{1.2pt}\\\\begin{longtable}",mat);mat<-sub("\\\\end\\{longtable\\}","\\\\end{longtable}\\\\endgroup",mat);writeLines(mat,"articulo/tablas/matriz_policorica.tex")}
 if(file.exists("salidas/08_invarianza_diferencias_chi2.csv")&&file.exists("salidas/08_invarianza_cambios_ajuste.csv")){
   di<-utils::read.csv("salidas/08_invarianza_diferencias_chi2.csv",row.names=1,check.names=FALSE);ca<-leer("salidas/08_invarianza_cambios_ajuste.csv");iv0<-leer("salidas/08_invarianza_sexo.csv")
   iv<-data.frame(Modelo=iv0$modelo,Chi2_escalado=iv0$chisq.scaled,gl=iv0$df,CFI_escalado=iv0$cfi.scaled,TLI_escalado=iv0$tli.scaled,RMSEA_escalado=iv0$rmsea.scaled,SRMR=iv0$srmr,Delta_chi2=c(NA,di[2:3,"Chisq diff"]),Delta_gl=c(NA,di[2:3,"Df diff"]),p=c(NA,di[2:3,"Pr(>Chisq)"]),Delta_CFI=c(NA,ca$delta_CFI),Delta_RMSEA=c(NA,ca$delta_RMSEA),Delta_SRMR=c(NA,ca$delta_SRMR))
   iv$Chi2_escalado<-formatC(iv$Chi2_escalado,format="f",digits=2,big.mark=".",decimal.mark=",");iv$Delta_chi2<-ifelse(is.na(iv$Delta_chi2),"--",formatC(iv$Delta_chi2,format="f",digits=2,decimal.mark=","));iv$Delta_gl[is.na(iv$Delta_gl)]<-"--";iv$p<-ifelse(is.na(iv$p),"--",ifelse(iv$p<.001,"<,001",formatC(iv$p,format="f",digits=3,decimal.mark=",")))
   for(nm in c("Delta_CFI","Delta_RMSEA","Delta_SRMR"))iv[[nm]]<-ifelse(is.na(iv[[nm]]),"--",formatC(iv[[nm]],format="f",digits=4,decimal.mark=","))
   names(iv)<-c("Modelo","Chi2 escalado","gl","CFI esc.","TLI esc.","RMSEA esc.","SRMR","Delta Chi2","Delta gl","p","Delta CFI","Delta RMSEA","Delta SRMR")
   ivout<-knitr::kable(iv,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,caption="Secuencia de invariancia ordinal y cambios de ajuste por sexo",label="invarianza")
   writeLines(c("\\begingroup\\scriptsize\\setlength{\\tabcolsep}{2pt}",resize_tabular(ivout),"\\endgroup"),"articulo/tablas/invarianza.tex")
 }
 wa<-leer("salidas/08_invarianza_wald_rutas.csv");if(nrow(wa)){w<-data.frame(Hipotesis=wa$hipotesis,Wald=wa$stat,gl=wa$df,p=wa$p.value,p_Bonferroni=wa$p_bonferroni,p_Holm=wa$p_holm);writeLines(knitr::kable(w,format="latex",booktabs=TRUE,digits=3,row.names=FALSE,format.args=list(decimal.mark=",",big.mark="."),caption="Pruebas de Wald por ruta con ajuste por comparaciones múltiples",label="waldsexo"),"articulo/tablas/wald_sexo.tex")}
}
if (!requireNamespace("writexl",quietly=TRUE))
  stop("Falta writexl. Instálelo una vez con install.packages('writexl') y vuelva a ejecutar.")
salida<-"outputs/Taller2_SEM_resultados.xlsx";dir.create("outputs",showWarnings=FALSE,recursive=TRUE)
writexl::write_xlsx(list(ajuste=ajuste,medicion=unir(list(medicion,cr,ave),c("cargas","CR","AVE")),
  discriminante=discriminante,hipotesis=hip,efectos=efectos,
  invarianza=unir(inv,c("secuencia","cambios","diferencias","Wald"))),path=salida)
cat("Libro generado en ",salida,"\n",sep="")
sessionInfo()
