# Mi Espacio personal

Un solo lugar para tus archivos, URLs de trabajo, manuales, imágenes de sistemas y notas,
**siempre ordenados por fecha y con el motivo (evento) por el que lo guardaste.**

## Cómo abrirlo

Haz doble clic en **`indice.html`** (o en `Abrir-MiEspacio.bat`).

Ahí ves todo en una sola pantalla, con:

- Búsqueda instantánea por título, motivo, evento o URL.
- **Tú escribes qué es**: en el campo **¿Qué es?** escribes `url`, `nota`,
  `actividad`… o **tu propia palabra** (`acta`, `inventario`); lo conocido se
  reconoce solo y lo tuyo queda con tu nombre.
- Filtros por categoría **dentro de ⚙ Filtros** (pulsa la barra de una categoría
  para apagarla o encenderla): Personal, URL-Trabajo, Manual, Imagen-Sistema,
  Nota, Actividad
  y filtro por rango de fechas.
- Orden por fecha (reciente/antiguo), título, categoría o **evento**.
- 4 vistas: **lista**, **compacta**, **línea de tiempo** y **📅 calendario**.
- Agrupación automática por mes y gráficos por categoría y por mes.
- El **motivo** y el **evento** de cada guardado visibles en la tarjeta.
- Modo **claro/oscuro**, compartir y visor de imágenes.
- **🗑 Papelera**: lo que borras se recupera; **🕘 Historial**: devuelve el
  catálogo a una versión anterior.
- **🩺 Revisar**: detecta enlaces rotos, archivos que ya no existen y datos
  malos; guardar y subir quedan **bloqueados** si el catálogo tiene errores.
- **📷 Subir archivos desde la web**: botón para **tomar foto** con la cámara
  del celular, elegir **varios archivos a la vez** (con barra de progreso y un
  registro por archivo) y **reemplazar el repetido** en lugar de duplicarlo.
- **📅 Calendario** (el centro del sistema): ocupa **casi toda el área de
  trabajo** y la rejilla **no muestra ningún botón** (así queda limpio).
  **Cada mes se distingue por su fondo** (los días de otros meses salen
  apagados) y **los días con contenido llevan un recuadro con el color de su
  categoría**. **Un único botón 📅 Calendario, siempre visible desde cualquier
  pantalla**
  (primer botón de la barra en PC; a la izquierda de la barra de abajo en el
  celular) te devuelve al calendario en un clic. **Al hacer clic en un día se
  abre su área de trabajo** y **ahí se activan todos los botones del sistema
  dentro del propio día**: la barra completa (🔍 buscar, orden, vista, ⚙
  filtros, ➕ agregar, conectar, 🗑 papelera, 🩺 revisar, 📦 respaldo) **se
  mete dentro del área**, más las acciones del día (**📎 adjuntar**, **📷
  foto**, **🗂 ver en la lista**), la navegación ‹ día › / **Hoy**, la lista
  de **lo que viene** y la categoría nueva **Actividad**.
- **Siempre al día:** la web **abre en el calendario**, **recuerda tu vista,
  día y búsqueda** en cada equipo y **se actualiza sola** cuando publicas una
  versión nueva.
- **📦 Respaldo en 1 clic**: un botón descarga **todo** tu espacio (catálogo,
  papelera y carpetas) en un solo archivo `.zip`, con un `LEEME` dentro con los
  pasos para restaurarlo si algún día hace falta.
- **🔔 Recordatorios**: banner y notificación **el día antes** (y el mismo día)
  de lo programado en el calendario.
- **📱 App instalable sin internet**: se instala con **icono propio** y
  funciona con la **última copia guardada** aunque no haya señal.
- **📤 Exportar a Excel**: baja en un clic un `.csv` con **exactamente lo que
  estás viendo** (un mes, una materia, un día).
- **🔎 Búsqueda amable**: perdona acentos, mayúsculas y errores de tecleo.
- Diseño **responsivo**: en PC con barra lateral arriba, en el celular con
  barra de botones abajo.

La versión publicada (celular, cualquier PC) es
<https://ovando130814-beep.github.io/mi-espacio/>.

## Estructura

