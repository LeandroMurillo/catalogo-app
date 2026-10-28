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

## Puesta en marcha con Docker Compose

Antes del primer uso de Compose se deben eliminar los contenedores y la red creados manualmente en
la semana 3. El volumen no se elimina porque contiene el catálogo que se quiere conservar:

```bash
docker rm -f catalogo-frontend catalogo-api catalogo-db
docker network rm catalogo-net
docker compose config
docker compose up --build -d
docker compose ps
docker compose logs -f catalogo-api
```

La red se elimina para que Compose pueda crearla y asignarle sus etiquetas. Si se conserva una red
manual con el mismo nombre, según la versión de Compose se obtiene una advertencia o el error
`network catalogo-net was found but has incorrect label`. El volumen `catalogo-db-data`, en cambio,
se reutiliza intencionalmente y puede producir una advertencia sin perder los datos.

La verificación produjo una configuración válida y los tres servicios
alcanzaron el estado `healthy`. La base quedó visible solamente como `27017/tcp`, la API publicó
`127.0.0.1:8000` y el frontend publicó el puerto 3000.

### Healthchecks

Cada capa comprueba su propia disponibilidad:

- `catalogo-db` ejecuta `db.adminCommand('ping')` con `mongosh`. MongoDB permite esta operación sin
  autenticación porque solo informa si el servidor responde; no permite leer ni modificar datos.
  Esto evita incluir la contraseña en el comando del healthcheck y, por lo tanto, que quede visible
  en la configuración o inspección del contenedor. Es una ventaja frente a una comprobación que
  necesita transportar credenciales. Su alcance es limitado: un `ping` exitoso no demuestra que
  `catalogo_user` exista ni que `DB_PASSWORD` sea correcta.
- `catalogo-api` consulta `http://127.0.0.1:8000/health` con `urllib.request`. Ofrece la misma
  comprobación HTTP que `curl`, pero ya viene con Python; instalar `curl` solo agregaría tamaño,
  dependencias y superficie de ataque. `127.0.0.1:8000` apunta a Uvicorn dentro del propio
  contenedor, por lo que el chequeo no depende de nginx, del DNS de Docker ni del puerto publicado
  en el host. La ruta `/health` también comprueba MongoDB. `ROOT_PATH=/api` no cambia las rutas
  internas: desde nginx se accede como `/api/health`, pero dentro de la API sigue siendo `/health`.
- `catalogo-frontend` consulta `/healthz` con el `wget` incluido en BusyBox, ya disponible en Alpine.
  Esta ruta comprueba nginx sin depender de la API.

### Orden condicionado por salud

La API declara `catalogo-db` con `condition: service_healthy`. La forma corta de `depends_on` solo
esperaría a que el contenedor se iniciara, no a que MongoDB aceptara conexiones. La API conserva,
además, diez reintentos cada tres segundos: esa defensa seguirá siendo necesaria en Kubernetes,
donde no existe `depends_on`.

El frontend declara la misma condición respecto de la API. Sin ningún `depends_on`, nginx puede
arrancar antes de que el DNS de Docker conozca `catalogo-api` y terminar con
`host not found in upstream`. La forma corta evitaría ese problema de resolución, pero
`service_healthy` también evita respuestas `502` durante los primeros segundos de la API.

## Persistencia e idempotencia

El ciclo de vida se comprueba con:

```bash
docker compose down
docker compose up -d
curl -s localhost:3000/api/productos | head -c 300
docker compose down -v
```

`docker compose down` elimina contenedores y la red, pero conserva el volumen nombrado. En la
verificación se contaron 13 productos antes del `down` y los mismos 13 después del nuevo `up`, lo
que confirma la persistencia. `docker compose down -v` elimina también `catalogo-db-data`; el
siguiente arranque crea una base vacía y vuelve a cargar únicamente el catálogo demo. Debe usarse
al final o sobre una copia si se quieren conservar datos agregados manualmente.

La siembra usa un `upsert` por `nombre` y un índice único sobre ese campo. Con la base poblada se
ejecutó:

```bash
docker compose up -d --force-recreate catalogo-api
```

La cantidad permaneció en 13 productos. El índice y el `upsert` hacen que el resultado sea el mismo
incluso cuando varias réplicas intentan sembrar el catálogo al mismo tiempo.

## Revisión de seguridad

| Control | Resultado |
| --- | --- |
| Usuario de `catalogo-api` | `uid=1000(catalogo)`, distinto de root |
| Usuario de `catalogo-frontend` | `uid=101(nginx)`, distinto de root |
| Puerto del frontend | `3000:8080`, punto de entrada de la aplicación |
| Puerto de la API | `127.0.0.1:8000:8000`, solo para depuración; en la semana 6 será interno |
| Puerto de MongoDB | No publica puertos; solo expone `27017/tcp` dentro de `catalogo-net` |
| Capabilities propias | API y frontend usan `cap_drop: [ALL]` y no agregan ninguna |
| Capabilities de MongoDB | `CHOWN`, `DAC_OVERRIDE`, `SETGID` y `SETUID` |

