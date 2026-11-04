# Taller 2: hallazgos iniciales sobre ponderación, muestra y plan de análisis

## Qué se confirmó en los archivos oficiales

La ECP 2023 es una encuesta probabilística estratificada y multietápica, con selección por conglomerados. El catálogo del DANE describe a los conglomerados como segmentos de alrededor de diez viviendas y señala que el factor de expansión incorpora ajustes de marco/cobertura y calibración. Por tanto, el factor sí corresponde para estimaciones que pretendan representar a la población objetivo.

El catálogo publica un archivo separado, `Tabla de viviendas.zip`. Su diccionario define `FEX_P` como “Factor de Expansión”. La tabla contiene 22.994 viviendas y un `DIRECTORIO` único por fila. Se enlazó con los registros de personas por `DIRECTORIO`; las 46.392 personas integradas encontraron un peso, sin faltantes. El factor es constante entre las personas asociadas a una misma vivienda, como corresponde a esta tabla.

La base integrada usa cinco módulos de personas: Democracia, Participación, Capital Social, Características generales y Características generales 2. La intersección por `DIRECTORIO`, `NRO_ENCUESTA`, `HOGAR_NUMERO` y `PERSONA_NUMERO` es de 46.392 casos. La tabla de viviendas agrega el peso y las variables geográficas. La estructura del diseño publicada en el manual no debe confundirse con variables de diseño disponibles en los microdatos: los ZIP anonimizados no exponen el identificador de UPM/conglomerado ni el estrato de muestreo.

## Conteos y pesos verificados

| Base / grupo | n sin ponderar | Suma de `FEX_P` | n efectivo de Kish por variación de pesos* |
|---|---:|---:|---:|
| Integrada, cinco módulos | 46.392 | 37.076.519 | 26.389 |
| Casos completos en los 25 indicadores | 35.024 | 26.253.743 | 18.567 |
| Hombres | 21.405 | 17.723.852 | 12.106 |
| Mujeres | 24.987 | 19.352.667 | 14.325 |

`FEX_P` varía aproximadamente entre 7,62 y 10.334,50 (mediana 642,70). La suma ponderada es una suma de factores sobre los registros analíticos enlazados; no debe presentarse como un total oficial publicado sin cotejar el universo y los dominios de estimación. El tamaño efectivo de Kish es solo un diagnóstico de pérdida de precisión por desigualdad de pesos: **no incorpora conglomeración, estratificación ni faltantes** y no reemplaza el tamaño efectivo de diseño.

Las cinco regiones tienen al menos 4.451 registros en la intersección integrada; sin embargo, el filtro previo de casos completos deja cero observaciones completas en Bogotá. Los documentos del Taller 1 ya señalan que Asamblea y Gobernación no aplican en Bogotá. Por eso la comparación multigrupo inicial se propone por sexo (`P220`: hombre/mujer), no por región: ambos grupos son grandes y conservan casos de Bogotá. Se usará tratamiento ordinal con faltantes por pares; aun así, hay que inspeccionar frecuencias y umbrales escasos antes de interpretar la invariancia.

## Implicaciones metodológicas para el Taller 2

