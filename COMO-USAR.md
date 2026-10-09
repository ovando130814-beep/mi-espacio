# Borrar algo (y recuperarlo después)

Al borrar, el elemento **no desaparece para siempre**: pasa a la *papelera*
(`papelera.json`) y puedes devolverlo desde la web o con `Restaurar.ps1`.
Para borrar sin papelera usa `-Definitivo`.

```powershell
cd C:\Users\Administrador\MiEspacio\_scripts
```

```powershell
# 1) Busca y borra (te muestra los que coinciden y te pregunta)
.\Eliminar.ps1 -Buscar "inventario"

# 2) Borra por número (el número es el orden del catálogo)
.\Eliminar.ps1 -Id 3

# 3) Borra el registro Y el archivo de la carpeta (el registro va a la papelera)
.\Eliminar.ps1 -Id 3 -BorrarArchivo

# 4) Borra todas las plantillas [Ejemplo] (hoy ya no queda ninguna:
#    se eliminaron el 2026-10-01; este comando sirve por si vuelves a crearlas)
.\Eliminar.ps1 -TodoLosEjemplos -Silencioso

# 5) Borrar sin papelera (no se puede recuperar)
.\Eliminar.ps1 -Id 3 -Definitivo
```

### Recuperar lo borrado desde la PC

```powershell
.\Restaurar.ps1          # muestra la papelera y elige qué devolver
.\Restaurar.ps1 -Id 2    # restaura el número 2
.\Restaurar.ps1 -Todo    # restaura todo
.\Restaurar.ps1 -Lista   # solo mirar, sin restaurar
```

El visor se regenera solo después de cada borrado y de cada restauración.

---

# Modificar y eliminar desde la propia web

Tu espacio online tiene botones **Modificar** y **Eliminar** en cada tarjeta, y un
**+ Agregar** arriba. Funcionan desde el celular y desde cualquier PC, y los cambios
se guardan directamente en `registro.csv` de GitHub.

### Primera vez en cada equipo: conectar

1. Pulsa **Conectar** (arriba a la derecha)
2. Crea tu token aquí (una sola vez, **No expiration** para que nunca venza):
   <https://github.com/settings/tokens/new>
   · Scopes: solo **`public_repo`** (tu repositorio es público)
3. Pégalo en el recuadro y pulsa **Conectar**

El token se guarda **solo en ese navegador** (no viaja con la página ni la página
pública lo muestra). Si usas otro equipo, lo conectas ahí también. Para quitarlo:
**Conectar → Borrar token de este equipo**.

### Uso normal

| Botón | Qué hace |
|---|---|
| **+ Agregar** | Formulario con fecha, categoría, motivo y evento → sube a GitHub |
| **Modificar** | Abre el elemento con todos sus datos → guarda los cambios |
| **Eliminar** | **Lo mueve a la papelera** (puedes restaurarlo); opcionalmente quita su archivo |
| **🗑 Papelera** | Abre la papelera y el historial de cambios |

Después de cada cambio la web vuelve a leer `registro.csv` (directo de GitHub) y
muestra el resultado al instante.

### Si usas varios equipos o varias pestañas

Cada guardado se aplica **sobre lo que hay en la nube** (la página vuelve a
leer `registro.csv` justo antes de escribir), así que lo que hagas en el
celular y lo que hagas en la PC **no se pisan**: si borras algo en un equipo y
agregas algo en otro, **los dos cambios quedan**. Y si intentas modificar un
elemento que ya no existe en la nube, la web te avisa en lugar de escribir
encima. Si dudas, recarga la página antes de guardar.

### La web siempre te muestra lo mismo en todos lados

- **Abre en el calendario** y **recuerda dónde ibas**: la vista (lista o
  calendario), **el día elegido**, si tenías el área de trabajo abierta y lo
  que estabas buscando. Si lo dejas en un equipo, al volver a entrar ahí
  mismo lo encuentras.
