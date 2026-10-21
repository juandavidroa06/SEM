# Comparación teórica de especificaciones de medición

**Propósito:** documentar alternativas para las mediciones aprobadas y seleccionar qué conservar para el siguiente análisis. La propuesta original permanece intacta como referencia; esta comparación no reemplaza la aprobación del docente.

## Criterio de comparación

Se estimaron seis CFA con WLSMV para indicadores ordinales/binarios: una especificación aprobada y una alternativa para cada constructo. Todas usan la misma muestra de casos completos (`N = 33.698`) para que la comparación descriptiva no se confunda con cambios de muestra. Es una muestra menor que la empleada en la primera estimación (`N = 35.024`) porque el análisis común incorpora también los ítems de familia y colegas de la alternativa interpersonal.

Los índices robustos se reportan junto con SRMR. El chi-cuadrado resulta significativo con este tamaño muestral y no se usa por sí solo para decidir. El CFI/TLI y RMSEA robustos son débiles en varios modelos; no se declara validada una escala solo porque un índice mejore. Los resultados completos y reproducibles están en `salidas/03_comparacion_medicion.csv`, `salidas/03_cargas_alternativas.csv` y `salidas/03_indices_modificacion.csv`.

## Resultados

| Constructo y especificación | CFI robusto | TLI robusto | RMSEA robusto | SRMR | Lectura provisional |
|---|---:|---:|---:|---:|---|
| Confianza interpersonal aprobada, 4 ítems | 0,749 | 0,248 | 0,396 | 0,108 | Ajuste débil; hay señales de que los cuatro vínculos no son homogéneos. |
| Interpersonal ampliada, agrega familia y colegas | 0,731 | 0,551 | 0,229 | 0,107 | No resuelve el ajuste; el ítem de familia tiene carga estandarizada cercana a 0,03. |
| Confianza institucional aprobada, 1 factor | 0,908 | 0,893 | 0,128 | 0,042 | CFI/TLI razonables, pero RMSEA alto. |
| Institucional, 2 dimensiones correlacionadas | 0,927 | 0,914 | 0,114 | 0,038 | Mejora modesta en todos los índices reportados; persiste desajuste y hay ítems ambiguos. |
| Conocimiento aprobado, 1 factor | 0,938 | 0,897 | 0,215 | 0,027 | SRMR bajo, pero RMSEA robusto alto. |
| Conocimiento, iniciativas/acción y consulta/voto | 0,945 | 0,898 | 0,214 | 0,026 | Mejora mínima; la división no cambia la conclusión de ajuste mixto. |

### 1. Confianza interpersonal

