# Diagrama vectorial con valores leídos de las salidas de esta ejecución.
# R base: no requiere Python, fuentes de Windows ni valores escritos a mano.
hip <- utils::read.csv("salidas/08_hipotesis.csv")
pa <- utils::read.csv("salidas/08_cargas_afc_estandarizadas.csv")
r2 <- utils::read.csv("salidas/08_R2.csv")$R2[1]
fl <- utils::read.csv("salidas/08_fornell_larcker.csv", row.names = 1, check.names = FALSE)
fmt <- function(x) formatC(x, digits = 3, format = "f", decimal.mark = ",")
carga <- function(item) fmt(pa$est.std[pa$op == "=~" & pa$rhs == item])
ruta <- function(rhs, h) {
  q <- hip[hip$rhs == rhs, ]
  paste0(h, ": ", fmt(q$std.all), if (q$pvalue < .001) "***" else "")
}
grDevices::pdf("articulo/figuras/modelo_sem.pdf", width = 7.5, height = 4.6,
  family = "Helvetica", encoding = "WinAnsi.enc", title = "Modelo SEM ponderado ECP 2023")
par(mar = c(0,0,0,0), xaxs = "i", yaxs = "i")
plot.new(); plot.window(xlim = c(0,540), ylim = c(0,330))
elipse <- function(x,y,rx,ry,etiquetas) {
  a <- seq(0, 2*pi, length.out = 181)
  polygon(x+rx*cos(a), y+ry*sin(a), col = "#F6F8FC", border = "#334155", lwd = 1.5)
  text(x,y, etiquetas, cex = .88, col = "#172033")
}
elipse(112,250,102,44,paste0("Confianza interpersonal\n4 indicadores ordinales\nCarga marcador: ",carga("P2025S4")))
elipse(112,80,102,44,paste0("Confianza institucional\n15 indicadores ordinales\nCarga marcador: ",carga("P5263S1")))
elipse(428,165,103,60,paste0("Familiaridad autorreportada\n6 indicadores binarios\nCarga marcador: ",carga("P5376S1"),"\nR² = ",fmt(r2)))
arrows(214,250,350,207,length=.09,lwd=1.5,col="#334155")
arrows(214,80,350,123,length=.09,lwd=1.5,col="#334155")
text(279,247,ruta("ConfianzaInterpersonal","H1"),cex=.88,font=2)
text(279,82,ruta("ConfianzaInstitucional","H2"),cex=.88,font=2)
arrows(112,206,112,124,code=3,length=.07,col="#475569")
text(119,165,paste0("r = ",fmt(fl["ConfianzaInterpersonal","ConfianzaInstitucional"])),pos=4,cex=.82)
text(270,20,"Coeficientes estandarizados. *** p < 0,001; varianza sin ajuste completo del diseño.",cex=.73)
invisible(dev.off())
