# Taller 1 SEM: ECP 2023

Proyecto de trabajo en R para el Taller 1 de Modelacion de Ecuaciones Estructurales.

## Fuente

- Entidad: Departamento Administrativo Nacional de Estadistica (DANE).
- Operacion: Encuesta de Cultura Politica (ECP), 2023.
- Catalogo oficial ANDA: <https://microdatos.dane.gov.co/index.php/catalog/822>.
- Fecha de descarga: 2026-10-19.
- Revisar y documentar los terminos de uso indicados por ANDA en la entrega.

## Contenido

- `datos_crudos/`: carpeta local para los ZIP originales descargados del DANE;
  por sus condiciones de uso, los microdatos no se versionan en este repositorio.
- `documentacion/`: cuestionario, manual técnico y diccionario oficial en ZIP.
- `00_inspeccion_base.R`: script inicial en R base que lee los CSV directamente
  desde los ZIP y genera un diagnostico de filas, variables e identificadores.
- `01_perfil_indicadores.R`: recodifica valores especiales para el perfil y
  genera frecuencias de los indicadores candidatos.
- `02_estimacion_sem.R`: estima los CFA por constructo y el SEM integrado con
  `lavaan`, usando WLSMV para indicadores ordinales/binarios.
- `03_comparacion_medicion.R`: compara el baseline aprobado con alternativas
  teóricas para cada constructo, usando una muestra común.
- `04_sem_instituciones_dos_dimensiones.R`: reestima en una misma muestra el
  SEM aprobado y el alternativo con dos dimensiones institucionales; este
  último es exploratorio.
- `05_calidad_descriptivos.R`: valida rangos e IDs, analiza faltantes, patrones,
  Little MCAR, perfiles constantes, descriptivos, distancias y Mardia.
- `05_resultados_calidad_descriptivos.md`: interpreta estos diagnósticos y sus
  límites para indicadores ordinales/binarios.
- `06_asociacion_afe.R`: estima matriz policórica, alfa ordinal, omega total,
  correlación ítem-resto, KMO, Bartlett, análisis paralelo y AFE MINRES oblimin.
- `06_resultados_asociacion_afe.md`: interpreta resultados de las soluciones
  exploratoria de cinco factores y teórica de tres factores.
- `07_especificacion_modelo.md`: marco conceptual, hipótesis con signos,
  diagrama, ecuaciones y matrices LISREL, conteo/identificación y modelo rival.
- `07_especificacion_modelo.R`: exporta sintaxis `lavaan` y conteo reproducible
  para las versiones de referencia y rival, sin estimarlas.
- `07_diagrama_modelo.svg`: diagrama de caminos con indicadores observados y
  constructos latentes.
- `04_comparacion_teorica_medicion.md`: interpreta las comparaciones y deja
  documentada la decisión provisional; el modelo aprobado permanece como
  referencia.
- `salidas/`: resultados generados por los scripts.

## Datos y entregables con microdatos

Para reproducir los análisis, descarga los módulos de la ECP 2023 desde el
[catálogo ANDA del DANE](https://microdatos.dane.gov.co/index.php/catalog/822)
y coloca los ZIP en `datos_crudos/` con los nombres esperados por los scripts.
No subas esos archivos al repositorio. El Excel de entrega y el ZIP final también
se mantienen localmente porque incluyen filas de microdatos; están en
`outputs/01a15760-d284-7790-91e9-a88837c249b8/` y `entregables/` en la carpeta
de trabajo original. El reporte PDF, el código y las tablas agregadas sí están
versionados.

El primer diagnóstico de R encontró 46.392 registros en cada uno de los módulos
de Democracia, Participación y Capital Social; los identificadores de persona
están completos y no se repiten en esos módulos. El módulo de Características
generales tiene 64.759 registros. La intersección de identificadores entre los
cuatro archivos es de 46.392 personas. El resultado reproducible está en
`salidas/00_diagnostico_modulos.csv`.

Los lectores ZIP buscan la extensión CSV por bytes para evitar fallos de
conversión de los nombres acentuados del DANE en Windows.

Abrir `Taller1_SEM_ECP2023.Rproj` en RStudio y ejecutar los scripts en orden.
Los constructos e indicadores propuestos se revisaron con el cuestionario y el
diagnostico; la propuesta fue aprobada por el docente el 20-10-2026.

## Ejecucion del modelo

`02_estimacion_sem.R` requiere `lavaan`. Ya fue instalado en R 4.6.1 en la
biblioteca de usuario de RStudio. Si se ejecuta desde otra sesión y no se
encuentra el paquete, verificar `.libPaths()` antes de reinstalarlo. El script
compara primero los modelos de medida por constructo y después estima el modelo
estructural; guarda tablas en `salidas/`.

Para reproducir la comparación de medición, ejecutar `source("03_comparacion_medicion.R")`.
La misma muestra completa se usa en las seis especificaciones. Ver la nota
`04_comparacion_teorica_medicion.md` antes de interpretar o modificar el SEM.
Para la comparación estructural exploratoria, ejecutar
`source("04_sem_instituciones_dos_dimensiones.R")`. El reporte explica por qué
la alternativa de dos dimensiones no sustituye el modelo de referencia.
Para reproducir calidad y descriptivos, ejecutar
`source("05_calidad_descriptivos.R")`; ver `05_resultados_calidad_descriptivos.md`
para leer las decisiones y limitaciones.
Para reproducir asociaciones y AFE, instalar `psych` y `GPArotation` si hacen
falta (`install.packages(c("psych", "GPArotation"))`) y ejecutar
`source("06_asociacion_afe.R")`. Ver `06_resultados_asociacion_afe.md` antes de
interpretar el número de factores: el análisis paralelo sugiere cinco, mientras
la solución de tres factores sirve como contraste de la hipótesis del taller.
Para exportar las sintaxis del modelo de referencia y el rival, ejecutar
`source("07_especificacion_modelo.R")`; consultar `07_especificacion_modelo.md`
para el marco teórico, las matrices, la identificación y la equivalencia posible
entre las dos direcciones estructurales.
