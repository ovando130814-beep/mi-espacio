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

# 4) Borra todas las plantillas [Ejemplo]
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