Los usuarios se comprobaron con `docker compose exec catalogo-api id` y
`docker compose exec catalogo-frontend id`; los puertos, con `docker compose ps`.

### Escaneo de vulnerabilidades

Se ejecutó Trivy como contenedor sobre las dos imágenes propias:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image catalogo-api:v1
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image catalogo-frontend:v1
```

| Imagen y origen | Vulnerabilidades | Con `Fixed Version` |
| --- | ---: | ---: |
| `catalogo-api:v1`, sistema base Debian | 166 | 2 |
| `catalogo-api:v1`, dependencias Python | 17 | 17 |
| `catalogo-frontend:v1`, sistema base Alpine | 159 | 159 |
| `catalogo-frontend:v1`, dependencias de aplicación | 0 | 0 |

La API informó, en total, 63 bajas, 68 medias, 49 altas y 3 de severidad desconocida. El frontend
informó 42 bajas, 76 medias, 39 altas y 2 críticas. Estos resultados son una fotografía de la base
de vulnerabilidades de Trivy al momento del escaneo y pueden cambiar al actualizarla o reconstruir
las imágenes con versiones base nuevas.

### Mínimo privilegio

Los tres servicios eliminan todas las capabilities con `cap_drop: [ALL]`. La API y el frontend ya
se ejecutan como usuarios no root y solo necesitan abrir puertos no privilegiados, por lo que
funcionan sin agregar ninguna capability.

MongoDB inicia como root para preparar `/data/db` y luego cambia al usuario `mongodb`. Sin
capabilities terminó con estos errores:

```text
chown: changing ownership of '/proc/1/fd/1': Operation not permitted
error: failed switching to 'mongodb': operation not permitted
```

`CHOWN` permite ajustar propietarios, mientras que `SETGID` y `SETUID` permiten cambiar al grupo y
usuario de MongoDB. En una base limpia esas tres fueron suficientes; al reutilizar el volumen de
semanas anteriores, quitar `DAC_OVERRIDE` produjo:

```text
find: '/data/db/diagnostic.data': Permission denied
find: '/data/db/.mongodb': Permission denied
find: '/data/db/journal': Permission denied
```

Por eso la lista final agrega únicamente `CHOWN`, `DAC_OVERRIDE`, `SETGID` y `SETUID`. Con ella,
MongoDB reutilizó el volumen existente y alcanzó nuevamente el estado `healthy`.

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

Los comandos anteriores conservan el procedimiento manual de referencia de la semana 3. La
comparación con Compose es:

| Aspecto | Tres comandos `docker run` | `docker-compose.yml` |
| --- | --- | --- |
| Definición | Opciones repartidas entre varios comandos | Configuración declarativa en un archivo versionado |
| Red y volumen | Se crean manualmente antes de los contenedores | Compose los crea y administra, con nombres explícitos |
| Orden de arranque | Lo coordina la persona que ejecuta los comandos | `depends_on` espera los healthchecks |
| Estado de salud | Hay que consultar o probar cada proceso manualmente | Cada servicio declara su healthcheck y muestra `healthy` |
| Variables | Se repiten como opciones `-e` | Se centralizan en `.env` y se documentan en `.env.example` |
| Construcción | Requiere ejecutar `docker build` por separado | `docker compose up --build` construye e inicia |
| Ciclo de vida | Cada contenedor se elimina por separado | `up`, `down` y `down -v` operan sobre todo el proyecto |
| Seguridad | Las capabilities quedan implícitas por defecto | Se eliminan todas y MongoDB recupera solo las necesarias |

Desaparecen la creación y coordinación manual de recursos y los tres `docker run`. Aparecen los
healthchecks, las dependencias condicionadas, la validación previa, la reconstrucción integrada y
una gestión conjunta y reproducible del proyecto.

## Despliegue con Kubernetes

Los Services del namespace `catalogo-app` usan la label `app` para descubrir los Pods administrados
por cada Deployment. La comprobación solicitada en el TP6 produjo la siguiente salida:

```console
homelab@rp5:~/Documents/catalogo-app$ kubectl get endpoints -n catalogo-app -o wide
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                ENDPOINTS                           AGE
catalogo-api        10.244.0.28:8000,10.244.0.29:8000   27m
catalogo-db         10.244.0.27:27017                   27m
catalogo-frontend   10.244.0.30:8080,10.244.0.31:8080   27m
```

Los endpoints confirman que los selectors coinciden con las labels de los Pods: MongoDB aporta un
destino en el puerto `27017`, mientras que la API y el frontend aportan dos destinos en los puertos
`8000` y `8080`, respectivamente. Estas cantidades coinciden con las réplicas declaradas en los
Deployments. Ningún Service muestra `<none>`; si un selector no coincidiera con ninguna label, el
Service se crearía igualmente, pero no tendría destinos y no podría reenviar tráfico.

Las direcciones `10.244.0.x` pertenecen a los Pods y pueden cambiar cuando estos se reemplazan. Los
clientes no deben depender de ellas: utilizan el nombre DNS estable del Service y Kubernetes
mantiene actualizados sus endpoints. La advertencia mostrada corresponde a la evolución de la API;
la misma asociación también puede consultarse mediante `kubectl get endpointslices -n catalogo-app`.

### NodePort temporal de la API

El Service `catalogo-api-nodeport` publica temporalmente la API en
`http://<IP-del-nodo>:30502` para realizar comprobaciones directas sin pasar por nginx. Usa el
selector `app=catalogo-api`, por lo que apunta a las mismas dos réplicas que el Service interno
`catalogo-api`:

