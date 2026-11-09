# Confianza y familiaridad con mecanismos de participación: ECP 2023

Proyecto académico de Modelación de Ecuaciones Estructurales, Universidad Santo Tomás,
2026-II. Autores: Juan David Roa Castañeda, Gabriel Felipe Aldana Vargas y Laura Camila
Rodríguez Granados.

El estudio relaciona confianza interpersonal, confianza institucional y familiaridad
autorreportada con seis mecanismos de participación. Emplea 25 indicadores ordinales
y binarios de la Encuesta de Cultura Política (ECP) 2023 del DANE y una base integrada
de 46.392 personas. El análisis es asociativo y exploratorio.

## Productos vigentes

- `articulo/articulo.pdf`: manuscrito compilado, con resumen en español e inglés.
- `articulo/articulo.tex`, `articulo/referencias.bib`, `articulo/tablas/` y
  `articulo/figuras/`: fuentes completas del artículo.
- `outputs/Taller2_SEM_resultados.xlsx`: resultados agregados, con las seis hojas
  solicitadas por el curso y hojas adicionales de sensibilidad y tamaños de efecto.
- `entregables/Taller2_SEM_Roa_Aldana_Rodriguez.zip`: paquete público reproducible
  con código, artículo y salidas agregadas; incluye manifiesto SHA-256.
- `REVISION_PUBLICACION.md`: alcance de la revisión y comprobaciones realizadas.

## Fuente y datos locales

