# Borrar algo

Puedes borrar **solo el registro** (el elemento desaparece del visor) o
**el registro + el archivo físico**.

```powershell
cd C:\Users\Administrador\MiEspacio\_scripts
```

```powershell
# 1) Busca y borra (te muestra los que coinciden y te pregunta)
.\Eliminar.ps1 -Buscar "inventario"

# 2) Borra por número (el número es el orden del catálogo)
.\Eliminar.ps1 -Id 3

# 3) Borra el registro Y el archivo de la carpeta
.\Eliminar.ps1 -Id 3 -BorrarArchivo

# 4) Borra todas las plantillas [Ejemplo]
.\Eliminar.ps1 -TodoLosEjemplos -Silencioso
```

El visor se regenera solo después de cada borrado.

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
| **Eliminar** | Pide confirmación y, si quieres, borra también el archivo físico |

Después de cada cambio la web vuelve a leer `registro.csv` y muestra el resultado.
GitHub tarda ~1 minuto en republicar `index.html`.

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
Eliminar.ps1     →  borro lo que ya no necesito
Subir-A-La-Nube  →  lo reflejo en la nube
```
