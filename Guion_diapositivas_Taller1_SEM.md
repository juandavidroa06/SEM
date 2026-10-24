# Guion de diapositivas del Taller 1 de SEM

**Tema:** confianza y familiaridad con mecanismos de participación en la Encuesta de Cultura Política de Colombia 2023  
**Duración sugerida:** 12–15 minutos, más preguntas  
**Equipo:** Roa, Aldana y Rodríguez

Este guion propone una secuencia de 12 diapositivas. En cada una se indica el texto breve que puede ir en pantalla, qué elemento visual conviene usar y qué idea explicar oralmente. Los números corresponden a los resultados guardados en el proyecto; las asociaciones se describen como transversales, no como efectos causales.

---

## Diapositiva 1. Título

**En pantalla**

- **Confianza y familiaridad con mecanismos de participación ciudadana**
- Encuesta de Cultura Política, Colombia 2023
- Taller 1 de Modelos de Ecuaciones Estructurales
- Roa · Aldana · Rodríguez | Curso y fecha de exposición

**Visual sugerido:** una imagen sencilla de participación ciudadana o un recorte limpio del diagrama del modelo (`07_diagrama_modelo.svg`). Evitar fotografías decorativas que compitan con el título.

**Para explicar:** el trabajo estudia cómo se relacionan dos formas de confianza con el reconocimiento declarado de mecanismos de participación.

## Diapositiva 2. Problema y pregunta

**En pantalla**

- La familiaridad con los mecanismos legales puede facilitar que las personas reconozcan canales de participación.
- La confianza interpersonal y la institucional pueden relacionarse con esa familiaridad.
- **Pregunta:** ¿Cómo se asocian ambas formas de confianza con la familiaridad autorreportada con mecanismos de participación en personas encuestadas en Colombia en 2023?

**Visual sugerido:** pregunta central con tres conceptos conectados: confianza interpersonal, confianza institucional y familiaridad.

**Para explicar:** la encuesta es transversal y observacional. La pregunta busca asociaciones ajustadas entre constructos; no permite determinar qué variable ocurre primero.

## Diapositiva 3. Conceptos y alcance de la medición

**En pantalla**

- **Confianza interpersonal:** confianza declarada en desconocidos, vecinos, amistades y personas de otra nacionalidad.
- **Confianza institucional:** confianza declarada en 15 instituciones y actores públicos.
- **Familiaridad:** respuesta a si conoce o ha oído hablar de seis mecanismos.
- Familiaridad autorreportada ≠ conocimiento factual comprobado ≠ uso o participación efectiva.

**Visual sugerido:** tres columnas con los constructos y un ejemplo de indicador para cada uno.

**Para explicar:** el constructo interpersonal combina vínculos cercanos y generalizados. Por eso el nombre se mantiene como “confianza interpersonal amplia” y no se presenta como una medida pura de confianza generalizada.

## Diapositiva 4. Base y muestra analítica

**En pantalla**

- Fuente: Encuesta de Cultura Política (ECP), DANE, 2023.
- Intersección de módulos: **46.392 personas**.
- Indicadores analizados: **25** (4 interpersonales, 15 institucionales, 6 de familiaridad).
- Casos completos en los 25 indicadores: **35.024 (75,5%)**.
- Estimador: **WLSMV**, para indicadores ordinales y dicotómicos.

**Visual sugerido:** flujo de muestra: 46.392 integrados → 35.024 completos para el análisis principal. Debajo, una nota sobre el 24,5% con al menos un faltante.

**Para explicar:** la muestra principal usa casos completos. Los resultados y sus limitaciones deben interpretarse con esa decisión en mente.

## Diapositiva 5. Preparación y calidad de los datos

**En pantalla**

- Identificadores completos y sin duplicados en los módulos integrados.
- No se detectaron valores fuera de rango en los 25 indicadores.
- Código 99 de confianza recodificado como faltante.
- Los seis ítems de mecanismos se recodificaron a 1 = conoce y 0 = no conoce.
- Asamblea y Gobernación tienen faltantes estructurales documentados para Bogotá.

**Visual sugerido:** esquema de recodificación o fragmento de `salidas/05_validacion_rangos.csv` reducido a los mensajes principales.

**Para explicar:** algunos vacíos de Asamblea y Gobernación se relacionan con la no aplicabilidad indicada por el formulario. El archivo de análisis no permite asignar una causa territorial a cada vacío individual.

## Diapositiva 6. Faltantes y distribuciones

**En pantalla**

