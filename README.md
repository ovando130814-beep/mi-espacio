# Mi Espacio personal

Un solo lugar para tus archivos, URLs de trabajo, manuales, imágenes de sistemas y notas,
**siempre ordenados por fecha y con el motivo (evento) por el que lo guardaste.**

## Cómo abrirlo

Haz doble clic en **`indice.html`** (o en `Abrir-MiEspacio.bat`).

Ahí ves todo en una sola pantalla, con:

- Búsqueda instantánea por título, motivo, evento o URL.
- Filtros por categoría (Personal, URL-Trabajo, Manual, Imagen-Sistema, Nota)
  y filtro por rango de fechas.
- Orden por fecha (reciente/antiguo), título, categoría o **evento**.
- 3 vistas: **lista**, **compacta** y **línea de tiempo**.
- Agrupación automática por mes y gráficos por categoría y por mes.
- El **motivo** y el **evento** de cada guardado visibles en la tarjeta.
- Modo **claro/oscuro**, compartir y visor de imágenes.
- **🗑 Papelera**: lo que borras se recupera; **🕘 Historial**: devuelve el
  catálogo a una versión anterior.
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
    ├── Generar-Indice.ps1   ← solo regenera el visor
    ├── Subir-A-La-Nube.ps1  ← sube todo a GitHub
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
| `-Categoria`| Sí          | `Personal`, `URL-Trabajo`, `Manual`, `Imagen-Sistema`, `Nota` |
| `-Fecha`    | No          | `AAAA-MM-DD` (hoy por defecto) |
| `-Motivo`   | No          | **Por qué** lo guardas |
| `-Evento`   | No          | Evento, proyecto o situación asociada |
| `-URL`      | No          | Enlace web |
| `-Ruta`     | No          | Ruta del archivo en tu PC |
| `-Copia`    | No          | Copia el archivo a la carpeta correspondiente |

> También puedes editar `registro.csv` directamente con Excel o el Bloc de notas
> y luego ejecutar `.\_scripts\Generar-Indice.ps1` para actualizar el visor.

## Las 3 entradas marcadas `[Ejemplo]`

Son plantillas de referencia. Bórralas cuando quieras: elimina esas filas de `registro.csv`
y ejecuta `.\_scripts\Generar-Indice.ps1`.

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
