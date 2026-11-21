# Sesión 3 · El mundo en una tabla

El modelo multirregional con la tabla FIGARO de Eurostat: huella de carbono de España y aranceles.

## Archivos

### `huella_espana.jl`

Script de Julia que reproduce la cifra oficial de Eurostat de la huella de carbono de la demanda final española en 2022, por país emisor, con la tabla FIGARO completa (50 regiones × 64 ramas = 3.200 sectores), sin agregar.

1. Lee la tabla FIGARO y monta Z (consumos intermedios), la demanda final y la producción x.
2. Calcula A = Z / x, la inversa de Leontief L = (I − A)⁻¹ y la producción q = L f que necesita la demanda final española f.
3. Calcula las emisiones por euro producido de cada país y rama, c = E / x.
4. Suma h = c · q por país emisor y lo compara con la cifra oficial.

La réplica sale a −0,02 % de la cifra oficial (341.541 frente a 341.611 miles de toneladas de CO₂ equivalente).

**Cómo ejecutarlo**

```julia
using Pkg; Pkg.add(["CSV", "DataFrames"])   # solo la primera vez
```

```
julia huella_espana.jl
```

La primera vez descarga los datos en la carpeta `datos/`, junto al script (unos 50 MB). Después tarda unos segundos.

### Próximamente

- Tabla FIGARO agregada a 6 regiones × 64 ramas, para trabajarla en Excel.

## Fuentes

- Eurostat, FIGARO, edición 2026, tablas industria por industria (CIRCABC).
- Eurostat, Greenhouse gas emission footprints (`env_ac_ghgfp`).