- **Se pone al día sola**: cuando vuelves a la pestaña, la web comprueba si
  hay una versión más nueva publicada y **se recarga sola** (si tienes un
  formulario abierto, solo te avisa para que termines primero).
- **Solo una vez** (y solo si acabas de actualizar desde una copia vieja):
  haz una recarga fuerte para quedarte con la versión nueva:
  - **PC:** `Ctrl` + `F5` (o `Ctrl` + `Shift` + `R`).
  - **Celular:** cierra la pestaña y ábrela de nuevo; si aun así no cambia,
    borra los datos del sitio del navegador (Ajustes → Sitio web → borrar
    datos) o ábrela en ventana de incógnito.

### Subir fotos y archivos desde la web (celular o PC)

Dentro del formulario (**+ Agregar** o **Modificar**) hay dos botones:

| Botón | Qué hace |
|---|---|
| **📎 Adjuntar archivo** | Abre el selector de archivos; puedes elegir **varios a la vez** |
| **📷 Tomar foto** | En el celular **abre la cámara**; en la PC abre el selector de imágenes |

Cosas que conviene saber:

- **Sube a la nube** (a la carpeta de la categoría elegida) y deja la ruta en el
  registro; el archivo no depende de tu equipo.
- Si eliges **varios archivos**, te pregunta: *Subirlos todos* crea **un
  registro por archivo** (título = nombre del archivo, con el mismo motivo,
  evento y fecha del formulario) y muestra **barra de progreso**; *Cancelar*
  sube solo el primero.
- Si el archivo **ya existe** en esa carpeta, pregunta si quieres
  **Reemplazarlo** (no queda duplicado) o subirlo como copia nueva con la fecha
  por delante.
- Límites: **10 archivos** por vez y **20 MB** por archivo. Si uno falla, la
  subida **sigue con los demás** y te avisa al final.

---

# Papelera e historial (deshacer)

Botón **🗑 Papelera** (arriba en PC, abajo en el celular). Tiene dos pestañas:

| Pestaña | Qué hace |
|---|---|
| **🗑 Papelera** | Lista lo que quitaste. **↩ Restaurar** lo devuelve a tu lista · **Eliminar definitivo** lo borra para siempre (con casilla para borrar también su archivo) · **Vaciar papelera** las borra todas |
| **🕘 Historial** | Los últimos cambios de `registro.csv`. **👁 Ver** te dice cuántos elementos había ese día · **↩ Restaurar** devuelve el catálogo completo a esa fecha |

> Al restaurar una versión, lo guardado **después** deja de verse en la lista
> (no se pierde: sigue en el historial de GitHub).

La papelera es un archivo más del repositorio (`papelera.json`), así que
**también se sincroniza**: borras en la PC y lo ves en la papelera del celular.

---

# 🩺 Revisar tu espacio (enlaces y archivos rotos)

Un botón comprueba **todo** de una vez: los datos del catálogo, si los archivos
siguen en su carpeta y si los enlaces de trabajo todavía abren.

### Desde la web

| Dónde | Botón |
|---|---|
| **PC** | Arriba, junto a 🗑 Papelera: **🩺 Revisar** |
| **Celular** | Barra de abajo → **⚙ Filtros** → **🩺 Revisar datos, archivos y enlaces** |

El resultado sale en cuatro bloques:

| Bloque | Qué te dice |
|---|---|
| **Datos del catálogo** | Títulos vacíos, fechas malas, categorías que no existen, registros repetidos |
| **Archivos del espacio** | ✗ los archivos que **ya no están** en su carpeta · ⚠ las rutas que solo existen en tu PC |
| **Enlaces que fallan** | ✗ URLs que **no responden** (se reintenta antes de darlas por muertas) |
| **Enlaces que abren** | ✓ los que sí responden |