- 11.368 personas tienen al menos un indicador faltante.
- Los casos completos representan 75,5% de la base integrada.
- Little rechaza MCAR en las dos sensibilidades (p < 0,001).
- El rechazo de MCAR no distingue por sí solo entre MAR y MNAR.
- En confianza interpersonal, las respuestas se concentran en la categoría mínima para desconocidos (54,7%) y personas de otra nacionalidad (52,3%).

**Visual sugerido:** `salidas/05_mapa_faltantes.png` o una barra de proporción completa/faltante. Si se usa el mapa, dejar legibles solo los patrones más frecuentes.

**Para explicar:** hay 1.331 patrones de faltantes. Los resultados de Little se calcularon con una aproximación normal multivariada; los indicadores son ordinales/binarios y Asamblea/Gobernación tienen no aplicabilidad territorial. Se requiere estudiar la relación de los faltantes con variables observadas.

## Diapositiva 7. Asociaciones y confiabilidad

**En pantalla**

- KMO global: **0,945**; Bartlett: p < 0,001.
- Correlación policórica media dentro de cada bloque:
  - Interpersonal: **0,446**
  - Institucional: **0,680**
  - Familiaridad con mecanismos: **0,787**
- Alfa policórico / omega total:
  - Interpersonal: **0,763 / 0,765**
  - Institucional: **0,970 / 0,970**
  - Familiaridad: **0,957 / 0,957**

**Visual sugerido:** mapa de calor de `salidas/06_mapa_calor_policoricas.png`, con tres bloques señalados; o una tabla compacta de confiabilidad.

**Para explicar:** la consistencia interna es alta en las baterías institucional y de familiaridad, pero esto no demuestra que cada una sea unidimensional. Los valores altos también pueden reflejar ítems redundantes.

## Diapositiva 8. Estructura exploratoria y medición

**En pantalla**

- El análisis paralelo sugirió **cinco factores** (submuestra de 2.500; 30 iteraciones).
- El AFE de tres factores recuperó los bloques teóricos y fue más interpretable.
- El AFE de cinco factores mostró una solución interpersonal inestable y dividió el bloque institucional.
- Los CFA previos mostraron ajuste mixto, especialmente en confianza interpersonal.
- Se conserva como referencia la estructura aprobada de tres constructos; no se declara validada.

**Visual sugerido:** comparación lado a lado de la estructura teórica de tres factores y la sugerida por el análisis paralelo. Usar `salidas/06_analisis_paralelo.png` o un esquema simplificado.

**Para explicar:** AFE y análisis paralelo ayudan a explorar, pero no sustituyen la evaluación confirmatoria. El modelo aprobado sirve como baseline para el taller, con sus límites explícitos.

## Diapositiva 9. Modelo e hipótesis

**En pantalla**

- **H1 (+):** confianza interpersonal ↔ mayor familiaridad autorreportada.
- **H2 (+):** confianza institucional ↔ mayor familiaridad autorreportada.
- **H3 (+):** covariación entre confianza interpersonal e institucional.
- `Familiaridad = γ₁₁(Confianza interpersonal) + γ₁₂(Confianza institucional) + ζ`
- N = 25 indicadores; 110 parámetros libres ordinales; 272 grados de libertad.

**Visual sugerido:** insertar `07_diagrama_modelo.svg`. Mantener visibles las flechas entre latentes y ocultar códigos de ítems pequeños; una versión detallada puede ir al anexo.

**Para explicar:** los indicadores son ordinales o binarios; se estimó con WLSMV y parametrización delta. Los signos son expectativas teóricas, no resultados asumidos.

## Diapositiva 10. Resultado del SEM de referencia

**En pantalla**

- Ajuste robusto: **CFI = 0,898; TLI = 0,888; RMSEA = 0,095; SRMR = 0,040**.
- Asociación estandarizada interpersonal → familiaridad: **β = 0,073**, p < 0,001.
- Asociación estandarizada institucional → familiaridad: **β = 0,085**, p < 0,001.
- Ambas asociaciones son positivas y pequeñas; el ajuste global es mixto.

**Visual sugerido:** diagrama con flechas etiquetadas β = 0,073 y β = 0,085. Al pie, mostrar en una línea CFI/TLI/RMSEA/SRMR y marcar que los índices robustos son los reportados.

**Para explicar:** los valores p indican evidencia estadística de asociación en esta muestra grande, pero los tamaños estandarizados son modestos y el ajuste no justifica afirmar que la medición esté plenamente respaldada. Reportar “asociación”, nunca “efecto” o “impacto”.

