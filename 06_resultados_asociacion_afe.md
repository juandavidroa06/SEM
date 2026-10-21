# Asociaciones, confiabilidad y estructura exploratoria

## Muestra y decisiones

Se analizaron 25 indicadores de la ECP 2023: cuatro de confianza interpersonal (P2025S4-S7), quince de confianza institucional (P5263S1-S15) y seis de conocimiento de mecanismos (P5376S1-S6). Se recodificó 99 como faltante y los indicadores de conocimiento como 1 = conoce y 0 = no conoce. Para conservar comparabilidad con el CFA previo se usaron los 35.024 casos completos de los 46.392 integrados.

Se estimó una matriz policórica sobre la muestra completa. Para los ítems dicotómicos, la correlación policórica corresponde al caso tetracórico. La matriz fue suavizada por `psych` cuando fue necesario para hacerla utilizable como matriz de correlaciones. La versión de `psych` advierte que los ítems no tienen el mismo número de categorías y desactiva la estimación de umbrales globales; esto es esperable al combinar preguntas binarias con escalas de cinco categorías.

## Asociaciones

El promedio de las correlaciones policóricas dentro de cada bloque fue:

| Bloque | Correlación policórica media intrabloque |
|---|---:|
| Confianza interpersonal | 0,446 |
| Confianza institucional | 0,680 |
| Conocimiento de mecanismos | 0,787 |

Promedios entre bloques: interpersonal-institucional = 0,157; interpersonal-conocimiento = 0,061; institucional-conocimiento = 0,077. El patrón respalda la distinción entre dimensiones y muestra asociaciones internas sustanciales. El mapa completo está en `salidas/06_mapa_calor_policoricas.png`; matriz numérica en `salidas/06_matriz_policorica.csv`.

## Confiabilidad e ítem-resto

El alfa calculado sobre la matriz policórica (alfa ordinal) y omega total fueron:

| Constructo | Alfa policórico | Omega total |
|---|---:|---:|
| Confianza interpersonal (4 ítems) | 0,763 | 0,765 |
| Confianza institucional (15 ítems) | 0,970 | 0,970 |
| Conocimiento de mecanismos (6 ítems) | 0,957 | 0,957 |

Las correlaciones corregidas ítem-resto fueron todas positivas. Los rangos fueron 0,513-0,629 para interpersonal, 0,675-0,891 para institucional y 0,824-0,919 para conocimiento. No hay un ítem con correlación negativa que sugiera automáticamente recodificación inversa. Los valores muy altos de las dos últimas baterías aconsejan revisar redundancia de contenido y multidimensionalidad; confiabilidad alta no demuestra unidimensionalidad. Los resultados por ítem están en `salidas/06_correlacion_item_resto.csv`.

Omega se reporta como omega total. La advertencia de `psych` sobre omega jerárquico cuando se solicita un único factor no invalida omega total; omega jerárquico no se interpreta en esta especificación.

## Adecuación factorial

KMO global = 0,945, lo que indica alta adecuación muestral según el índice. Los MSA individuales quedaron por encima de 0,70. Bartlett: chi-cuadrado(300) = 850.994,9; p < 2,2e-16. La prueba rechaza que la matriz sea identidad. Con N grande, Bartlett es muy sensible; debe leerse junto con KMO, matriz y sentido teórico.

## Análisis paralelo y AFE

El análisis paralelo policórico se ejecutó en una submuestra aleatoria reproducible de 2.500 casos, con 30 iteraciones y comparación al percentil 95. Sugirió **cinco factores**. El AFE MINRES con rotación oblimin sobre la matriz policórica de los 35.024 casos se guardó en `salidas/06_cargas_AFE.csv`.

La solución de cinco factores separa el bloque institucional en dos grupos altamente correlacionados (correlación factorial aproximada 0,82) y además divide la confianza interpersonal entre dos factores; P2025S4 presenta una carga ligeramente mayor que 1 y comunalidad de 0,995, señal de una solución límite que requiere revisión. No es un caso Heywood estricto porque la comunalidad no supera 1, pero es una alerta de estimación. Esta división de interpersonal es inestable y puede reflejar que cuatro ítems son pocos para una exploración irrestricta, además de los límites de la matriz categórica. Los cinco factores no deben tratarse como cinco constructos sustantivos aprobados.

Como contraste explícito con la hipótesis teórica aprobada, se estimó también un AFE de tres factores con la misma matriz. Los indicadores se agruparon en los tres bloques previstos, con cargas principales aproximadas de 0,59-0,74 (interpersonal), 0,67-0,92 (institucional) y 0,85-0,94 (conocimiento). Las correlaciones entre esos factores fueron bajas a moderadas (máximo aproximado 0,26). Esta solución es más interpretable y respalda la estructura inicial, pero el ajuste global (TLI ≈ 0,876; RMSR ≈ 0,023) no es concluyente como evidencia confirmatoria. Consultar `salidas/06_cargas_AFE_3_factores.csv` y `salidas/06_ajuste_AFE_3_factores.csv`.

## Alcance y decisiones siguientes

La evidencia exploratoria apoya los tres bloques teóricos, especialmente en cargas y asociaciones intrabloque, mientras el análisis paralelo advierte posible subdivisión. La decisión responsable es conservar los tres constructos como modelo de referencia provisional, comparar la solución de cinco factores con el contenido del cuestionario y el modelo de dos dimensiones institucionales ya discutido, y volver a evaluar en CFA con WLSMV. No se eliminan ítems solamente para elevar confiabilidad.

Los indicadores son ordinales/dicotómicos; la matriz policórica mejora el tratamiento de sus escalas, pero sus estimaciones dependen de supuestos de umbral y pueden ser sensibles a celdas escasas. Los resultados de cinco factores se calcularon con N completo, mientras el análisis paralelo usó 2.500 casos por costo computacional. Repetir el paralelo con otra semilla/submuestra y más iteraciones sería una sensibilidad útil antes de concluir. La tasa de casos completos (75,5%) y el diagnóstico previo de faltantes siguen siendo limitaciones. El AFE no sustituye la comparación confirmatoria ni justifica causalidad.

## Archivos

- `06_asociacion_afe.R`: reproducción integral en R.
- `06_matriz_policorica.csv`, `06_mapa_calor_policoricas.png`.
- `06_confiabilidad.csv`, `06_correlacion_item_resto.csv`.
- `06_KMO_Bartlett.csv`, `06_KMO_individual.csv`.
- `06_analisis_paralelo.png`, `06_resultado_analisis_paralelo.csv`.
- Cargas, correlaciones de factores, residuos y medidas descriptivas del AFE de 5 y 3 factores en `salidas/06_*`.

