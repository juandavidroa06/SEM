# Resultados de calidad y descripción de indicadores

**Base:** Encuesta de Cultura Política (ECP) 2023, módulos de Democracia, Participación y Capital Social. **Unidad:** persona entrevistada. **Indicadores:** 25 (4 de confianza interpersonal, 15 institucionales y 6 de conocimiento). **Ejecución:** R 4.6.1; semilla 2026.

El análisis se reproduce con `source("05_calidad_descriptivos.R")` desde `Taller1_SEM_ECP2023.Rproj`. El script usa R base, conserva los datos crudos y deja las tablas y figuras en `salidas/05_*`.

## Integridad y rangos

La integración produjo 46.392 registros. No se encontraron IDs duplicados en los módulos ni en la base integrada; los cuatro campos de identificación estaban completos en el diagnóstico previo. Tras aplicar los códigos del formulario, no hay valores fuera del rango permitido en los 25 indicadores. Los códigos 99 se convierten en faltantes en las baterías de confianza; P5376S1–S6 se recodifican de 1/2 a 1/0 (conoce/no conoce).

## Datos faltantes

De 46.392 personas, 35.024 tienen respuesta completa en los 25 indicadores (75,50%); 11.368 tienen al menos un faltante. La media es 1,42 indicadores faltantes por persona, la mediana es cero y el máximo es 19. Se detectaron 1.331 patrones distintos de faltantes.

| Indicador/patrón | n | Porcentaje |
|---|---:|---:|
| Casos completos | 35.024 | 75,50 |
| Solo faltan Asamblea y Gobernación (P5263S6, S12) | 4.219 | 9,09 |
| Falta la batería institucional completa (P5263S1–S15) | 1.712 | 3,69 |

Los faltantes por indicador son 0% en los seis ítems de conocimiento, 0,92%–2,38% en confianza interpersonal y 5,42%–19,94% en confianza institucional. Los mayores porcentajes corresponden a Asamblea departamental (19,94%) y Gobernación (17,65%); el formulario marca ambas como no aplicables en Bogotá. El código 99 significa “no sabe/no informa”; la no aplicabilidad territorial puede estar almacenada como otro tipo de vacío. Como este archivo de análisis no incorpora una variable geográfica que permita identificar cada caso, no atribuimos automáticamente cada faltante a una sola causa.

### Prueba de Little

Se calculó la estadística de Little mediante EM normal multivariado implementado en R base, en dos sensibilidades. En 23 indicadores, excluyendo las preguntas territoriales de Asamblea y Gobernación, se obtuvo χ²(15.979) = 26.698,60, p < 2,2 × 10⁻¹⁶ (958 patrones). Con los 25 indicadores: χ²(23.992) = 40.316,59, p < 2,2 × 10⁻¹⁶ (1.331 patrones). El EM convergió en 8 y 10 iteraciones, respectivamente.

En ambas sensibilidades se rechaza la hipótesis nula de MCAR. Esto indica que los patrones observados no son compatibles con faltantes completamente aleatorios bajo el modelo normal empleado; **no permite distinguir por sí solo MAR de MNAR**. La interpretación también es limitada porque los indicadores son ordinales/binarios, los faltantes incluyen 99 y hay no aplicabilidad territorial documentada. La asociación de faltantes con variables geográficas observadas y el mecanismo deben examinarse antes de decidir entre casos completos, FIML o imputación.

## Distribuciones, asimetría y curtosis

La tabla completa está en `salidas/05_descriptivos_indicadores.csv`; incluye media, desviación estándar, mediana, mínimo, máximo, asimetría, curtosis en exceso, frecuencias y proporción en categorías extremas. Estas estadísticas numéricas resumen categorías ordenadas como códigos y no implican que las distancias entre categorías sean intervalares.

En confianza interpersonal se observa concentración en la categoría mínima para personas desconocidas (54,71%, media 1,72) y para personas de otra nacionalidad (52,31%, media 1,77). La confianza en amistades es más alta (media 3,27). En conocimiento, las proporciones que responden “sí conoce” van de 22,98% para iniciativa popular y 24,98% para cabildo abierto hasta 42,57% para plebiscito. Los seis ítems de conocimiento no tienen faltantes tras recodificar.

## Patrones constantes y atípicos

Se contó el perfil constante solo entre personas completas en cada batería. El mismo valor en todos los ítems aparece en 4.881 personas de confianza interpersonal (10,84%), 10.380 de confianza institucional (29,24%) y 24.353 de conocimiento (52,49%). En la batería binaria de conocimiento esto puede ser una respuesta sustantiva (por ejemplo, no conocer ninguno) y no prueba descuido; no se excluyen personas por este criterio.

No hay indicadores continuos, por lo que puntajes z robustos y boxplots de valores continuos no aplican. Como chequeo exploratorio adicional, se calcularon distancias de Mahalanobis usando las categorías numéricas de los 25 indicadores en los 35.024 casos completos. Con el umbral χ²(25) al percentil 99,9, 2.591 casos (7,40%) superan el corte. Al ser respuestas discretas y no normales, el umbral es solo una bandera descriptiva y no justifica eliminar casos. Los 100 mayores valores con sus identificadores están en `salidas/05_atipicos_multivariados_casos.csv` para revisión.

## Normalidad multivariada (Mardia)

Para reducir el costo de la matriz de distancias por pares, se usó una submuestra aleatoria reproducible de 2.000 casos completos de los 35.024 disponibles. Con los códigos numéricos de los 25 indicadores, b₁,p = 58,997 y χ²(2.925) = 19.665,62, p < 2,2 × 10⁻¹⁶; b₂,p = 963,09 frente al valor de referencia p(p + 2) = 675, con z = 175,33 y p < 2,2 × 10⁻¹⁶. La normalidad multivariada queda claramente rechazada bajo este cálculo.

La conclusión coincide con lo esperable en respuestas ordinales y binarias acotadas. Mardia se presenta como diagnóstico solicitado, no como supuesto literal para estas variables; respalda el uso de estimadores categóricos/robustos como WLSMV frente a máxima verosimilitud normal convencional. La submuestra y el carácter discreto de los indicadores limitan la lectura inferencial de los valores p.

## Archivos de salida

- `05_validacion_rangos.csv`
- `05_faltantes_por_indicador.csv`, `05_faltantes_por_persona.csv`, `05_resumen_faltantes_persona.csv`
- `05_patrones_faltantes.csv`, `05_prueba_little_mcar.csv`, `05_patrones_constantes.csv`
- `05_descriptivos_indicadores.csv`, `05_normalidad_mardia.csv`
- `05_atipicos_multivariados_resumen.csv`, `05_atipicos_multivariados_casos.csv`
- `05_mapa_faltantes.png`, `05_distribuciones_indicadores.png`

## Decisiones

1. Conservar los 99 como faltantes y documentar por separado la no aplicabilidad de Asamblea y Gobernación.
2. No excluir automáticamente los perfiles constantes ni las personas señaladas por Mahalanobis.
3. Tratar MCAR como no respaldado; investigar si los faltantes se asocian con variables observadas y comparar estrategias de manejo en la fase de medición.
4. Usar la no normalidad como apoyo para WLSMV con indicadores ordinales/binarios, no para cambiar la escala de las respuestas.
