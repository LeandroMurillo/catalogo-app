# Flujo de trabajo para documentar los TPs

Este directorio contiene la documentación técnica y las evidencias generadas durante la resolución de los trabajos prácticos.
                              
La idea es separar dos actividades:

1. **Resolver el TP sin interrumpir el trabajo para redactar el informe.**
2. **Procesar después las evidencias y presentarlas de forma ordenada en Typst.**

El registro principal de cada sesión se realiza con `Start-Transcript` de PowerShell.

---

## Estructura sugerida

```text
docs/
├── README.md
├── tp1-c.typ
├── tp2-c.typ
├── tp3-c.typ
└── evidence/
    └── tp3/
        ├── session.txt
        ├── devtools-api-productos.png
        └── producto-persistente.png
```

Los nombres pueden adaptarse a cada TP.

---

## 1. Comenzar una sesión de trabajo

### Preparar el entorno del TP3

Antes de iniciar el registro, ejecutar desde la raíz del repositorio:

```powershell
.\docs\scripts\prepare-tp3.ps1
```

El script construye `catalogo-api:v1`, `catalogo-api:v2` y
`catalogo-frontend:v1`, descarga `mongo:7` y verifica `APP_VERSION` en ambas
imágenes de la API. Requiere Docker Desktop iniciado con contenedores Linux y
acceso a Internet para descargar imágenes y dependencias. Funciona también
si se invoca por su ruta desde otro directorio.

Para repetir el práctico desde cero cuando ya existan recursos:

```powershell
.\docs\scripts\prepare-tp3.ps1 -Reset
```

**`-Reset` elimina los contenedores `catalogo-frontend`, `catalogo-api` y
`catalogo-db`, sus volúmenes anónimos, la red `catalogo-net` y el volumen
`catalogo-db-data`, incluidos todos los productos guardados.** Sin esa opción,
el script se detiene si encuentra recursos del TP3. También se detiene si
otros contenedores usan la red o el volumen. Construye y valida las imágenes
antes de eliminar recursos; cualquier error de Docker interrumpe la ejecución.

Conserva el código, los informes, las evidencias y los recursos ajenos al TP3.
Deja sin crear la red, el volumen y los contenedores para que puedas ejecutar
las consignas desde el punto 1. No modifica `main.typ` ni resuelve el práctico.

### Iniciar el registro

Desde la raíz del repositorio:

```powershell
New-Item -ItemType Directory -Force .\docs\evidence\tp3 | Out-Null

Start-Transcript `
  -Path .\docs\evidence\tp3\session.txt `
  -Append
```

A partir de este momento se puede trabajar normalmente en PowerShell.

El transcript sirve como **registro maestro de la sesión**: conserva los comandos ejecutados y gran parte de la salida mostrada en terminal.

---

## 2. Marcar las consignas mientras se trabaja

Antes de comenzar cada punto importante del TP, agregar un marcador:

```powershell
Write-Output "=== TP3.1 - RED Y VOLUMEN ==="
```

Luego ejecutar los comandos correspondientes:

```powershell
docker network create catalogo-net
docker volume create catalogo-db-data
docker network ls
docker volume ls
```

Al comenzar la siguiente sección:

```powershell
Write-Output "=== TP3.2 - BASE DE DATOS ==="
```

Continuar de la misma forma durante todo el TP.

Esto permite localizar posteriormente cada bloque dentro de `session.txt` y facilita su extracción automática.

---

## 3. Finalizar la sesión

Al terminar el trabajo:

```powershell
Stop-Transcript
```

El archivo generado quedará, por ejemplo, en:

```text
docs/evidence/tp3/session.txt
```

Si se utiliza `-Append`, varias sesiones pueden acumularse en el mismo archivo.

---

## 4. Evidencias gráficas

`Start-Transcript` solamente registra la terminal.

Las verificaciones realizadas mediante interfaces gráficas deben guardarse por separado, por ejemplo:

```text
docs/evidence/tp3/
├── session.txt
├── devtools-api-productos.png
├── frontend-funcionando.png
└── producto-persistente.png
```

Conviene realizar capturas únicamente cuando aportan información que no queda bien demostrada mediante texto.

Ejemplos:

