# catalogo-app

Aplicación web de catálogo de productos desarrollada como proyecto integrador del curso
**Contenedores, Docker y Orquestación con Kubernetes**.

Está compuesta por una interfaz web en React + Vite, una API REST desarrollada con
Python y FastAPI, y una base de datos MongoDB 7. La aplicación permite visualizar
productos, buscar por nombre o SKU, filtrar por categoría y consultar el detalle de
cada producto.

## Arquitectura

    navegador ──► catalogo-frontend ──────► catalogo-api ──────► catalogo-db
                  React + Vite              Python + FastAPI     MongoDB 7
                  nginx :8080               :8000                :27017
                  (host 3000)               (host 8000, solo     (sin puerto
                                            depuración)          publicado)

| Capa | Imagen | Puerto interno | Puerto publicado |
| --- | --- | --- | --- |
| `catalogo-frontend` | React + Vite servido por nginx | 8080 | 3000 |
| `catalogo-api` | Python + FastAPI | 8000 | 8000 (solo depuración) |
| `catalogo-db` | MongoDB 7 | 27017 | — |

El frontend es el único punto de entrada: nadie le habla a la base
directamente, y a la API le habla el frontend.

## Configuración con Docker Compose

La configuración de cada entorno se mantiene fuera de las imágenes. Docker Compose lee `.env`
automáticamente desde la raíz del proyecto, mientras que `.env.example` documenta el contrato de
variables sin incluir secretos reales. El archivo `.env` es local y está excluido de Git.

Para configurar el proyecto por primera vez:

```bash
cp .env.example .env
```

Luego se debe editar `.env` y asignar una contraseña segura a `DB_PASSWORD`. Las demás variables
incluyen valores adecuados para el entorno local con Compose:

| Variable | Consumidor | Finalidad |
| --- | --- | --- |
| `API_HOST` | Frontend (nginx) | Nombre interno de la API |
| `API_PORT` | Frontend (nginx) | Puerto interno de la API |
| `DB_HOST` | API | Nombre interno de MongoDB |
| `DB_PORT` | API | Puerto interno de MongoDB |
| `DB_NAME` | API | Base de datos de la aplicación |
| `DB_USER` | API y MongoDB | Usuario compartido; Compose lo asigna a `MONGO_INITDB_ROOT_USERNAME` |
| `DB_PASSWORD` | API y MongoDB | Contraseña compartida; Compose la asigna a `MONGO_INITDB_ROOT_PASSWORD` |
| `MONGO_URI` | API | URI de conexión opcional que reemplaza las variables `DB_*` para la conexión |
| `APP_VERSION` | API | Versión informada por `/health` |
| `ROOT_PATH` | API | Prefijo externo bajo el que se publica FastAPI |
| `SEED_DEMO` | API | Activa o desactiva la carga del catálogo de ejemplo |

Todas las variables operativas son obligatorias en Compose, excepto `MONGO_URI`, que puede quedar
vacía para utilizar `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD`.

Antes de iniciar, se puede validar que estén definidas todas las variables requeridas sin imprimir
sus valores:

```bash
docker compose config --quiet
docker compose config --variables
```

La aplicación se construye e inicia en segundo plano con:

```bash
docker compose up --build -d
docker compose ps
```

Para usar otro entorno no hace falta duplicar el archivo Compose ni reconstruir imágenes. Se indica
un archivo de variables diferente en cada comando:

```bash
docker compose --env-file .env.desarrollo config --quiet
docker compose --env-file .env.desarrollo up -d
```

Los archivos `.env.*` están ignorados salvo `.env.example`. No se deben versionar contraseñas,
tokens ni una `MONGO_URI` real: esta última contiene las credenciales completas. En Kubernetes,
`DB_PASSWORD` o `MONGO_URI` deberán almacenarse en un Secret, nunca en un ConfigMap. También se debe
evitar compartir la salida completa de `docker compose config`, porque muestra los valores resueltos.

## Levantar la aplicación por comandos de Docker

La aplicación debe levantarse manualmente respetando el siguiente orden. Obsérvese que la base de datos no publica puertos hacia el host, ya que constituye la capa más interna de la aplicación y solo debe ser accesible desde los contenedores conectados a la red Docker `catalogo-net`.

```bash
# La contraseña se solicita sin mostrarla ni guardarla en el historial del shell.
read -rsp "Contraseña de MongoDB: " DB_PASSWORD && export DB_PASSWORD

# 1. Creamos la red
docker network create catalogo-net

# 2. Creamos el volumen persistente
docker volume create catalogo-db-data

# 3. Levantamos la base de datos
docker run -d \
  --name catalogo-db \
  --network catalogo-net \
  -e MONGO_INITDB_ROOT_USERNAME=catalogo_user \
  -e MONGO_INITDB_ROOT_PASSWORD="$DB_PASSWORD" \
  -v catalogo-db-data:/data/db \
  mongo:7

# 4. Levantamos la API
docker run -d \
  --name catalogo-api \
  --network catalogo-net \
  -e DB_HOST=catalogo-db \
  -e DB_PORT=27017 \
  -e DB_NAME=catalogodb \
  -e DB_USER=catalogo_user \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e APP_VERSION=v1 \
  -e ROOT_PATH=/api \
  -e SEED_DEMO=true \
  -p 127.0.0.1:8000:8000 \
  catalogo-api:v1

# 5. Levantamos el frontend
docker run -d \
  --name catalogo-frontend \
  --network catalogo-net \
  -e API_HOST=catalogo-api \
  -e API_PORT=8000 \
  -p 3000:8080 \
  catalogo-frontend:v1
```

Resultado registrado al ejecutar el contenedor de MongoDB:

```console
homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-db --network catalogo-net -e MONGO_INITDB_ROOT_USERNAME=catalogo_user -e MONGO_INITDB_ROOT_PASSWORD=[REDACTED] -v catalogo-db-data:/data/db mongo:7
cd59c9d7d1bbcd2ff291a9ddedcb4ff08f5c65498f074389fe3e8bdb03a6d45a
```

Es importante respetar este orden de arranque, ya que los distintos componentes de la aplicación tienen dependencias entre sí. Alterar la secuencia puede provocar los siguientes problemas:

- Si catalogo-net no existe al ejecutar un contenedor con --network catalogo-net, Docker no podrá conectarlo a la red y el comando fallará. Además, un contenedor ejecutado sin especificar esta red quedará conectado a la red bridge por defecto y no podrá resolver por nombre a los contenedores de catalogo-net.

- El volumen se crea antes de MongoDB para disponer previamente del almacenamiento persistente que se montará en /data/db. De esta manera, los datos pueden conservarse aunque el contenedor de la base de datos sea eliminado y recreado.

- La base de datos debe estar disponible antes de iniciar la API, ya que esta intenta conectarse a catalogo-db. Si el contenedor no existe o MongoDB todavía no está disponible, la API no podrá establecer la conexión.

- La API debe iniciarse antes que el frontend porque nginx utiliza catalogo-api como upstream. Si ese nombre no puede resolverse al arrancar, nginx falla y el contenedor del frontend termina su ejecución.

## Ejecución manual y Compose

Los comandos anteriores conservan el procedimiento manual de referencia. En el uso normal,
`docker-compose.yml` declara la red, el volumen, los healthchecks y el orden condicionado por salud,
por lo que no es necesario crear los recursos ni coordinar el arranque manualmente.
