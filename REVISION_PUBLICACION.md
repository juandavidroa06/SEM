# Revisión para publicación — 9 de noviembre de 2026

## Alcance

Se revisaron el artículo, los scripts vigentes del Taller 2, el Excel de resultados,
las fuentes de LaTeX y el paquete de entrega. Los materiales del Taller 1 se conservan
como antecedentes. No se realizan commits ni push en esta revisión.

## Correcciones y ampliaciones

1. **Factor de expansión y diseño.** Se mantiene FEX_P, enlazado desde la tabla de
   viviendas con clave DIRECTORIO única. Las 46.392 personas tienen peso positivo.
   Se distingue la ponderación de la corrección completa de varianzas por diseño.
   La falta de estratos y UPM se informa como limitación de los archivos utilizados,
   sin atribuir al DANE una negativa institucional que no se documenta aquí.
2. **Diferencias por sexo.** Resumen, abstract, discusión y conclusiones distinguen
   el contraste conjunto (p=0,017) de las dos pruebas por ruta. La institucional
   tiene p=0,034 sin ajuste y p=0,067 con Holm/Bonferroni; no se presenta como una
   diferencia específica concluyente. Las pruebas comparan coeficientes no
   estandarizados; los estandarizados describen magnitudes.
3. **Cargas e incertidumbre.** El apéndice y la hoja de medición usan
   standardizedSolution(): coeficiente, EE, z, p e intervalo pertenecen a la misma
   escala estandarizada, incluidos los indicadores marcadores.
4. **No aplicabilidad territorial.** Se incorpora una estimación con 23 indicadores
   y las mismas 46.392 personas, retirando Asamblea y Gobernación para todas las
   regiones. Las rutas permanecen próximas al modelo principal y el ajuste robusto
   sigue siendo débil. Se informa como sensibilidad, no como prueba anidada.
5. **Medición.** Se evalúa por separado la dependencia residual vecinos-amistades
   con justificación de contenido y dos particiones internas de 23.196 personas.
   La selección previa de la pareja con información de toda la base se reconoce:
   la partición posterior no constituye una validación independiente. El modelo
   original se conserva como referencia exploratoria.
6. **Kish.** La inflación adicional de errores se etiqueta como escenario hipotético.
   Puede duplicar variabilidad ya incorporada por el modelo ponderado y no estima
   el efecto de diseño del SEM ni garantiza resultados conservadores.
7. **Reproducción.** Un único ejecutor regenera diagnósticos, matrices, residuos,
   tamaños de efecto, sensibilidades, invariancia, tablas y diagrama. El exportador
   falla ante insumos ausentes. La entrada histórica 08_fase2_sem.R delega al flujo
   vigente para evitar sobrescrituras con una versión anterior.
8. **Manuscrito.** Se corrigen fecha de recolección (octubre-diciembre, según el
   boletín), redondeos, separadores decimales, identificación de tablas y sintaxis.
   Se armoniza la redacción con el ajuste robusto débil, el R² bajo y el alcance
   asociativo de los datos transversales. Los dos resúmenes cumplen 150–250 palabras.
9. **Entrega.** El ZIP se genera con una lista de productos agregados y un manifiesto
   SHA-256; excluye microdatos, bases individuales y diagnósticos por persona.

## Comprobaciones

- Se reestimaron AFC, SEM principal, rival, alternativa institucional, sensibilidades
  y modelos multigrupo desde los ZIP originales. Las estimaciones principales
  reproducen β=0,094 y β=0,065, con R²=0,016.
- Se ejecutó el exportador en una carpeta separada con los insumos agregados;
  regeneró las tablas y la figura sin depender de tablas LaTeX anteriores.
- El cierre estable del ejecutor y la exportación final terminaron con código 0.
- La compilación completa pdflatex/BibTeX terminó correctamente, sin referencias
  sin resolver ni desbordamientos. Se inspeccionaron visualmente las páginas.
  El PDF adaptado a la plantilla tiene 23 páginas con referencias y apéndices;
  las referencias empiezan en la página 17, dentro del límite del taller para el cuerpo.
- El Excel contiene nueve hojas, conserva los valores analíticos tras el formato
  y no contiene celdas con errores de Excel. Se verificaron las cargas e intervalos,
  Holm, conteos regionales, pesos, sensibilidades y tamaños de efecto mediante
  `verificar_resultados.py`.
- El empaquetador comprueba integridad ZIP y genera un manifiesto SHA-256 de los
  archivos públicos. Los microdatos y resultados individuales quedan fuera.

Las limitaciones metodológicas señaladas permanecen; las mejoras no convierten
los resultados en causales ni en inferencia completamente ajustada al diseño.

## Adaptación a la plantilla oficial USTA

Se incorporó la plantilla suministrada por el docente y se conserva una copia
sin modificaciones en `documentacion/Plantilla_Articulo_USTA.tex`. El artículo
adopta 11 puntos, papel carta, márgenes de 2,5 cm, interlineado de uno y medio,
`authblk`, fuentes de tablas y figura, enlaces azules y la estructura solicitada.
Los resúmenes no contienen fórmulas y mantienen entre 150 y 250 palabras. Las
conclusiones se sintetizaron sin repetir cifras y los apéndices se agruparon en
Material complementario. Se eliminaron los ejemplos y textos de guía de la
versión de entrega. Las estimaciones y el libro analítico se conservaron.

La compilación usa los paquetes oficiales requeridos por la plantilla; los que
faltaban en este equipo se descargaron a una carpeta temporal local del proyecto.
No se modificó la instalación global de LaTeX. Se verificaron compilación completa,
referencias, presentación visual, coherencia analítica e integridad del paquete.