Arriba salen tres cuentas: **✗ problemas · ⚠ avisos · ✓ comprobados**.
El botón **📋 Copiar informe** te deja el listado en el portapapeles.

> **Guardar está protegido:** si el catálogo tiene datos rotos, al guardar
> desde la web aparece *"No se puede guardar"* con lo que hay que corregir,
> y **no se publica nada**.

### Desde la PC (antes de subir)

```powershell
cd C:\Users\Administrador\MiEspacio\_scripts
.\Validar-Catalogo.ps1             # solo revisa
.\Validar-Catalogo.ps1 -Corregir   # corrige lo automático (filas vacías, fechas, categorías, rutas)
```

**La subida a la nube ya lo comprueba sola**: si `registro.csv` tiene errores,
`Subir-A-La-Nube.ps1` se cancela **antes** de subir y te dice qué corregir
(nada de errores como el que dejó el catálogo en blanco una vez).

| Comando | Qué hace |
|---------|----------|
| `.\Validar-Catalogo.ps1` | Informe de errores y avisos (0 = se puede subir) |
| `.\Validar-Catalogo.ps1 -Corregir` | Arregla lo automático y vuelve a revisar |
| `.\Subir-A-La-Nube.ps1 -SinValidar` | Sube aunque haya errores (solo si sabes lo que haces) |
| `.\Pruebas-Validador.ps1` | Comprueba que el validador funciona bien |

---

# 📅 Calendario de actividades

El calendario te deja **programar actividades en los días que importan** y ver
**todo** lo de tu espacio (archivos, URLs, manuales, notas, eventos y
actividades) colocado sobre el día de su fecha.

### Cómo se abre

| Dónde | Cómo |
|---|---|
| **El botón 📅 Calendario** | **Siempre visible desde cualquier pantalla**: en PC es el **primer botón de la barra de arriba**; en el celular, el **primero (izquierda) de la barra de abajo**. Un solo clic y estás en el calendario |
| **PC** | También en el desplegable **Vista** → **📅 Calendario** |
| **Celular** | También en el desplegable **Vista** |

### Qué ves (el calendario manda, SIN botones)

- Ocupa **casi toda el área de trabajo**: rejilla grande del mes (**lunes
  primero**), **hoy** marcado y el día elegido resaltado.
- **La rejilla no muestra ningún botón**: la barra de herramientas, los chips
  de categoría, los filtros y la navegación **‹ mes › / Hoy** se esconden para
  que solo veas **el calendario** (queda el título del mes).
  - Para **cambiar de mes**: haz clic en cualquiera de los **días grises** de
    la última o primera fila (son días del mes siguiente/anterior); se abre su
    área y, al pulsar **📅 Calendario**, verás ese mes. Dentro del área también
    te mueves con **‹ ›** día a día y **Hoy**.
- **Cada mes tiene su color**: los días de otros meses (primera y última fila)
  salen con el **fondo apagado** y los números tenues, así se ve enseguida
  dónde empieza y termina el mes.
- **Los días con contenido se pintan de un color**: si ese día hay algo
  guardado, la celda lleva un **recuadro del color de su categoría** (el mismo
  color de sus puntos); los días vacíos quedan solo con el fondo del mes.
  La **leyenda** bajo la rejilla lo explica.
- Cada **punto** es un elemento guardado ese día; el **color** indica su
  categoría (leyenda debajo de la rejilla). Si un día tiene más de 4, sale **+N**.
- Las **estadísticas de arriba se activan con el día elegido**: cuántos
  elementos hay ese día, cuántas actividades, cuánto hay en el mes y lo que viene.
- Debajo, el **día elegido** (fecha y resumen, sin botones): avisa que ese día
  se abre con un clic.
- **🔔 Lo que viene**: los próximos 5 elementos con fecha desde hoy en adelante
  (pulsa uno para saltar a ese día).

### Al hacer clic en un día se abre SU área de trabajo (con todo dentro)