1. **Ponderación:** incorporar `FEX_P` en AFC, SEM y multigrupo. La variable está a nivel de vivienda y se propaga a sus personas mediante `DIRECTORIO`; no se calcula un peso nuevo con el tamaño muestral.
2. **Diseño complejo y errores estándar:** la ponderación es viable, pero no basta para replicar todo el diseño. Los datos publicados no incluyen identificador de conglomerado/UPM ni estrato real. `REGION` tiene cinco dominios geográficos y `DIRECTORIO` identifica viviendas; ninguno debe usarse como sustituto del conglomerado o estrato DANE. El usuario confirma que el DANE no puede proporcionar esos identificadores ni ofrece el cálculo alternativo de varianzas. Por tanto, se continúa con `FEX_P` para ponderar las estimaciones puntuales, pero los errores estándar, pruebas e intervalos no están plenamente ajustados al diseño. Los resultados inferenciales se presentarán como exploratorios y esta limitación permanecerá explícita.
3. **Faltantes:** la eliminación completa previa retiene 35.024 de 46.392 personas (75,5%) y excluye por completo la región Bogotá. El nuevo flujo usa WLSMV con información disponible por pares, como permite el enunciado del Taller 2, para no descartar automáticamente esos casos. Los dos ítems institucionales no aplicables en Bogotá siguen requiriendo revisión sustantiva y diagnóstica.
4. **Tamaño de efecto:** por el gran n, no se interpretará `p` como medida de importancia. Reportar coeficientes latentes estandarizados con intervalos, `R²` del factor de familiaridad y `f²` incremental único calculado desde los coeficientes estandarizados y la correlación de predictores. Dar prioridad a la magnitud, dirección e incertidumbre.
5. **Efectos indirectos:** el modelo aprobado no contiene mediador ni segundo resultado endógeno. No corresponde inventar una mediación; la actividad de efectos indirectos se documentará como no aplicable a esta especificación.
6. **Modelo alternativo:** conservar como sensibilidad la confianza institucional en dos dimensiones ya planteada en el Taller 1. Es exploratoria y no reemplaza la estructura aprobada. No es una alternativa anidada simple; además, WLSMV no ofrece comparación AIC/BIC convencional, así que se reportará el ajuste descriptivo y las limitaciones, sin declarar ganador solo por los índices.
7. **Multigrupo:** estimar invariancia ordinal configural, de umbrales y métrica (umbrales + cargas) entre hombres y mujeres, con identificación Wu–Estabrook y parametrización theta. Si al menos se sostiene la métrica, comparar las rutas estructurales libres e iguales entre grupos. Interpretar diferencias de grupo como moderación asociativa, no causal.

## Estado de ejecución

El script `08_fase2_sem.R` integra los cinco módulos y `Tabla de viviendas.zip`, verifica claves y `FEX_P`, y genera las salidas de abajo. Se instalaron `lavaan` y `semTools` (con sus dependencias) en la biblioteca de usuario de R 4.6.1.

### AFC y medición

El AFC ponderado convergió y pasó `post.check`, sin señales de solución impropia ni correlaciones latentes mayores que uno. Los índices ordinarios y escalados se ven favorables (CFI escalado = 0,981; RMSEA escalado = 0,046; SRMR = 0,040), mientras los índices robustos de lavaan son más débiles (CFI robusto = 0,900; TLI robusto = 0,890; RMSEA robusto = 0,092; IC 90% [0,091; 0,093]). Se reportan ambas versiones porque difieren sustantivamente bajo WLSMV; el ajuste no se declarará inequívocamente adecuado.

La confiabilidad compuesta fue 0,793 para confianza interpersonal, 0,968 para confianza institucional y 0,891 para familiaridad con mecanismos. Las AVE fueron 0,492, 0,668 y 0,794, respectivamente; la AVE interpersonal queda apenas bajo 0,50. Los HTMT descriptivos fueron 0,286 entre las dos confianzas, 0,069 entre confianza interpersonal y familiaridad, y 0,090 entre confianza institucional y familiaridad, todos bajo 0,85. **Estos HTMT se calcularon sin ponderación** (la función utilizada no recibió `FEX_P`); deben tratarse como diagnóstico complementario y no como evidencia ponderada de validez discriminante.

El ajuste local merece atención: 10 de 300 residuos de correlación superan |0,10|; el mayor en valor absoluto fue −0,219 entre P2025S4 y P2025S6. Los mayores índices de modificación sugieren dependencia residual entre indicadores cercanos en contenido, especialmente P2025S5–P2025S6 y P5263S3–P5263S9. No se liberaron parámetros solo por estos índices; cualquier revisión requiere justificar contenido y validarla en otra muestra o submuestra.

### SEM y tamaños de efecto

Las rutas ponderadas son positivas: confianza interpersonal → familiaridad, β estandarizado = 0,094 (coeficiente no estandarizado = 0,119; EE = 0,011; IC 95% [0,098; 0,141]); confianza institucional → familiaridad, β = 0,065 (coeficiente = 0,066; EE = 0,008; IC 95% [0,050; 0,082]). Ambas pruebas unilaterales para el signo positivo dan p < 0,001. El `R²` latente de familiaridad es 0,016. Los `f²` incrementales únicos son 0,0083 para confianza interpersonal y 0,0040 para confianza institucional: las asociaciones son pequeñas pese a su alta significación estadística.

El AFC correlacionado y el SEM de referencia resultan equivalentes: lavaan confirma que implican la misma estructura de momentos y que una diferencia de chi-cuadrado no es interpretable. Esto concuerda con que el SEM deja libre la covarianza entre las dos confianzas y es saturado en las tres covarianzas latentes. El modelo institucional alternativo de dos dimensiones mejora algo el ajuste robusto (CFI = 0,913; RMSEA = 0,086; SRMR = 0,038), pero sigue mostrando ajuste débil y permanece exploratorio. No se infieren efectos indirectos porque el modelo no incluye mediador.