```
MiEspacio\
├── indice.html              ← tu visor (se regenera solo)
├── index.html               ← el mismo visor para la web publicada
├── registro.csv             ← el catálogo: FECHA, CATEGORÍA, TÍTULO, UBICACIÓN, URL, MOTIVO, EVENTO
├── papelera.json            ← lo que borraste (se recupera desde la web o Restaurar.ps1)
├── 01-Archivos-Personales\  ← documentos personales
├── 02-URLs-Trabajo\         ← aquí solo se guarda la URL en el catálogo
├── 03-Manuales\             ← PDFs de manuales
├── 04-Imagenes-Sistemas\    ← capturas de sistemas/aplicaciones del trabajo
├── 05-Notas-y-Eventos\      ← notas y evidencias de por qué guardas algo
└── _scripts\
    ├── Agregar.ps1          ← añade un elemento + regenera el visor
    ├── Eliminar.ps1         ← lo quita y lo deja en la papelera
    ├── Restaurar.ps1        ← devuelve algo de la papelera
    ├── Papelera.ps1         ← ayudante de la papelera (no ejecutar)
    ├── Validar-Catalogo.ps1 ← revisa el catálogo (y lo arregla con -Corregir)
    ├── Pruebas-Validador.ps1 ← comprueba que el validador funciona
    ├── Generar-Indice.ps1   ← solo regenera el visor
    ├── Subir-A-La-Nube.ps1  ← sube todo a GitHub (valida antes de subir)
    └── plantilla.html       ← diseño del visor (no editar)
```

## Cómo agregar algo nuevo

Abre PowerShell y ejecuta:

```powershell
cd C:\Users\Administrador\MiEspacio\_scripts
```

**Una URL de trabajo (con su motivo y evento):**

```powershell
.\Agregar.ps1 -Titulo "Portal de planillas" -Categoria URL-Trabajo `
              -Fecha 2026-09-30 -URL "https://ejemplo.com/planillas" `
              -Motivo "Consulta mensual de planillas" -Evento "Cierre mensual"
```

**Un archivo o manual que quieres copiar a tu espacio:**

```powershell
.\Agregar.ps1 -Titulo "Manual de inventario" -Categoria Manual `
              -Fecha 2026-09-30 -Motivo "Lo necesito para el inventario anual" `
              -Evento "Inventario 2026" -Ruta "C:\Users\Administrador\Downloads\manual.pdf" -Copia
```

**Una imagen de un sistema o aplicación:**

```powershell
.\Agregar.ps1 -Titulo "Error al sincronizar tabletas" -Categoria Imagen-Sistema `
              -Fecha 2026-09-30 -Motivo "Evidencia para escalar al soporte" `
              -Evento "Incidente 4821" -Ruta "C:\capturas\error.png" -Copia
```

**Una nota / evento:**

```powershell
.\Agregar.ps1 -Titulo "Cambio de procedimiento de actas" -Categoria Nota `
              -Fecha 2026-09-30 -Motivo "Para no volver a investigar el proceso" `
              -Evento "Reunión con coordinación"
```

### Parámetros

| Parámetro   | Obligatorio | Descripción |
|-------------|-------------|-------------|
| `-Titulo`   | Sí          | Nombre del elemento |
| `-Categoria`| Sí          | `Personal`, `URL-Trabajo`, `Manual`, `Imagen-Sistema`, `Nota`, `Actividad` |
| `-Fecha`    | No          | `AAAA-MM-DD` (hoy por defecto) |
| `-Motivo`   | No          | **Por qué** lo guardas |
| `-Evento`   | No          | Evento, proyecto o situación asociada |
| `-URL`      | No          | Enlace web |
| `-Ruta`     | No          | Ruta del archivo en tu PC |
| `-Copia`    | No          | Copia el archivo a la carpeta correspondiente |

> También puedes editar `registro.csv` directamente con Excel o el Bloc de notas
> y luego ejecutar `.\_scripts\Generar-Indice.ps1` para actualizar el visor.

## Ya no hay registros `[Ejemplo]`

Las plantillas de prueba se **eliminaron el 1 de octubre de 2026**: tu lista y tu
`registro.csv` solo contienen tus propios elementos. Si algún día vuelves a crear
ejemplos y quieres quitarte todos de una vez:

```powershell
.\_scripts\Eliminar.ps1 -TodoLosEjemplos -Silencioso
```

---

## Verlo desde cualquier lugar (siguiente paso)

Hoy el espacio vive en tu PC. Para abrirlo **desde el celular o desde otra máquina**
hay que subirlo a un servicio en la nube. Ya tienes credenciales, así que cuando digas
"listo" lo publicamos y te quedará algo así:

- `indice.html` visible desde cualquier navegador con tu URL personal.
- Los archivos/manuales accesibles desde esa misma web.
- Para subir cambios: un solo comando desde PowerShell.

Tres opciones rápidas:

| Opción | Qué obtienes | Ideal si… |
|--------|--------------|-----------|
| **GitHub privado + Pages** | Web pública `usuario.github.io/miespacio` con tu catálogo | quieres control total y gratis |
| **Vercel / Netlify** | Web instantánea con dominio bonito | quieres algo más pulido |
| **Google Drive** | Solo carpetas, sin visor | solo necesitas almacenamiento |

**Importante:** dime qué opción eligues y **no pegues el token en el chat**;
te indicaré cómo guardarlo como variable de entorno para que solo se use en tu máquina.
