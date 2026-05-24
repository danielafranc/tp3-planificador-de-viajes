# Firestore Schema — TripPlanner

> **Concepto clave:** Cloud Firestore es **schemaless** (NoSQL). No existe un `CREATE TABLE` ni un archivo `.sql`. Las colecciones se crean automáticamente cuando se escribe el primer documento. La "estructura" la imponen las clases Dart del modelo (`Trip`, `SavingsMovement`, `Destination`) en [lib/domain/](../lib/domain/).
>
> Este documento es la **fuente única de verdad** del modelo de datos: describe qué colecciones espera la app y qué campos debe tener cada documento.

---

## 🌳 Árbol de colecciones

```
Firestore (raíz)
│
├── /destinations                  ← catálogo público (todos los usuarios lo ven)
│   └── {destinationId}
│
└── /users
    └── {uid}                      ← un doc por usuario (la "FK" es el path)
        │
        ├── /trips                 ← TODOS los viajes del usuario (los 3 estados juntos)
        │   └── {tripId}
        │
        └── /savings_movements     ← historial de ahorros del usuario
            └── {movementId}
```

### ¿Por qué subcolecciones bajo `/users/{uid}/`?
Porque Firestore no tiene foreign keys. La relación "este viaje pertenece a este usuario" se modela usando el **path del documento**: cada viaje vive físicamente debajo del usuario que lo creó. Ventajas:
- Las security rules son simples (`allow read: if request.auth.uid == userId`).
- Imposible leer viajes de otro usuario por error.
- Queries automáticamente filtradas al usuario logueado.

### ¿Por qué `/destinations` está en la raíz y no bajo el usuario?
Porque el catálogo es **global**: todos los usuarios ven los mismos destinos. No depende del usuario logueado.

---

## 📁 `/destinations/{destinationId}`

Catálogo público de destinos turísticos argentinos. Lo administra el equipo (no la app).

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `name` | string | sí | Nombre del destino (ej. `"Bariloche"`). |
| `province` | string | sí | Provincia argentina (ej. `"Río Negro"`). |
| `description` | string | sí | Texto descriptivo corto. |
| `imageUrl` | string | sí | URL a foto representativa (HTTPS). |
| `priceFromUsd` | number | sí | Precio "desde" en USD para mostrar en home. |
| `isFeatured` | boolean | sí | Si aparece en el carrusel destacado de Inicio. |
| `isTouristic` | boolean | sí | Clave para **RN-06**: si es turístico, la fecha meta es 3 meses antes; si no, 1 mes. |
| `availableTransports` | array&lt;string&gt; | sí | Medios de transporte disponibles. Valores: `"avion"`, `"micro"`, `"auto"`, `"tren"`. |

**Modelo Dart:** [`Destination`](../lib/domain/destination.dart)

---

## 📁 `/users/{uid}/trips/{tripId}`

Viajes del usuario. **Una sola colección guarda los tres estados** (presupuesto, activo, completado), distinguidos por el campo `state`. Esto evita migrar documentos entre colecciones cuando cambia el estado.

### Campos de identidad y denormalización

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `destinationId` | string | sí | ID del destino en `/destinations`. Es una referencia, no FK formal. |
| `destinationName` | string | sí | **Denormalizado** del catálogo. Permite mostrar el nombre sin un JOIN extra. |
| `destinationImageUrl` | string | sí | **Denormalizado**. Idem. |
| `isTouristic` | boolean | sí | **Denormalizado**. Se usa al crear para calcular `savingsTargetDate` (RN-06). |

> **¿Por qué denormalizamos?** Firestore no tiene JOINs. Si quisiéramos mostrar el nombre del destino tendríamos que hacer una lectura extra por cada viaje. La copia es un trade-off clásico de NoSQL: una escritura más al crear, a cambio de muchas menos lecturas después. Si el catálogo cambia el nombre del destino, el viaje queda con el snapshot anterior — aceptable para nuestro caso.

### Estado del ciclo de vida

| Campo | Tipo | Requerido | Descripción | PRD |
|---|---|---|---|---|
| `state` | string | sí | `"presupuesto"` \| `"activo"` \| `"completado"`. | Sección 9 |

**Transiciones permitidas:**
- `presupuesto` → `activo` (botón "Confirmar como mi viaje", **CU-05**)
- `activo` → `presupuesto` (cuando se confirma otro como activo — **RN-01**: solo uno activo a la vez)
- `activo` → `completado` (botón "Archivar viaje", **CU-07**)
- `completado` → no tiene salida (read-only)

### Configuración del viaje (lo elige el usuario en CU-03)

| Campo | Tipo | Requerido | Descripción | PRD |
|---|---|---|---|---|
| `durationDays` | number (int) | sí | Cantidad de días del viaje. | CU-03 |
| `tripDate` | timestamp \| null | no | Fecha de salida. Null si activó "mes más barato". | CU-03 |
| `cheapestMonth` | boolean | sí | Si el usuario activó la opción **RN-05**. | RN-05 |
| `people` | number (int) | sí | Cantidad de personas que viajan. | CU-03 |
| `hotelStars` | number (int) | sí | Categoría de hotel: `1` a `5`. | CU-03 |
| `maxDistanceKm` | number (int) | sí | Distancia máxima al centro: `1` a `5`. | CU-03 |
| `transport` | string | sí | `"avion"` \| `"micro"` \| `"auto"` \| `"tren"`. | RN-10 |

