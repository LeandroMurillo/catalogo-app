# Flujo de trabajo para documentar los TPs

Este directorio contiene los informes de los trabajos prácticos. Los comandos
ejecutados, sus salidas y las explicaciones se escriben directamente en el archivo
Typst correspondiente. El TP3 se documenta en `docs/tp3-c.typ`.

## Preparar el entorno del TP3

Desde la raíz del repositorio, en PowerShell:

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

Conserva el código, los informes y los recursos ajenos al TP3. Deja sin crear
la red, el volumen y los contenedores para ejecutar las consignas desde el
punto 1. No modifica `main.typ` ni resuelve el práctico.

## Documentar cada consigna

1. Ejecutar los comandos del punto correspondiente.
2. Copiar los comandos y sus salidas reales al informe, dentro de un bloque
   `comandos` con contenido literal `text`.
3. Intercalar la interpretación técnica como párrafos entre los bloques de consola.
4. Para las comprobaciones del navegador, describir los pasos y transcribir
   las observaciones: URL, método HTTP, estado de respuesta y mensajes visibles.

Ejemplo del formato utilizado en `tp3-c.typ`:

````typst
Creamos el volumen nombrado de MongoDB.

#comandos[
  ```text
  docker volume create catalogo-db-data
  catalogo-db-data
  ```
]
````

La función `comandos`, definida en el propio informe, aplica el estilo y ajusta
las líneas largas al ancho de la página. Las transcripciones quedan integradas
en el `.typ`. Las capturas se guardan en `docs/imagenes/` y se incluyen mediante
la función `captura`, con una leyenda que identifica la ejecución de origen.

## Formatear Typst en VS Code

Abrir la carpeta raíz del proyecto e instalar la extensión recomendada
**Tinymist Typst** (`myriad-dreamin.tinymist`). La configuración de
`.vscode/settings.json` utiliza Typstyle para formatear los archivos `.typ`
automáticamente al guardar, con indentación de dos espacios y un ancho objetivo
de 100 caracteres.

También se puede ejecutar **Format Document / Formatear documento** desde la
paleta de comandos. Typstyle está integrado en Tinymist; no requiere instalar
un paquete de npm.

## Compilar el informe

Con Typst instalado, desde la raíz del repositorio:

```bash
typst compile docs/tp3-c.typ docs/tp3-c.pdf
```

Revisar que cada consigna conserve sus comandos, resultados y explicación,
y que el PDF muestre correctamente los bloques de texto.