La alternativa ampliada incorporó confianza en familiares (P2025S1) y colegas (P2025S2). Aunque el TLI y RMSEA robustos mejoran frente al modelo de cuatro ítems, el CFI robusto disminuye, el SRMR casi no cambia y la carga de familia es prácticamente nula. No se recomienda añadir familia como indicador reflectivo. Además, la literatura distingue conceptualmente confianza generalizada y confianza particularizada, aunque reconoce que pueden relacionarse ([Delhey y Newton, 2005](https://doi.org/10.1093/esr/jci022)). En la lista aprobada, desconocidos y personas de otra nacionalidad se acercan al dominio generalizado; vecinos y amistades representan vínculos más cercanos. Con solo dos indicadores por dominio, no se propone fijar ahora un CFA de dos factores.

**Decisión provisional:** conservar exactamente los cuatro indicadores aprobados como baseline, sin afirmar que la medición unidimensional ya quedó validada. Revisar con el docente si el constructo debe entenderse como confianza interpersonal amplia o si se redefine teóricamente para obtener indicadores coherentes.

### 2. Confianza institucional

El formulario sitúa los 15 ítems en una sola pregunta (capítulo G, pregunta 17, página impresa 28; repetida en la 29): “En una escala de 1 a 5, donde 1 significa que no confía y 5 que confía mucho, qué tanto confía usted en las siguientes instituciones o actores”. La escala es común (1 = no confía; 2 = confía poco; 3 = ni mucho ni poco; 4 = confía; 5 = confía mucho; 99 = no sabe/no informa). Por tanto, las dimensiones no están separadas por enunciados o escalas distintas; la distinción posible se basa en la función institucional y en los patrones de respuesta. La Asamblea departamental y la Gobernación aparecen expresamente como “no aplica para Bogotá”.

Con el contenido concreto del formulario, los nombres se precisan así:

- **Representación política, gobierno y organización electoral**: Alcaldía, Congreso, Asamblea departamental, concejos, partidos/movimientos, Gobernación, Registraduría y Presidencia (P5263S2, S4, S6, S8, S10, S12, S14, S15). “Organización electoral” se incluye porque la Registraduría no es propiamente un órgano de gobierno; comparte aquí el ámbito político-electoral, no la función ejecutiva.
- **Justicia, control, protección de derechos y seguridad pública**: Procuraduría, Fuerzas Militares, jueces y magistrados, Contraloría, Policía, Defensoría y Fiscalía (P5263S1, S3, S5, S7, S9, S11, S13).

La división es consistente con estudios que advierten que confianza en gobierno, partidos, policía y justicia no necesariamente forma una dimensión única; además, algunos trabajos separan instituciones políticas de instituciones de orden/administración ([estudio de equivalencia de medición](https://doi.org/10.1007/s11205-016-1400-8); [Pattie et al., 2003](https://doi.org/10.1111/1467-9248.00435)). La confianza política también requiere distinguir instituciones y objetos de evaluación ([Levi y Stoker, 2000](https://doi.org/10.1146/annurev.polisci.3.1.475)).

La clasificación sigue siendo una hipótesis de trabajo. La segunda dimensión reúne funciones diferentes (justicia, control, seguridad y protección de derechos), por lo que no se debe nombrar como si fuera un factor puro de “Estado de derecho”. Los índices de modificación muestran solapamiento: especialmente Registraduría con el segundo factor, Defensoría y Registraduría, Fiscalía y Registraduría, y Fuerzas Militares y Policía. Esas señales no justifican liberar parámetros automáticamente; pueden indicar que la separación actual no captura limpiamente la estructura.

**Decisión provisional:** conservar el factor único aprobado como referencia y etiquetar la alternativa como dimensiones de representación/gobierno/organización electoral y justicia/control/protección/seguridad. La evidencia del CFA no basta para reemplazar el factor único.

### 3. Conocimiento de mecanismos de participación

La alternativa separó mecanismos de iniciativa/acción (revocatoria, iniciativa popular y cabildo abierto) de consulta/voto (referendo, plebiscito y consulta popular). La mejora de CFI robusto es pequeña; TLI y RMSEA robustos prácticamente no cambian. La idea de un conocimiento político general es una operacionalización reconocida, aunque una batería puede contener dominios específicos ([Delli Carpini y Keeter, 1996](https://www.jstor.org/stable/j.ctt1cc2kv1)). Los mecanismos nombrados comparten contenido cívico, pero referendo y plebiscito tienen además similitud semántica que puede producir dependencia local entre respuestas.

**Decisión provisional:** mantener el factor unidimensional aprobado para la comparación principal y no adoptar la división de dos factores por una mejora marginal. Se debe describir con precisión como conocimiento/autorreporte de conocimiento de mecanismos, no como prueba objetiva de competencia política. El ajuste mixto debe seguirse revisando.

## Especificación que se conserva

Se retiene como **modelo inicial de referencia** la estructura de tres constructos aprobada: confianza interpersonal (P2025S4–S7), confianza institucional (P5263S1–S15) y conocimiento de mecanismos (P5376S1–S6). La estimación inicial no valida todavía las tres mediciones: el ajuste interpersonal y el RMSEA de conocimiento/institucional requieren atención. Las alternativas quedan etiquetadas como análisis de sensibilidad y no cambian retroactivamente la propuesta aprobada.

## Reestimación exploratoria del SEM

Se estimó la versión alternativa para examinar qué ocurre al introducir las dos dimensiones institucionales en la ecuación del conocimiento. `04_sem_instituciones_dos_dimensiones.R` vuelve a estimar también el SEM aprobado con la misma muestra completa (`N = 35.024`), para hacer la comparación sobre casos idénticos.

| SEM | CFI robusto | TLI robusto | RMSEA robusto | SRMR |
|---|---:|---:|---:|---:|
| Referencia aprobada, 3 constructos | 0,898 | 0,888 | 0,095 | 0,040 |
| Alternativa, instituciones en 2 dimensiones | 0,911 | 0,901 | 0,089 | 0,037 |

El ajuste mejora modestamente, pero la correlación entre las dos dimensiones institucionales es **0,952**, señal de que casi se superponen en esta especificación. En la regresión simultánea, las asociaciones estandarizadas son 0,097 para confianza interpersonal, -0,491 para representación/gobierno/organización electoral y 0,572 para justicia/control/protección/seguridad. Los signos opuestos de los dos factores institucionales no deben interpretarse como relaciones sustantivas independientes: con factores tan correlacionados, los coeficientes condicionales pueden volverse inestables o reflejar supresión.

**Conclusión:** la versión de dos dimensiones está estimada y sirve como sensibilidad exploratoria, pero no se incorpora como modelo principal ni como resultado final del taller. Se conserva la especificación aprobada como referencia. La próxima decisión requiere revisar una partición institucional con mayor diferenciación conceptual y comprobar que tenga validez discriminante; si no se logra, será más prudente mantener confianza institucional como factor único o cambiar el objetivo de medición con el docente. Todas las rutas son asociaciones transversales, no efectos causales.

Las salidas están en `salidas/04_comparacion_sem.csv`, `salidas/04_rutas_sem.csv`, `salidas/04_covarianzas_latentes.csv` y `salidas/04_sintaxis_sem_alternativo.txt`.

## Referencias

- Delhey, J. y Newton, K. (2005). “Predicting Cross-National Levels of Social Trust: Global Pattern or Nordic Exceptionalism?”. *European Sociological Review*, 21(4), 311–327. https://doi.org/10.1093/esr/jci022
- Delli Carpini, M. X. y Keeter, S. (1996). *What Americans Know about Politics and Why It Matters*. Yale University Press. https://www.jstor.org/stable/j.ctt1cc2kv1
- Levi, M. y Stoker, L. (2000). “Political Trust and Trustworthiness”. *Annual Review of Political Science*, 3, 475–507. https://doi.org/10.1146/annurev.polisci.3.1.475
- Pattie, C., Seyd, P. y Whiteley, P. (2003). “Citizenship and Civic Engagement: Attitudes and Behaviour in Britain”. *Political Studies*, 51(3), 443–468. https://doi.org/10.1111/1467-9248.00435
- “Can We Trust Measures of Political Trust? Assessing Measurement Equivalence in Diverse Regime Types”. *Social Indicators Research*. https://doi.org/10.1007/s11205-016-1400-8
