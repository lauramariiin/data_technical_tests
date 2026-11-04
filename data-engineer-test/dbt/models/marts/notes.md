# Phase 2 — dbt transformations --> Matching de puntos de venta

`dim_pos_unified` unifica los puntos de venta de OMNI y GI.

## Reglas de matching (`match_rule`)
1. **Nombre normalizado + código postal** (`NAME_AND_ZIP`).
2. **Nombre normalizado + ciudad/localidad** (`NAME_AND_CITY`), solo para registros no emparejados por código postal.

El nombre se normaliza eliminando espacios duplicados y convirtiéndolo a mayúsculas.
El código postal se trata como texto para conservar ceros iniciales.

## Estados de correspondencia (`match_status`)
- `MATCHED` -> El punto existe en OMNI y GI
- `OMNI_ONLY` -> El punto solo existe en OMNI
- `GI_ONLY` -> El punto solo existe en GI

## Origen (`source_system`)
- `OMNI` -> Solo procede de OMNI 
- `GI` -> Solo procede de GI
- `OMNI+GI` -> Proceden de ambas fuentes y ha habido match


### Falsos positivos
Dos puntos de venta distintos pueden acabar haciendo match si comparten
nombre y código postal, o nombre y ciudad. Por ejemplo, dos franquicias
con el mismo nombre en la misma localidad podrían confundirse y juntarse
por error.

### Falsos negativos
El mismo punto de venta puede no hacer match si el nombre cambia entre
sistemas, contiene errores ortográficos, sufijos, abreviaturas o diferencias 
de formato. También puede ocurrir si el código postal o la ciudad difieren entre fuentes.

## Mejoras futuras
- Crear un diccionario maestro de puntos de venta: mantener una tabla centralizada con todos los puntos de venta y sus identificadores, para evitar duplicados y facilitar su identificación entre diferentes fuentes.
- Aplicar coincidencias aproximadas (fuzzy matching): permitir encontrar puntos de venta aunque sus nombres no sean exactamente iguales.
