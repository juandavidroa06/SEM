# Propuesta provisional de constructos e indicadores

**Estado:** aprobada por el docente (confirmación del estudiante, 20 de octubre de 2026).

## Base y unidad de análisis

Encuesta de Cultura Política (ECP) 2023 del DANE. La unidad será la persona adulta entrevistada. Los módulos de Democracia, Participación y Capital Social comparten identificadores individuales; el diagnóstico local encontró 46.392 filas en cada uno, sin duplicados ni IDs incompletos. La fuente oficial describe como objetivos temáticos la participación, la democracia y el capital social.

## Pregunta de investigación provisional

¿Cómo se relacionan la confianza interpersonal y la confianza institucional con el conocimiento de los mecanismos de participación ciudadana entre las personas encuestadas en Colombia en 2023?

## Constructos e indicadores candidatos

| Constructo | Rol | Indicadores candidatos | Escala |
|---|---|---|---|
| Confianza interpersonal/generalizada | Exógeno | P2025S4 personas desconocidas; P2025S5 vecinos(as); P2025S6 amistades; P2025S7 personas de otra nacionalidad | Ordinal 1–5; 99 = no sabe/no informa |
| Confianza institucional | Exógeno | P5263S1–P5263S15: Procuraduría, Alcaldía, Fuerzas Militares, Congreso, jueces y magistrados, Asamblea departamental, Contraloría, concejos municipales/distritales, Policía, partidos/movimientos políticos, Defensoría, Gobernación, Fiscalía, Registraduría y Presidencia | Ordinal 1–5; 99 = no sabe/no informa; P5263S6 y P5263S12 tienen además faltantes estructurales |
| Conocimiento de mecanismos de participación | Endógeno | P5376S1 revocatoria del mandato; S2 iniciativa popular legislativa/normativa; S3 referendo; S4 plebiscito; S5 consulta popular; S6 cabildo abierto | Binaria: 1 = sí conoce, 2 = no conoce; se recodifica a 1/0 |

## Relaciones hipotéticas

- H1: una mayor confianza interpersonal se asocia positivamente con el conocimiento de mecanismos de participación.
- H2: una mayor confianza institucional se asocia con el conocimiento de mecanismos de participación; la dirección se mantendrá como pregunta empírica hasta precisar el marco teórico.
- H3: la confianza interpersonal y la institucional podrían covariar.

La encuesta es transversal, por lo que los resultados se interpretarán como asociaciones y no como efectos causales.

## Especificación conceptual en `lavaan`

En la notación del cuaderno de SEM (`=~` para medición y `~` para regresiones), el borrador sería:

```r
modelo <- '
  ConfianzaInterpersonal =~ P2025S4 + P2025S5 + P2025S6 + P2025S7
  ConfianzaInstitucional =~ P5263S1 + P5263S2 + P5263S3 + P5263S4 + P5263S5 +
                            P5263S6 + P5263S7 + P5263S8 + P5263S9 + P5263S10 +
                            P5263S11 + P5263S12 + P5263S13 + P5263S14 + P5263S15
  ConocimientoMecanismos =~ P5376S1 + P5376S2 + P5376S3 + P5376S4 + P5376S5 + P5376S6
  ConocimientoMecanismos ~ ConfianzaInterpersonal + ConfianzaInstitucional
  ConfianzaInterpersonal ~~ ConfianzaInstitucional
'
```

Siguiendo el cuaderno, primero se validarían los modelos de medida (CFA) y después se añadirían las rutas estructurales. Como los indicadores son ordinales/binarios, en `lavaan` se declararían como `ordered`; la guía oficial indica que esa opción activa WLSMV. La dimensionalidad de confianza institucional debe revisarse antes de mantenerla como un único factor.

## Diagnóstico de frecuencias ejecutado

El script `01_perfil_indicadores.R` produjo el perfil inicial: 35.024 de 46.392 personas tienen respuestas completas en todos los indicadores listados. Los seis ítems de conocimiento no presentan faltantes; entre 10.659 y 19.749 personas reportan conocer cada mecanismo. En confianza interpersonal, el faltante por ítem está entre 0,92% y 2,38%. En confianza institucional, después de convertir 99 a perdido y considerar los faltantes existentes, varía entre 5,42% y 19,94%; Asamblea departamental y Gobernación concentran más faltantes por su aplicabilidad geográfica y por “no sabe/no informa”. Estos resultados justifican revisar el manejo de datos faltantes antes de estimar.

## Precauciones y siguiente decisión

La confianza institucional incluye instituciones diversas; antes de fijar una sola dimensión se revisará su estructura (AFE/CFA) y los ítems con 99/faltantes estructurales. En el conocimiento de mecanismos, los seis indicadores son binarios y no necesariamente intercambiables; para SEM se deberá justificar el tratamiento categórico y revisar dimensionalidad, umbrales y ajuste. Si el docente exige factores estrictamente reflectivos, se consultará si acepta esta operacionalización o si conviene cambiar el constructo endógeno.

La participación efectiva (P2003) queda como alternativa, pues varias categorías son muy raras (en algunos grupos, menos del 1% reporta contacto durante el último año), lo que puede dificultar una medición latente reflectiva estable.

## Próximo paso

El docente aprobó esta propuesta. El perfil inicial está en `salidas/01_perfil_indicadores.csv`. El siguiente paso es estimar los CFA por constructo y luego el SEM integrado con el flujo de dos etapas aprendido en clase. El script reproducible está en `02_estimacion_sem.R`; requiere `lavaan`.

## Resultado de la primera estimación (diagnóstico, no modelo final)

Tras corregir la lectura de nombres acentuados en los ZIP y ejecutar `02_estimacion_sem.R` con lavaan 0.7-3, el tamaño analítico fue 35.024. Los índices robustos WLSMV de los CFA fueron:

| Medición unidimensional | CFI robusto | TLI robusto | RMSEA robusto | SRMR |
|---|---:|---:|---:|---:|
| Confianza interpersonal (4 ítems) | 0,748 | 0,244 | 0,395 | 0,109 |
| Confianza institucional (15 ítems) | 0,909 | 0,894 | 0,127 | 0,041 |
| Conocimiento de mecanismos (6 ítems) | 0,940 | 0,900 | 0,212 | 0,027 |

Estos resultados robustos sugieren que las tres baterías no deben darse por validadas como factores unidimensionales. En confianza interpersonal, las asociaciones residuales más altas unen confianza en vecinos con amistades y confianza en desconocidos con personas de otra nacionalidad, lo que puede indicar una separación entre vínculos cercanos y confianza generalizada. En conocimiento de mecanismos también aparece dependencia residual entre algunos mecanismos. El SEM integrado produjo CFI robusto = 0,898, TLI robusto = 0,888 y RMSEA robusto = 0,095, por lo que sus coeficientes estructurales no se interpretan aún como resultados finales.

Las salidas reproducibles de este primer intento están en `salidas/02_ajuste_cfa.csv`, `salidas/02_cargas_cfa.csv`, `salidas/02_indices_modificacion_cfa.csv`, `salidas/02_ajuste_sem.csv` y `salidas/02_parametros_sem.csv`. El siguiente trabajo es revisar subdimensiones y especificaciones con sustento teórico, antes de volver a estimar o cambiar indicadores aprobados.