- DevTools del navegador.
- Aplicación funcionando.
- Comportamiento del frontend.
- Verificación visual de persistencia.
- Estados relevantes de una interfaz gráfica.

No es necesario capturar cada comando de Docker si ya quedó registrado en el transcript.

---

## 5. Qué documentar en el informe

Para cada sección del TP, el informe debería distinguir:

```text
Objetivo
   ↓
Comandos ejecutados
   ↓
Resultado / evidencia
   ↓
Interpretación técnica
```

Ejemplo:

```typst
=== Creación de la red y el volumen

Se creó una red bridge definida por el usuario:

```bash
docker network create catalogo-net
```

También se creó el volumen nombrado utilizado por MongoDB:

```bash
docker volume create catalogo-db-data
```

La existencia de ambos recursos se verificó mediante:

```bash
docker network ls
docker volume ls
```
```

La salida completa no tiene que copiarse manualmente durante la ejecución. Puede recuperarse posteriormente desde `session.txt`.

---

## 6. Incluir evidencias textuales en Typst

Si posteriormente se extrae una sección del transcript a un archivo independiente:

```text
docs/evidence/tp3/01-red-volumen.txt
```

Typst puede incluirla directamente:

```typst
#raw(
  read("evidence/tp3/01-red-volumen.txt"),
  lang: "text",
)
```

También puede definirse una función reutilizable:

```typst
#let evidencia(nombre) = block(
  width: 100%,
  inset: 8pt,
  radius: 4pt,
  fill: luma(245),
)[
  #raw(
    read("evidence/tp3/" + nombre + ".txt"),
    lang: "text",
  )
]
```

Uso:

```typst
#evidencia("01-red-volumen")
```

De esta forma, el formato de todas las evidencias queda centralizado.

---

## 7. Flujo recomendado

```text
Leer consigna
      ↓
Marcar sección con Write-Output
      ↓
Ejecutar comandos normalmente
      ↓
Start-Transcript registra la sesión
      ↓
Guardar capturas gráficas solo cuando sean necesarias
      ↓
Finalizar con Stop-Transcript
      ↓
Extraer las evidencias relevantes
      ↓
Typst genera el informe
```

Este flujo evita interrumpir la resolución del TP para redactar documentación en tiempo real.

---

## 8. Buenas prácticas

- Mantener una carpeta de evidencia independiente para cada TP.
- Utilizar marcadores claros y consistentes.
- No editar manualmente el transcript original: conservarlo como registro de la sesión.
- Si hace falta una evidencia limpia, generar un archivo derivado a partir del transcript.
- No llenar el informe de capturas de terminal innecesarias.
- Preferir comandos y salida textual cuando sean suficientes.
- Utilizar capturas para verificaciones visuales o interfaces gráficas.
- Revisar el transcript antes de versionarlo.

### Información sensible

Un transcript puede contener:

- contraseñas escritas como argumentos;
- tokens;
- rutas locales;
- nombres de usuario;
- variables de entorno;
- otros datos sensibles.

Antes de hacer `git add`, revisar siempre:

```powershell
Get-Content .\docs\evidence\tp3\session.txt
```

Si el TP utiliza credenciales de laboratorio conocidas, pueden formar parte de la evidencia académica, pero este procedimiento no debe trasladarse sin revisión a entornos reales o productivos.

---

## Comandos de referencia rápida

### Iniciar registro

```powershell
Start-Transcript -Path .\docs\evidence\tp3\session.txt -Append
```

### Marcar una sección

```powershell
Write-Output "=== TP3.X - NOMBRE DE LA SECCION ==="
```

### Finalizar registro

```powershell
Stop-Transcript
```

### Revisar el transcript

```powershell
Get-Content .\docs\evidence\tp3\session.txt
```

### Abrirlo en VS Code

```powershell
code .\docs\evidence\tp3\session.txt
```

---

## Objetivo del método

El transcript es la **fuente de evidencia de ejecución**.

Los archivos `.typ` son la **fuente del informe**.

Las imágenes son **evidencias complementarias**.

```text
PowerShell / Docker
        ↓
    session.txt
        ↓
 selección y extracción
        ↓
 Typst + imágenes
        ↓
      PDF
```

La prioridad durante la resolución del TP es ejecutar, observar y comprender. La presentación final de esas evidencias se realiza después.