Fuente: DANE, [catálogo ANDA de la ECP 2023](https://microdatos.dane.gov.co/index.php/catalog/822).
Consulta el cuestionario, la metodología y los términos de uso del catálogo antes de
reutilizar los datos. La descarga registrada inicialmente por el equipo fue el
19 de octubre de 2026; el análisis utiliza también los módulos adicionales y la tabla
de viviendas disponibles en la misma operación.

Los microdatos no se redistribuyen. Descarga los archivos originales del catálogo y
colócalos, sin descomprimir, en `datos_crudos/` con estos nombres locales:

1. `Democracia.zip`
2. `Participacion.zip`
3. `Capital_social.zip`
4. `Caracteristicas_generales.zip`
5. `Caracteriasticas generales 2.zip`
6. `Tabla de viviendas.zip`

El quinto nombre conserva la grafía utilizada en el proyecto. Cada ZIP debe contener
un único CSV. Los cinco módulos de personas se integran por `DIRECTORIO`,
`NRO_ENCUESTA`, `HOGAR_NUMERO` y `PERSONA_NUMERO`, verificando claves completas y únicas.
La tabla de viviendas tiene `DIRECTORIO` único y aporta `FEX_P`, `REGION` y `P3` sin
multiplicar los registros de personas. Las 46.392 personas integradas tienen peso
positivo y completo. No se calcula un factor de expansión nuevo.

## Reproducción del análisis

Abre `Taller1_SEM_ECP2023.Rproj` o trabaja desde la raíz del repositorio. Requiere R
con `lavaan`, `semTools`, `psych`, `knitr` y `writexl`. Los scripts comprueban los
paquetes; no los instalan automáticamente. En una sesión de R puedes instalarlos
una vez mediante:

```r
install.packages(c("lavaan", "semTools", "psych", "knitr", "writexl"))
```

Ejecuta:

```r
source("00_ejecutar_taller2.R", encoding = "UTF-8")
```

O desde una consola:

```text
Rscript 00_ejecutar_taller2.R
```

El ejecutor regenera los insumos desde los ZIP, sin requerir CSV o tablas de una
sesión anterior. Ejecuta, en este orden:

1. `00_diagnosticos_articulo.R`: calidad y descriptivos de Fase 1 mediante
   `05_calidad_descriptivos.R`, matriz policórica descriptiva y preparación.
2. `01_afc.R`: AFC ponderado, ajuste, cargas con incertidumbre estandarizada,
   confiabilidad, AVE, Fornell–Larcker, HTMT no ponderado y residuos.
3. `02_estructural.R`: SEM principal y rival, tamaños de efecto, sensibilidades a
   pesos/faltantes y escenario hipotético de errores. Incluye
   `02_sensibilidades_medicion.R`: modelo sin los dos ítems no aplicables en Bogotá
   y revisión exploratoria de dependencia local en dos particiones internas.
4. `03_multigrupo.R`: secuencia ordinal por sexo, comparación conjunta de rutas y
   Wald por ruta con ajustes Holm y Bonferroni.
5. `04_exportar_resultados.R`: Excel y tablas LaTeX; llama a
   `04_diagrama_articulo.R` para regenerar la figura vectorial desde las salidas y
   a `04_fuentes_tablas.R` para las notas de fuente según la plantilla.

Para regenerar únicamente las tablas, el libro y la figura usando salidas ya
calculadas y verificadas, utiliza `Rscript 00_ejecutar_taller2.R --solo-exportar`.

Se fijan semillas reproducibles y se guardan las versiones de R y paquetes en
`salidas/*sessionInfo*.txt`. La estimación de modelos puede tardar varios minutos.
Los CSV por persona que genera el diagnóstico de Fase 1 son exclusivamente locales,
están excluidos de Git y no se añaden al paquete público.

## Formato de entrega USTA

El manuscrito usa la plantilla suministrada por el docente: 11 puntos, papel carta,
márgenes de 2,5 cm, interlineado de uno y medio, autores y afiliación con `authblk`,
resúmenes sin fórmulas, enlaces azules y referencias autor–año. La copia original
se conserva en `documentacion/Plantilla_Articulo_USTA.tex`; sus ejemplos y textos
de guía no forman parte del artículo. Las fuentes bajo tablas y figura siguen
el formato de la plantilla.

## Compilación y paquete

Requiere una distribución LaTeX con `pdflatex` y `bibtex`, por ejemplo TinyTeX.
Además de los paquetes básicos de la plantilla, una instalación mínima puede
necesitar `microtype`, `enumitem`, `preprint` (incluye `authblk`), `setspace`, `pgf`
y `xurl`. Se instalan normalmente con:

```text
tlmgr install microtype enumitem preprint setspace pgf xurl
```

En este equipo se descargaron a `tmp/plantilla/texmf/` sin
modificar la instalación del sistema; `reproducir.ps1` utiliza esa copia local si
existe. Las distribuciones completas de TeX Live y Overleaf suelen incluirlos.

Desde `articulo/`, con esos paquetes disponibles, ejecuta:

```text
pdflatex -interaction=nonstopmode -halt-on-error articulo.tex
bibtex articulo
pdflatex -interaction=nonstopmode -halt-on-error articulo.tex
pdflatex -interaction=nonstopmode -halt-on-error articulo.tex
```

En Windows, `./reproducir.ps1` ejecuta el análisis y compila el artículo.
`./reproducir.ps1 -SoloArticulo` recompila utilizando las tablas ya generadas.
Después de verificar los resultados con `python verificar_resultados.py`,
`python empaquetar.py` actualiza el ZIP
mediante una lista explícita de archivos agregados y comprueba su integridad.
Estos comandos no realizan commits ni push.

## Alcance de las conclusiones

- WLSMV incorpora `FEX_P`. Faltan identificadores de estratificación y
  UPM/conglomerados en los archivos utilizados; los errores estándar y pruebas no
  representan un ajuste completo del diseño. `DIRECTORIO` y `REGION` no sustituyen
  esas variables.
- El ajuste robusto del modelo principal es débil: CFI 0,900 y RMSEA 0,092,
  aunque los índices escalados son más favorables. Las asociaciones son pequeñas
  y el R² es aproximadamente 0,016.
- La diferencia institucional por sexo no conserva significación en las pruebas
  específicas ajustadas por Holm y Bonferroni (p=0,067). La prueba conjunta
  (p=0,017) es un contraste distinto y no localiza por sí sola una ruta particular.
- La revisión residual es exploratoria. La pareja de ítems se identificó antes
  con información de la base completa; la partición posterior evalúa estabilidad
  interna y no constituye validación independiente.
- El escenario que infla errores con un multiplicador basado en Kish es hipotético,
  puede duplicar variabilidad ya incorporada y no estima el efecto de diseño del SEM.
- HTMT y los descriptivos de Fase 1 se identifican explícitamente como no ponderados.
  Las matrices muestrales ponderadas utilizadas por el AFC se exportan por separado.
- Familiaridad declarada no equivale a conocimiento factual, uso o participación.
  Los datos transversales no identifican efectos causales.

## Materiales de Fase 1

El script `Taller1_SEM_reproducible.R`, el reporte en `output/pdf/`, los scripts
exploratorios anteriores y las notas numeradas se conservan como antecedentes del
Taller 1. No son el punto de entrada del artículo vigente. Las notas históricas
pueden describir decisiones y salidas previas; prevalecen el artículo actualizado,
`REVISION_PUBLICACION.md` y el ejecutor canónico del Taller 2.