El día que eliges **abre su propia área a pantalla completa** (se cierra la
rejilla) y **ahí se activan todos los botones que necesitas**, incluida la
**barra entera del sistema, que se mete dentro del área**:

| Botón | Qué hace |
|---|---|
| **‹ día anterior** / **día siguiente ›** | Te mueves día a día sin salir del área |
| **Hoy** | Abre el área del día de hoy |
| **📅 Calendario** | **El botón único del sistema** (primer botón de la barra): vuelve a la rejilla del mes **desde cualquier pantalla** |
| **🔍 Buscar** (barra del sistema, dentro del área) | Filtra al instante lo de **ese día** (título, motivo, evento, URL) |
| **Orden** | Ordena los elementos del día (título, fecha, categoría…) |
| **Vista** | Cambia a Lista / Compacta / Línea / Calendario |
| **⚙ Filtros** | Rango de fechas y gráficas, **dentro del área** |
| **➕ Agregar** | Abre el formulario con la **fecha ya puesta** y la categoría **Actividad** |
| **Conectar** / **🗑 Papelera** / **🩺 Revisar** / **📦 Respaldo** | Las 4 opciones del sistema, activas sobre ese día |
| **📎 Adjuntar archivo** | Sube y cataloga con la **fecha de ese día** |
| **📷 Tomar foto** | La foto queda con la **fecha de ese día** |
| **🗂 Ver en la lista** | Filtra la lista a ese día: ahí usas chips, edición, compartir… |

- En el **celular**, los botones grandes de la barra (**📅 Calendario, Filtros,
  Agregar, Vista, Papelera, Conectar**) aparecen en la **barra de abajo** mientras el
  área está abierta.
- Cada elemento del día se muestra con sus botones normales: **Abrir/Compartir,
  ✏️ Modificar y 🗑 Eliminar**, y las **estadísticas de arriba** responden a ese
  mismo día.

> La rejilla no usa búsqueda, orden ni chips; **dentro del área**, el buscador
> y el orden sí trabajan sobre el día elegido. Los elementos sin fecha no
> salen (te avisa el contador de arriba).

### Para programar una actividad

1. Abre el calendario y **haz clic en el día** que te interesa: se abre **su
   área de trabajo**.
2. Pulsa **➕ Agregar** (o 📎 Adjuntar / 📷 Tomar foto, que también quedan con la
   fecha de ese día).
3. Escribe el título (obligatorio), el motivo y el evento, y pulsa **Guardar**.
4. El punto aparece en el día, la actividad entra en **Lo que viene** y también
   se ve en la lista normal con el chip **Actividad**.

> Las actividades son registros normales: viven en `registro.csv`, entran en el
> respaldo 📦, pasan por la papelera y se restauran igual que todo lo demás.
> El botón Guardar sigue las mismas reglas: si el catálogo tiene errores, no se
> publica nada.

---

# 📦 Descargar un respaldo (ZIP)

Un botón te baja **todo tu espacio de una vez** en un solo archivo
`MiEspacio-respaldo-AAAA-MM-DD.zip`:

- `registro.csv` — tu catálogo completo.
- `papelera.json` — lo que borraste (para poder restaurarlo).
- Todas las carpetas `01-…` a `05-…` (archivos, fotos, documentos).
- `LEEME-RESPALDO.txt` — los pasos para restaurarlo, dentro del mismo ZIP.

### Dónde está

| Dónde | Botón |
|---|---|
| **PC** | Arriba, junto a 🩺 Revisar: **📦 Respaldo** |
| **Celular** | Barra de abajo → **⚙ Filtros** → **📦 Descargar todo el espacio en un archivo .zip** |

### Cómo usarlo

1. Pulsa el botón (no hace falta estar conectado: lo baja directo de la nube).
2. Verás la barra **Descargando (3/12): 02-URLs-Trabajo/…** y al final el
   resumen **✓ 12 archivo(s) en el ZIP** con el peso y los que falten.
