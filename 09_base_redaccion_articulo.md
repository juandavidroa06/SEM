# Base de redacción para el artículo

**Estado:** borrador de trabajo basado en los análisis disponibles; requiere revisión del equipo y del docente antes de enviar o presentar como manuscrito final.

## Título provisional

**Confianza interpersonal, confianza institucional y familiaridad con mecanismos de participación ciudadana: análisis de la ECP 2023 en Colombia**

## Pregunta y alcance

¿Cómo se asocian la confianza interpersonal y la confianza institucional con la familiaridad autorreportada con mecanismos de participación ciudadana entre las personas entrevistadas en la Encuesta de Cultura Política de Colombia de 2023? El diseño transversal permite estudiar asociaciones, no establecer dirección causal.

## Resumen de trabajo

Este estudio examinó la asociación entre confianza interpersonal, confianza institucional y familiaridad autorreportada con mecanismos de participación ciudadana, mediante un modelo de ecuaciones estructurales aplicado a microdatos de la Encuesta de Cultura Política (ECP) 2023 del DANE. Se integraron cinco módulos por los identificadores de vivienda, encuesta, hogar y persona; la intersección analítica incluyó 46.392 personas. Los indicadores ordinales y binarios se analizaron con WLSMV y los modelos se ponderaron con el factor de expansión `FEX_P`. El ajuste robusto del modelo de tres factores fue débil (CFI=.900; TLI=.890; RMSEA=.092; SRMR=.040), aunque los índices escalados fueron más favorables (CFI=.981; RMSEA=.046). Las dos asociaciones estructurales fueron positivas, con coeficientes estandarizados pequeños (β=.094 y β=.065); el modelo explicó 1,6% de la varianza del factor endógeno. En el análisis multigrupo por sexo, la ruta de confianza institucional fue mayor entre hombres que entre mujeres, mientras que la ruta interpersonal no mostró diferencia estadística. Como los archivos anonimizados no contienen UPM/conglomerado ni estrato y el DANE no ofrece identificadores ni estimaciones alternativas de varianza para este análisis, los errores estándar y contrastes no reflejan el diseño complejo completo. Los hallazgos se interpretan como exploratorios y asociativos.

**Palabras clave provisionales:** confianza interpersonal; confianza institucional; participación ciudadana; ecuaciones estructurales; encuesta compleja; Colombia.

## Método: texto base

### Diseño y fuente de datos

Se realizó un análisis transversal de microdatos anonimizados de la ECP 2023 del Departamento Administrativo Nacional de Estadística (DANE). La ECP es una encuesta probabilística, estratificada, multietápica y de conglomerados. La base analítica se formó mediante la intersección de los módulos Democracia, Participación, Capital Social, Características generales y Características generales 2, unidos por `DIRECTORIO`, `NRO_ENCUESTA`, `HOGAR_NUMERO` y `PERSONA_NUMERO`. La intersección fue de 46.392 personas, sin claves duplicadas ni incompletas en los módulos revisados. El modelo usó información disponible por pares; por tanto, el N de 46.392 no significa que todas las personas tuvieran respuesta en los 25 indicadores. 35.024 personas (75,5%) presentaron información completa en todos ellos.

El factor de expansión `FEX_P`, definido por el DANE en la Tabla de viviendas, se enlazó a cada registro de persona mediante `DIRECTORIO`. Se empleó para ponderar las estimaciones. Los archivos anonimizados disponibles no contienen los identificadores de estrato ni UPM/conglomerado requeridos para reproducir íntegramente el diseño en la estimación de varianzas. Según la información proporcionada por el equipo, el DANE no ofrece esos identificadores ni un cálculo alternativo de varianza para este análisis. En consecuencia, los errores estándar, intervalos y pruebas se reportan como inferencia exploratoria ponderada y no como inferencia plenamente ajustada al diseño complejo.

### Medidas y especificación