```console
homelab@rp5:~/Documents/catalogo-app$ kubectl get endpoints \
  catalogo-api catalogo-api-nodeport -n catalogo-app -o wide
NAME                    ENDPOINTS
catalogo-api            10.244.0.28:8000,10.244.0.29:8000
catalogo-api-nodeport   10.244.0.28:8000,10.244.0.29:8000

homelab@rp5:~/Documents/catalogo-app$ curl -s http://172.16.20.19:30502/health
{"status":"ok","db":"ok","version":"v1"}
```

`catalogo-api-nodeport` existe únicamente con fines de depuración y verificación durante el TP6.
*No formará parte del chart de la semana 8*: en el despliegue normal la API permanecerá como
`ClusterIP` y recibirá tráfico solo desde el frontend dentro del clúster. Evitar su exposición
reduce los puntos de entrada públicos y conserva la separación entre las capas de la aplicación.

### Limitación conocida: persistencia de MongoDB

El Deployment de Kubernetes `catalogo-db` no monta actualmente un volumen persistente en
`/data/db`. Esta limitación no afecta al despliegue con Docker Compose, que sí utiliza el volumen
nombrado `catalogo-db-data`, pero implica que los datos de MongoDB se pierden cuando Kubernetes
reemplaza su Pod.

La limitación se comprobó partiendo del producto manual `Celular de Ejemplo`, con SKU `1001`. Se
eliminó únicamente el Pod de MongoDB y el Deployment creó otro automáticamente:

```console
homelab@rp5:~/Documents/catalogo-app$ curl -s \
  'http://172.16.20.19:30502/productos?q=1001'
[{"sku":1001,"nombre":"Celular de Ejemplo",...,"imagen":true}]

homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod \
  -l app=catalogo-db -n catalogo-app
pod "catalogo-db-654f9f8fdc-nxl6q" deleted from catalogo-app namespace

homelab@rp5:~/Documents/catalogo-app$ curl -s \
  http://172.16.20.19:30502/productos
[]
```

La autorreparación recuperó el proceso de MongoDB, pero no su contenido. Después se reinició la API
para ejecutar nuevamente la siembra configurada con `SEED_DEMO=true`:

```console
homelab@rp5:~/Documents/catalogo-app$ kubectl rollout restart \
  deployment/catalogo-api -n catalogo-app
deployment.apps/catalogo-api restarted

homelab@rp5:~/Documents/catalogo-app$ curl -s \
  'http://172.16.20.19:30502/productos?q=Honor'
[{"nombre":"Honor 9N (Midnight Black, 32 GB) (3 GB RAM)",...,"sku":123222,...}]

homelab@rp5:~/Documents/catalogo-app$ curl -s \
  'http://172.16.20.19:30502/productos?q=1001'
[]
```

Los doce productos de demostración reaparecen porque están incluidos en la imagen de la API y la
siembra usa operaciones idempotentes. Los productos cargados manualmente no pueden reconstruirse.
La persistencia real de MongoDB se incorporará en la semana 7 mediante un volumen persistente
montado en `/data/db`.

## Cheatsheet de kubectl

| Comando | Descripción |
| --- | --- |
| `kubectl config current-context` | Muestra el contexto activo para comprobar contra qué clúster se ejecutarán los comandos. |
| `kubectl create namespace catalogo-app` | Crea el namespace que agrupa los recursos de la aplicación y los separa de los de otros proyectos. |
| `kubectl config set-context --current --namespace=catalogo-app` | Establece `catalogo-app` como namespace predeterminado del contexto actual para no repetir `-n` en cada operación. |
| `kubectl run catalogo-db --image=mongo:7 --dry-run=client -o yaml` | Genera localmente el manifiesto base del Pod de MongoDB sin crear el recurso en el clúster. |
| `kubectl apply -f k8s/pod-catalogo-db.yaml` | Crea el recurso declarado en el archivo o actualiza su configuración cuando ya existe. |
| `kubectl get pods -o wide` | Lista los Pods y agrega datos como la dirección IP y el nodo al que fueron asignados. |
| `kubectl describe pod catalogo-api` | Muestra la configuración, el estado y los Events utilizados para diagnosticar el Pod de la API. |
| `kubectl logs catalogo-api --previous` | Recupera los logs de la ejecución anterior del contenedor después de un reinicio. |
| `kubectl port-forward pod/catalogo-api 8000:8000` | Abre un túnel temporal de depuración entre el puerto local `8000` y el mismo puerto del Pod. |
| `kubectl delete pod catalogo-api` | Elimina el Pod de la API; permitió comprobar que, sin un controlador, Kubernetes no lo recrea. |