3. Guarda el `.zip` en tu PC, en un USB o mándatelo por correo.

> **Es tu copia de seguridad**: guárdala de vez en cuando, por si un día se
> borra algo por error o pierdes el acceso a la cuenta. Si algún archivo no se
> puede bajar, el respaldo **igual se descarga** con los demás y te dice cuáles
> faltaron. El límite desde el navegador es de 400 MB por ZIP (si tu espacio
> crece más allá, te lo preparo por partes).

---

# Subir todo a la nube (GitHub)

Tu espacio se sube a GitHub y queda publicado para verlo **desde el celular
o desde cualquier PC**. Todo lo que subas, y todo lo que borres, se refleja allá.

### 1. Una sola vez: crear el token

1. Entra a <https://github.com> → tu foto → **Settings**
2. **Developer settings** → **Personal access tokens** → **Tokens (classic)**
3. **Generate new token (classic)**
4. Marca el permiso **repo** (el que controla tus repositorios; con eso la web
   de GitHub Pages también funciona)
5. Cópialo (empieza con `ghp_...`) y guárdalo en un lugar seguro

### 2. Una sola vez: configurar y publicar

Abre PowerShell y ejecuta:

```powershell
cd C:\Users\Administrador\MiEspacio\_scripts
.\Subir-A-La-Nube.ps1
```

Te va a pedir: tu **usuario de GitHub**, el **nombre del repositorio**
(por ejemplo `mi-espacio`) y el **token** (se escribe oculto y se guarda en
`%USERPROFILE%\.miespacio-github.json`, **fuera** de la carpeta, nunca se sube).

Al terminar te muestra tu dirección web, algo así:

```
https://TUUSUARIO.github.io/mi-espacio/indice.html
```

Guárdala: esa es la que abres desde cualquier lugar.

### 3. Siempre que agregues o borres algo

```powershell
.\Subir-A-La-Nube.ps1
```

- Sube archivos nuevos, el `registro.csv` actualizado y el `indice.html`.
- Si borraste algo con `Eliminar.ps1`, **ese registro y ese archivo desaparecen de la nube**.
- Usa `-BorrarEnLaNube` para que te liste antes qué se va a borrar allá.
- Usa `-Estado` para ver si la web está activa y cuál es la dirección.

### Otras opciones útiles

| Comando | Qué hace |
|---------|----------|
| `.\Subir-A-La-Nube.ps1 -Estado` | Dirección web, si Pages está activa |
| `.\Subir-A-La-Nube.ps1 -Mensaje "subo manuales"` | Sube con mensaje propio |
| `.\Subir-A-La-Nube.ps1 -Reconfigurar` | Cambiar token o repositorio |
| `.\Subir-A-La-Nube.ps1 -SinValidar` | Subir sin pasar la revisión del catálogo |

---

## Nota de privacidad

Elegiste **público con enlace**: cualquiera que tenga la dirección puede ver
lo que subas (archivos, URLs, manuales, imágenes). Si algún día prefieres
que solo tú lo veas, se cambia en un minuto:

```powershell
.\Subir-A-La-Nube.ps1 -Estado        # para verlo
```

y en GitHub: **Settings → Manage access → Private**, o pídemelo y lo dejo
en privado con acceso por usuario y contraseña.

---

## Orden de trabajo habitual

```
Agregar.ps1      →  guardo algo con su fecha, motivo y evento
Eliminar.ps1     →  lo quito (queda en la papelera por si acaso)
Restaurar.ps1    →  recupero algo de la papelera
Validar-Catalogo →  reviso el catálogo (o lo hago solo al subir)
Subir-A-La-Nube  →  valida y lo reflejo en la nube
```

Desde la web no hace falta nada de esto: **+ Agregar**, **Modificar**,
**Eliminar** y **🗑 Papelera** guardan directo en GitHub.
