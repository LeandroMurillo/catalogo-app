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

# Levantar la aplicación por comandos de Docker

La aplicación debe levantarse manualmente respetando el siguiente orden. Obsérvese que la base de datos no publica puertos hacia el host, ya que constituye la capa más interna de la aplicación y solo debe ser accesible desde los contenedores conectados a la red Docker `catalogo-net`.

```bash
# 1. Creamos la red
docker network create catalogo-net

# 2. Creamos el volumen persistente
docker volume create catalogo-db-data

# 3. Levantamos la base de datos
docker run -d \
  --name catalogo-db \
  --network catalogo-net \
  -e MONGO_INITDB_ROOT_USERNAME=catalogo_user \
  -e MONGO_INITDB_ROOT_PASSWORD=catalogo_pass \
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
  -e DB_PASSWORD=catalogo_pass \
  -e APP_VERSION=v1 \
  -e ROOT_PATH=/api \
  -e SEED_DEMO=true \
  -p 8000:8000 \
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

Es importante respetar este orden de arranque, ya que los distintos componentes de la aplicación tienen dependencias entre sí. Alterar la secuencia puede provocar los siguientes problemas:

- Si catalogo-net no existe al ejecutar un contenedor con --network catalogo-net, Docker no podrá conectarlo a la red y el comando fallará. Además, un contenedor ejecutado sin especificar esta red quedará conectado a la red bridge por defecto y no podrá resolver por nombre a los contenedores de catalogo-net.

- El volumen se crea antes de MongoDB para disponer previamente del almacenamiento persistente que se montará en /data/db. De esta manera, los datos pueden conservarse aunque el contenedor de la base de datos sea eliminado y recreado.

- La base de datos debe estar disponible antes de iniciar la API, ya que esta intenta conectarse a catalogo-db. Si el contenedor no existe o MongoDB todavía no está disponible, la API no podrá establecer la conexión.

- La API debe iniciarse antes que el frontend porque nginx utiliza catalogo-api como upstream. Si ese nombre no puede resolverse al arrancar, nginx falla y el contenedor del frontend termina su ejecución.

## Limitación actual

Actualmente, este orden de arranque debe ser conocido y ejecutado manualmente por la persona que levanta la aplicación.

La relación entre la red, el volumen y los distintos contenedores todavía no está declarada en un único archivo ejecutable. Esta limitación se resolverá en la siguiente etapa mediante Docker Compose.