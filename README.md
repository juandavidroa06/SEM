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

## Taller 2: ponderación y Fase 2/3

Los ZIP de `datos_crudos/` incluyen ahora `Caracteriasticas generales 2.zip` y
`Tabla de viviendas.zip`. Esta última contiene `FEX_P`, el factor de expansión
documentado por el DANE, enlazable a las personas por `DIRECTORIO`.
Para Taller 2, ejecutar desde la carpeta del proyecto y en este orden:

Estos scripts leen los ZIP crudos: la base integrada del Taller 1 no trae
`FEX_P`, por eso el factor se enlaza desde Tabla de viviendas usando
`DIRECTORIO`.

1. `source("00_preparacion.R")`: integra los cinco módulos, enlaza `FEX_P`
   desde Tabla de viviendas por `DIRECTORIO` y recodifica los 25 indicadores.
2. `source("01_afc.R")`: estima el AFC ponderado y genera medición,
   confiabilidad, AVE, HTMT y Fornell--Larcker.
3. `source("02_estructural.R")`: estima SEM de referencia y rival, y produce
   hipótesis y sensibilidades de pesos, faltantes y efecto aproximado de diseño.
4. `source("03_multigrupo.R")`: estima invariancia ordinal por sexo y Wald con
   ajustes Bonferroni y Holm.
5. `source("04_exportar_resultados.R")`: crea el libro Excel local en `outputs/`.

Los scripts requieren `lavaan`, `semTools` y `writexl` según corresponda;
comprueban los paquetes y no los instalan automáticamente. El script histórico
`08_fase2_sem.R` se conserva para cotejar las salidas anteriores. Ver
`08_hallazgos_muestreo_efectos.md` para los hallazgos confirmados y
la limitación de que los microdatos anonimizados no publican identificadores
del estrato ni del conglomerado muestral. El DANE no ofrece esos identificadores
ni un cálculo alternativo de varianzas para este análisis; por ello las
inferencias se reportan como exploratorias y sin ajuste completo del diseño.
La síntesis lista para desarrollar el manuscrito está en
`09_base_redaccion_articulo.md`. El libro es un derivado local y no se versiona.
Los scripts usan rutas relativas al proyecto y semilla fija `2026`; la biblioteca
de paquetes opcional se agrega solo si existe bajo el perfil del sistema.