## Diapositiva 11. Modelo rival y sensibilidad institucional

**En pantalla**

- La alternativa separó confianza institucional en representación/gobierno y justicia/control/protección/seguridad.
- Ajuste robusto alternativo: CFI = 0,911; TLI = 0,901; RMSEA = 0,089; SRMR = 0,037.
- Correlación entre las dos dimensiones institucionales: **0,952**.
- Coeficientes simultáneos con signos opuestos; pueden reflejar solapamiento o supresión.
- La alternativa queda como sensibilidad exploratoria; se conserva el factor institucional único aprobado como referencia.

**Visual sugerido:** tabla pequeña de índices del modelo de referencia frente al alternativo, con una advertencia visual sencilla junto a la correlación 0,952.

**Para explicar:** la mejora de ajuste es modesta. Como las dimensiones se solapan mucho, no se interpretan sus coeficientes como asociaciones independientes sólidas ni se reemplaza el modelo de referencia.

## Diapositiva 12. Conclusiones y próximos pasos

**En pantalla**

1. Los bloques teóricos muestran asociaciones internas y confiabilidad adecuadas para continuar evaluando la medición.
2. En el SEM de referencia, ambas confianzas se asocian positivamente, aunque con magnitudes pequeñas.
3. El ajuste global y los diagnósticos factoriales siguen siendo mixtos; la estructura no se declara validada.
4. Los faltantes no son compatibles con MCAR bajo las pruebas aplicadas y el análisis usó casos completos.
5. No se infiere causalidad; el outcome mide familiaridad autorreportada.

**Próximos pasos sugeridos:** revisar medición interpersonal; estudiar faltantes con variables geográficas y otras covariables disponibles; verificar ponderadores, estratos y conglomerados DANE; evaluar alternativas antes de modificar la especificación aprobada.

**Visual sugerido:** tres mensajes finales en texto breve y una franja inferior con “asociación transversal · casos completos · familiaridad autorreportada”.

## Diapositiva 13. Referencias principales

Incluir en pantalla solo referencias legibles; las referencias completas pueden ir en una diapositiva de respaldo o en el documento entregado.

- DANE. (2023). *Encuesta de Cultura Política: formulario y documentación técnica*. [Catálogo ANDA](https://microdatos.dane.gov.co/index.php/catalog/822).
- Delhey, J. y Newton, K. (2005). Predicting cross-national levels of social trust. *European Sociological Review, 21*(4), 311–327. https://doi.org/10.1093/esr/jci022
- Levi, M. y Stoker, L. (2000). Political trust and trustworthiness. *Annual Review of Political Science, 3*, 475–507. https://doi.org/10.1146/annurev.polisci.3.1.475
- Delli Carpini, M. X. y Keeter, S. (1996). *What Americans Know About Politics and Why It Matters*. Yale University Press.
- Li, C.-H. (2016). Confirmatory factor analysis with ordinal data. *Behavior Research Methods, 48*, 936–949. https://doi.org/10.3758/s13428-015-0619-7
- Rosseel, Y. (2012). lavaan: An R package for structural equation modeling. *Journal of Statistical Software, 48*(2), 1–36. https://doi.org/10.18637/jss.v048.i02

---

## Recomendaciones de exposición

- Mantener entre 3 y 5 viñetas por diapositiva; las explicaciones largas quedan para la exposición oral.
- Redondear a tres decimales en coeficientes e índices, y usar coma decimal de forma consistente.
- Señalar siempre si un índice es robusto. En los resultados principales, presentar CFI robusto, TLI robusto y RMSEA robusto junto con SRMR.
- No interpretar el análisis paralelo de cinco factores como una nueva estructura aprobada.
- No presentar p = 0; reportar p < 0,001.
- No llamar “conocimiento objetivo” a la respuesta de si conoce o ha oído hablar de cada mecanismo.
- Si el docente pide reducir la presentación, se pueden unir las diapositivas 5 y 6, y las 7 y 8. Conservar las diapositivas de modelo, resultados y limitaciones.

## Archivos del proyecto para preparar las figuras

- Diagrama: `07_diagrama_modelo.svg`.
- Mapa de faltantes: `salidas/05_mapa_faltantes.png`.
- Distribuciones: `salidas/05_distribuciones_indicadores.png`.
- Mapa policórico: `salidas/06_mapa_calor_policoricas.png`.
- Análisis paralelo: `salidas/06_analisis_paralelo.png`.
- Ajuste, rutas, confiabilidad y descriptivos: tablas CSV correspondientes en `salidas/`.