### Costos y cotización

| Campo | Tipo | Requerido | Descripción | PRD |
|---|---|---|---|---|
| `transportCostUsd` | number | sí | Costo total de transporte (ida y vuelta × personas). | CU-03 |
| `hotelCostUsd` | number | sí | Costo total de hotel (precio por noche × noches). | CU-03 |
| `totalUsd` | number | sí | Suma + margen de seguridad (**RN-04**). Es lo que ve el usuario. | RN-04 |
| `totalArsCache` | number | sí | Equivalente en ARS, calculado al MEP. Cache para evitar recalcular. | RN-07 |
| `mepRateUsed` | number | sí | Valor del MEP usado en el cálculo (USD→ARS). | RN-07 |
| `pricesUpdatedAt` | timestamp | sí | Última vez que se actualizaron los precios. | RN-09 |

### Plan de ahorro y timestamps

| Campo | Tipo | Requerido | Descripción | PRD |
|---|---|---|---|---|
| `savingsTargetDate` | timestamp | sí | Fecha objetivo de ahorro. Calculada: `tripDate - 3 meses` si turístico, `tripDate - 1 mes` si no. | RN-06 |
| `createdAt` | timestamp | sí | Cuándo se creó el presupuesto. | — |
| `confirmedAt` | timestamp \| null | no | Cuándo se confirmó como viaje activo. Null si todavía es presupuesto. | CU-05 |
| `archivedAt` | timestamp \| null | no | Cuándo se archivó como completado. Null si no está archivado. | CU-07 |

**Modelo Dart:** [`Trip`](../lib/domain/trip.dart)

---

## 📁 `/users/{uid}/savings_movements/{movementId}`

Historial de movimientos de ahorro del usuario. El total es **global** (RN-02), no está asignado a un viaje específico — se compara contra el viaje activo.

| Campo | Tipo | Requerido | Descripción | PRD |
|---|---|---|---|---|
| `amountUsd` | number | sí | Monto del movimiento normalizado a USD. | CU-09 |
| `originalAmount` | number | sí | Monto original ingresado por el usuario. | CU-09 |
| `originalCurrency` | string | sí | `"USD"` \| `"ARS"` — la moneda en que el usuario lo ingresó. | CU-09 |
| `mepRateUsed` | number \| null | no | Valor del MEP usado para convertir ARS→USD. Null si el ingreso fue en USD. | RN-07 |
| `date` | timestamp | sí | Fecha del movimiento. Por **RN-08**, se setea automáticamente al momento del registro. | RN-08 |

**Modelo Dart:** [`SavingsMovement`](../lib/domain/savings_movement.dart)

---

## 🧩 Tipos de Firestore que usamos

| Tipo Firestore | Tipo Dart | Cuándo usar |
|---|---|---|
| `string` | `String` | Texto, IDs, enums representados como string. |
| `number` | `int` o `double` | Costos, contadores. Firestore no distingue int de double — el conversor Dart lo decide. |
| `boolean` | `bool` | Flags. |
| `timestamp` | `DateTime` | Fechas. **Siempre usar `Timestamp.fromDate(dt)` al escribir** y `(doc['campo'] as Timestamp).toDate()` al leer. |
| `array` | `List<T>` | Listas pequeñas y fijas (ej. `availableTransports`). |
| `map` | `Map<String, dynamic>` | No lo usamos en este proyecto. |
| `null` | `null` | Para campos opcionales como `tripDate`, `confirmedAt`, `archivedAt`. |

---

## 🔒 Reglas de seguridad recomendadas

Estas reglas viven en Firebase Console → Firestore → Rules. **No están en este código**, pero son críticas. La idea:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Catálogo: lectura pública, escritura solo admins
    match /destinations/{id} {
      allow read: if true;
      allow write: if false;  // (manejado fuera de la app)
    }

    // Datos privados del usuario
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                       && request.auth.uid == userId;
    }
  }
}
```

**Por qué:** garantiza que un usuario solo lee/escribe sus propios viajes y movimientos. El catálogo de destinos es público porque es contenido del producto, no datos personales.

---

## ⚙️ Cómo cargar datos por primera vez

Tres formas, usadas en el proyecto:

| Forma | Archivo | Cuándo usar |
|---|---|---|
| **Firestore Console** (manual) | — | Pocos documentos, demo en vivo frente a profe. |
| **Script Dart** (`lib/scripts/seed_firestore.dart`) | [seed_firestore.dart](../lib/scripts/seed_firestore.dart) | Cargas repetibles. Útil para testing. |
| **Pantalla `/dev`** | [dev_seed_screen.dart](../lib/presentation/screens/dev_seed_screen.dart) | Atajo visual para dispararlas desde la app sin tipear. |