La confianza interpersonal se midió con cuatro indicadores ordinales de confianza en personas desconocidas, vecinos, amistades y personas de otra nacionalidad (P2025S4–P2025S7). La confianza institucional se especificó con quince indicadores ordinales sobre instituciones públicas (P5263S1–P5263S15). La familiaridad autorreportada con mecanismos de participación se midió con seis indicadores binarios de reconocimiento de mecanismos (P5376S1–P5376S6), recodificados como 1=conoce y 0=no conoce. Este factor representa familiaridad declarada, no una prueba objetiva de conocimiento. Las respuestas 99 en las escalas de confianza se trataron como perdidas; los faltantes estructurales se conservaron como perdidos.

Se estimó un modelo de tres factores correlacionados y dos rutas estructurales hacia familiaridad con mecanismos: confianza interpersonal y confianza institucional. Se ajustó además una estructura exploratoria que dividió la confianza institucional en dos factores. La encuesta es transversal; por ello, las rutas se interpretan como asociaciones compatibles con la especificación, no como efectos causales.

### Estrategia analítica

Los indicadores ordinales se estimaron con WLSMV y faltantes por pares. Se incorporó `FEX_P` en los modelos de AFC, SEM e invariancia. Se examinaron índices de ajuste robustos y escalados, cargas, confiabilidad compuesta, AVE, HTMT y residuos locales. La magnitud de asociación se describió con coeficientes estandarizados, R² y f² incremental. La invariancia ordinal por sexo se evaluó en una secuencia configural, de umbrales y métrica (umbrales más cargas), con identificación Wu–Estabrook y parametrización theta. Los cambios aproximados de ajuste se consideraron junto con las pruebas de diferencia, dado el tamaño muestral y la sensibilidad de chi-cuadrado.

## Resultados: texto base

### Medición y ajuste

El AFC ponderado de tres factores convergió y no mostró señales de solución impropia en las comprobaciones realizadas. Sin embargo, el ajuste robusto fue débil: χ² escalado(272)=27.181,35, p<.001; CFI=.900; TLI=.890; RMSEA=.092, IC 90% [.091,.093]; SRMR=.040. Los índices escalados fueron CFI=.981, TLI=.979 y RMSEA=.046, discrepancia que debe conservarse explícita en la interpretación. El modelo institucional exploratorio de dos factores mejoró algunos índices robustos (CFI=.913; RMSEA=.086; SRMR=.038), pero el ajuste continuó débil; no se selecciona como modelo definitivo por ajuste únicamente.

La confiabilidad compuesta fue .793 para confianza interpersonal, .968 para confianza institucional y .891 para familiaridad con mecanismos. La AVE fue .492, .668 y .794, respectivamente; la primera queda ligeramente bajo el umbral convencional de .50. Los HTMT disponibles fueron bajos (.069–.286), pero son diagnósticos no ponderados y deben reportarse como evidencia complementaria, no como prueba ponderada concluyente. Los diagnósticos locales mostraron diez residuos de correlación con valor absoluto superior a .10; no se añadieron correlaciones residuales guiadas solo por índices de modificación.

### Asociaciones estructurales y magnitud

La confianza interpersonal se asoció positivamente con familiaridad con mecanismos (B=.119, EE=.011, β=.094, IC 95% de B [.098,.141], p<.001). La confianza institucional también presentó una asociación positiva (B=.066, EE=.008, β=.065, IC 95% de B [.050,.082], p<.001). El R² del factor endógeno fue .016. Los f² incrementales fueron .008 para confianza interpersonal y .004 para confianza institucional, magnitudes muy pequeñas. Debido al ajuste absoluto débil y a la falta de corrección por conglomeración y estratificación, estos coeficientes se interpretan como asociaciones exploratorias.

### Comparación por sexo

Los cambios escalados de ajuste entre los modelos configural, de umbrales y métrico fueron pequeños (|ΔCFI|≤.0005; las disminuciones de RMSEA escalado fueron .0013 y .0014). Sin embargo, la prueba de diferencia entre el modelo configural y el de umbrales fue significativa (Δχ²=59.51, 38 gl, p=.014), mientras que la comparación entre umbrales y métrico no lo fue (Δχ²=31.32, 22 gl, p=.090). Esta discrepancia y el ajuste absoluto robusto débil requieren cautela al afirmar invariancia.

