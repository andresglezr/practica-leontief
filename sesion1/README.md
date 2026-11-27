# Sesión 1 · El modelo input-output de Leontief

Apuntes y hoja de Excel de la clase de máster sobre el modelo input-output de Leontief.

## Presentación

[`presentacion_sesion1.html`](presentacion_sesion1.html) es la presentación de la clase. GitHub no la muestra: descárgala (botón *Download raw file*) y ábrela en el navegador. Funciona sin conexión y lleva dentro la hoja de Excel interactiva de la práctica.

## Apuntes

[`apuntes_sesion1.pdf`](apuntes_sesion1.pdf) sigue los capítulos 1 y 2 de Miller y Blair (2022), *Input-Output Analysis: Foundations and Extensions*, con la economía de juguete de la práctica: la tabla, los coeficientes, la inversa de Leontief, los multiplicadores, el modelo cerrado, el modelo de precios y ejercicios resueltos.

## La práctica en Excel

`leontief_practica.xlsx` es el ejercicio y [`leontief_practica_resuelta.xlsx`](leontief_practica_resuelta.xlsx) la solución, con todas las fórmulas. `leontief_practica.xlsx` tiene una economía de juguete con tres sectores (Primario, Industria y Servicios). Los datos son inventados con fines docentes.

- En azul, los datos de la tabla (se pueden cambiar).
- En amarillo, las celdas que hay que calcular.

## Qué hay que calcular

| Paso | Qué | Dónde | Pista |
|---|---|---|---|
| 1 | Matriz de coeficientes técnicos, A | B11:D13 | `=B3/B$7` y arrastrar |
| 2 | Matriz identidad, I | F11:H13 | `=M.UNIDAD(3)` |
| 3 | I − A | B16:D18 | restar las dos matrices |
| 4 | Inversa de Leontief, L = (I − A)⁻¹ | F16:H18 | `=MINVERSA(B16:D18)` |
| 5 | Multiplicadores de producción | F19:H19 | `=SUMA(F16:F18)` y arrastrar |
| 6 | Impacto de un shock, Δx = L·Δf | C22:C24 | `=MMULT(F16:H18;B22:B24)` |
| 7 | Empleos por M€ producido | D22:D24 | `=B8/B7`, `=C8/C7`, `=D8/D7` |
| 8 | Empleo del shock | E22:E25 | `=D22*C22`, arrastrar y sumar |
| 9 | Multiplicadores de empleo | F20:H20 | `=SUMAPRODUCTO($D$22:$D$24;F16:F18)` y arrastrar |
| 10 | Comprobación | G22:I24 | `=MMULT(F16:H18;B16:D18)` debe dar la identidad |

Ejemplo de shock: 0, 100 y 0 en B22:B24 (+100 M€ de demanda final en la Industria).

Con ese shock salen unos 1.791 empleos y multiplicadores de empleo de 21,8, 17,9 y 21,5.

## Funciones

Excel en español, con los argumentos separados por punto y coma. Equivalencias en inglés: SUMA = SUM, M.UNIDAD = MUNIT, MINVERSA = MINVERSE, MMULT = MMULT, SUMAPRODUCTO = SUMPRODUCT.