### Invariancia y diferencias por sexo

La secuencia ordinal se estimó con identificación Wu–Estabrook y parametrización theta. Según cambios escalados, se sostiene la invariancia de umbrales (ΔCFI = −0,0002; ΔRMSEA = −0,0013; ΔSRMR ≈ 0) y métrica (ΔCFI = +0,0005; ΔRMSEA = −0,0014; ΔSRMR ≈ +0,00001). La prueba de diferencia rechaza el paso configural→umbrales (p = 0,014), pero no el paso umbrales→métrico (p = 0,090); con el tamaño muestral amplio, se da prioridad a los cambios aproximados, documentando la discrepancia. El ajuste absoluto robusto del modelo configural también es débil, por lo que las comparaciones se interpretan con cautela.

Al restringir conjuntamente las dos rutas estructurales, la prueba de diferencia fue significativa (Δχ² ajustado = 8,21; 2 gl; p = 0,017). Las pruebas de Wald por ruta indican que la asociación interpersonal no cambia por sexo (p = 0,650), mientras la asociación institucional es mayor en hombres (β = 0,083) que en mujeres (β = 0,049; p = 0,034). Es moderación asociativa provisional; los errores estándar y pruebas siguen sin corrección por UPM y estrato.

Estos valores de p y sus intervalos usan el peso `FEX_P`, pero **no** una varianza completa de encuesta compleja. El DANE no ofrece los identificadores de diseño ni un cálculo alternativo de varianza para este análisis. En consecuencia, las conclusiones de hipótesis e invariancia se conservarán como resultados exploratorios de modelos ponderados, sin ajuste completo del diseño; no se afirmará que sus errores estándar o pruebas representan toda la incertidumbre del diseño muestral.

Antes del artículo hay que resolver también una diferencia de cobertura que merece cotejo: el sitio del DANE informa 64.770 participantes en la operación, mientras los módulos de cultura política integrados en estos ZIP tienen 46.392 registros de persona. La base de Características generales contiene 64.759 registros de personas del hogar, pero solo 46.392 empatan con los cuatro módulos temáticos. El flujo debe describirse con precisión y la cifra oficial debe atribuirse a la publicación del DANE, no confundirse con la muestra analítica integrada.

## Archivos reproducibles

- `08_fase2_sem.R`: integración, diagnóstico de pesos y flujo de modelos de Taller 2.
- `salidas/08_diseno_muestral.csv`: conteos, suma de pesos y Kish por pesos.
- `salidas/08_grupos_sexo.csv`: tamaño y diagnóstico de pesos por grupo.
- `salidas/08_grupos_region.csv`: conteos regionales de la intersección integrada.
- `salidas/08_ajuste.csv`, `08_hipotesis.csv`, `08_tamanos_efecto.csv`: AFC, SEM y tamaños de asociación.
- `salidas/08_confiabilidad.csv`, `08_AVE.csv`, `08_HTMT.csv`: medición y validez.
- `salidas/08_invarianza_sexo.csv`, `08_invarianza_cambios_ajuste.csv`, `08_invarianza_diferencias_chi2.csv`, `08_invarianza_wald_rutas.csv`: invariancia ordinal y diferencias entre rutas.
- `salidas/08_residuos_correlacion.csv` y `08_indices_modificacion.csv`: diagnóstico local.

No se exporta aquí otra copia de los microdatos integrados. Los ZIP se mantienen localmente en `datos_crudos/`.

## Fuentes oficiales consultadas

- [Catálogo de microdatos ECP 2023: archivos y diccionario de Tabla de viviendas](https://microdatos.dane.gov.co/index.php/catalog/822/get-microdata)
- [Diccionario oficial de Tabla de viviendas: `FEX_P`, Factor de Expansión](https://microdatos.dane.gov.co/index.php/catalog/822/data-dictionary/F15?file_name=Tabla+viviendas)
- [Metodología general ECP, versión 9](https://www.dane.gov.co/files/operaciones/ECP/DSO-ECP-MET-001-V9.pdf)
- [Información oficial ECP 2023: resultados y número de participantes publicado](https://www.dane.gov.co/index.php/estadisticas-por-tema/cultura/cultura-politica-encuesta)