La prueba conjunta de igualdad de las dos rutas estructurales fue significativa (Δχ²=8.21, 2 gl, p=.017). Por ruta, no se encontró diferencia por sexo en la asociación interpersonal (β hombres=.096; β mujeres=.090; p=.650). La asociación institucional fue mayor entre hombres (β=.083) que entre mujeres (β=.049; p=.034). Estas diferencias son provisionales, asociativas y no están corregidas por el diseño completo de la encuesta.

## Discusión: ejes para desarrollar

1. La gran muestra produce valores p pequeños incluso con efectos muy modestos; la lectura sustantiva debe priorizar β, f² y R².
2. El ajuste robusto cuestiona la suficiencia de la medición, especialmente la unidimensionalidad de confianza interpersonal e institucional. La alternativa institucional es exploratoria y requiere validación independiente.
3. La familiaridad autorreportada no debe denominarse conocimiento objetivo ni equipararse con participación efectiva.
4. La diferencia de la ruta institucional por sexo puede orientar una hipótesis futura, pero requiere replicación con incertidumbre correctamente estimada.
5. El factor de expansión pondera los puntos estimados; al faltar identificadores de diseño no se debe presentar la inferencia como plenamente representativa en términos de varianza.

## Limitaciones que deben permanecer en el manuscrito

- Diseño transversal: no identifica temporalidad ni causalidad.
- Ajuste absoluto robusto débil y AVE interpersonal ligeramente bajo .50.
- HTMT calculado sin ponderación; usarlo únicamente como diagnóstico descriptivo complementario.
- `FEX_P` incorporado, pero sin estratos/UPM/conglomerados ni método alternativo de varianza; errores estándar, intervalos, p y pruebas multigrupo son exploratorios.
- 35.024 personas tienen datos completos en los 25 indicadores; el estimador usa información por pares. Hay no aplicabilidad estructural de dos indicadores institucionales en Bogotá.
- La muestra analítica integrada (46.392) no equivale al total de personas informado por el DANE para la operación; el manuscrito debe explicar la intersección de módulos y no confundirla con el total oficial.
- No se incorporaron covariables potencialmente relevantes como edad, educación o ruralidad; cualquier ajuste adicional debe definirse teóricamente antes de cerrar el modelo.

## Cifras y fuentes que deben cotejarse antes de enviar

- Confirmar en la salida vigente de R las cifras finales y versiones de paquetes; la ejecución registrada usó lavaan 0.7-3 y semTools 0.5-10.
- Confirmar la descripción oficial del factor `FEX_P`, su unidad de aplicación y los dominios de inferencia en documentación DANE.
- Explicar por qué 46.392 personas constituyen la intersección temática y cómo se trataron casos con ítems no aplicables.
- Incorporar el marco teórico aprobado, referencias completas y requisitos de la revista una vez se elijan tema, extensión y estilo bibliográfico.
- No reportar los valores p como confirmación definitiva de hipótesis o diferencias poblacionales; enmarcarlos en la limitación del diseño.

## Fuentes de datos y reproducibilidad

- DANE, catálogo ECP 2023: https://microdatos.dane.gov.co/index.php/catalog/822
- Diccionario de Tabla de viviendas (`FEX_P`): https://microdatos.dane.gov.co/index.php/catalog/822/data-dictionary/F15?file_name=Tabla+viviendas
- Boletín técnico ECP 2023: https://www.dane.gov.co/files/operaciones/ECP/bol-ECP-2023.pdf
- Script de integración y estimación: `08_fase2_sem.R`.
- Salidas tabulares y diagnóstico metodológico: carpeta `salidas/` y `08_hallazgos_muestreo_efectos.md`.
- Libro de resultados por bloques: `outputs/01a15760-d284-7790-91e9-a88837c249b8/Taller2_SEM_resultados.xlsx`.
