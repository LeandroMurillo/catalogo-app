#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2cm),
  footer: context {
    set text(font: "Liberation Sans", size: 8.5pt)
    set par(justify: false, leading: 5pt, spacing: 0pt)
    block(width: 100%, stroke: (top: 0.7pt), inset: (top: 3pt))[
      #grid(
        columns: (1fr, auto),
        align: (left, right + bottom),
        [Contenedores, Docker y Orquestación con Kubernetes \
          FACET – UNT],
        counter(page).display("1"),
      )
    ]
  },
)

#set text(font: "Liberation Serif", size: 11.5pt, lang: "es", hyphenate: false)
#set par(justify: true, leading: 8.7pt, spacing: 8pt)
#set heading(numbering: none)
#show heading: set text(size: 11.5pt, weight: "bold")
#show raw: set text(font: "Liberation Mono", size: 10.35pt)
#set list(marker: [○], indent: 3.5pt, body-indent: 6pt)

#let consigna(numero, cuerpo) = {
  {
    show heading: none
    heading(level: 2, outlined: true)[Consigna #numero]
  }
  block(above: 14pt, below: 0pt, enum(
    start: numero,
    numbering: n => box(width: 17pt, align(right)[#n)]),
    indent: 0pt,
    body-indent: 5pt,
    cuerpo,
  ))
}

#let incisos(..items) = enum(
  numbering: "a)",
  indent: 3.5pt,
  body-indent: 6pt,
  spacing: 10.5pt,
  ..items.pos(),
)

// Inicio de una respuesta o apartado: separación uniforme y unión con lo que sigue.
#let paso(cuerpo) = block(
  above: 18pt,
  below: 8pt,
  breakable: true,
  sticky: true,
  cuerpo,
)

// Separador entre el enunciado y el primer párrafo de la resolución.
#let resolucion(cuerpo) = block(
  width: 100%,
  above: 18pt,
  below: 8pt,
  inset: (top: 10pt),
  stroke: (top: 0.8pt + black),
  breakable: true,
  sticky: true,
  cuerpo,
)

// Separación entre la leyenda de cada figura y el contenido siguiente.
#show figure: set block(below: 20pt)
// Leyendas más pequeñas y en sans serif para distinguirlas del cuerpo del informe.
#show figure.caption: set text(font: "Liberation Sans", size: 9.5pt)
#show figure.caption: set par(justify: false, leading: 4pt)

#let captura(archivo, leyenda, ancho: 100%) = figure(
  image("imagenes/" + archivo, width: ancho),
  caption: leyenda,
)

#let comandos(cuerpo) = block(
  width: 100%,
  above: 8pt,
  below: 8pt,
  inset: 6pt,
  fill: rgb("#F4F4F4"),
  stroke: 0.6pt + rgb("#CCCCCC"),
  radius: 1.5pt,
  breakable: true,
)[
  #set par(justify: false, leading: 6.9pt, spacing: 0pt)
  #show raw: it => {
    set text(font: "Liberation Mono", size: 8.1pt)
    // La regla también recibe el raw generado: insertar los cortes solo una vez.
    if it.text.contains("\u{200b}") or it.text.len() < 2 {
      it
    } else {
      let ajustado = it.text.clusters().join("\u{200b}")
      raw(ajustado, block: it.block, lang: it.lang)
    }
  }
  #cuerpo
]


// Consignas transcritas de tp-03-C.pdf, páginas 2 a 5.
#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 3 — Variante C]

  Proyecto: `catalogo-app`
]

Evidencias ejecutadas en Bash sobre `homelab@rp5`. Los puntos 1 a 3 conservan
la ejecución previa; los puntos 4 a 8 se verificaron el 7 de octubre de 2026,
de 00:23 a 00:30 (UTC−3). Los comandos de Docker y sus salidas se transcriben
directamente en este documento. Las comprobaciones del navegador se realizaron
con Chromium automatizado mediante Playwright y el dominio Network de Chrome
DevTools Protocol; sus resultados se conservan como observaciones textuales.
Las explicaciones se intercalan con los bloques de comandos y sus salidas.
Las líneas largas se ajustan al ancho de página.

Las capturas incluidas en los puntos 6, 7 y 8 corresponden a la ejecución
anterior en Windows del 4 de octubre de 2026. Complementan las transcripciones
de Bash; el producto de esa ejecución tiene un identificador diferente.

= Consignas

#consigna(1)[
  Crear la red y el volumen con los nombres estándar de la variante, y registrar la salida de
  `docker network ls` y `docker volume ls`:

  #resolucion[Creamos la red `catalogo-net` y el volumen `catalogo-db-data`.]

  #comandos[
    ```text
    docker network create catalogo-net
    docker volume create catalogo-db-data
    ```
  ]

  Consultamos las listas de redes y volúmenes para comprobar que ambos recursos se crearon correctamente.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker network ls
    NETWORK ID     NAME           DRIVER    SCOPE
    6787f465fb08   bridge         bridge    local
    2a8c3a3a55a5   catalogo-net   bridge    local
    e43ff3617b0a   host           host      local
    501a54eb7c99   none           null      local

    homelab@rp5:~/Documents/catalogo-app$ docker volume ls
    DRIVER    VOLUME NAME
    local     8dbb5fc9bc215afe5a3a5d1418910be2f6829388ddc8066e7343093504e9906b
    local     c0438e22d2bf138e1888a4685f739efeab5691d5056daab1552a5b314f187885
    local     catalogo-db-data
    ```
  ]
]

#pagebreak()

#consigna(2)[
  Ejecutar el contenedor de la base de datos con las características que se detallan a
  continuación, *sin publicar ningún puerto*. El comando debe construirse a partir de lo visto
  en clase; se solicita transcribirlo en el `README.md` junto con su resultado.

  - *Nombre:* `catalogo-db`
  - *Red:* `catalogo-net`
  - *Imagen:* `mongo:7`
  - *Variables de entorno:* las dos de la primera semana, con los valores estándar de la
    variante: usuario `catalogo_user` y contraseña `catalogo_pass`
  - *Volumen:* `catalogo-db-data`, montado sobre el directorio de datos del motor: `/data/db`
  - *Puertos publicados:* ninguno

  La ausencia del parámetro `-p` es deliberada: la base de datos es la capa más interna y solo
  debe alcanzarse desde `catalogo-net`. Corresponde justificar esa decisión por escrito en el
  `README.md`. Registrar además la línea del registro que informa que el motor se encuentra a la
  espera de conexiones.

  #resolucion[Iniciamos MongoDB con el volumen montado en `/data/db` y sin publicar puertos.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-db --network catalogo-net -e MONGO_INITDB_ROOT_USERNAME=catalogo_user -e MONGO_INITDB_ROOT_PASSWORD=catalogo_pass -v catalogo-db-data:/data/db mongo:7
    cd59c9d7d1bbcd2ff291a9ddedcb4ff08f5c65498f074389fe3e8bdb03a6d45a
    ```
  ]

  Consultamos el registro para comprobar que el motor acepta conexiones.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-db 2>&1 | grep "Waiting for connections"
    {"t":{"$date":"2026-10-06T23:00:45.520+00:00"},"s":"I",  "c":"NETWORK",  "id":23016,   "ctx":"listener","msg":"Waiting for connections","attr":{"port":27017,"ssl":"off"}}

    ```
  ]

  No publicamos el puerto `27017` mediante `-p`, ya que la API accede a MongoDB
  a través de `catalogo-net`. Así evitamos exponer la base de datos mediante un
  puerto del anfitrión: la aplicación solo necesita acceder desde la red interna.
  El mensaje
  `Waiting for connections` confirma que MongoDB acepta conexiones.
]

#pagebreak()

#consigna(3)[
  Ejecutar el contenedor de la API en la misma red, configurado para alcanzar la base *por
  nombre*. Debe esperarse a que el motor haya terminado de inicializar antes de levantarla.

  - *Nombre:* `catalogo-api`
  - *Red:* `catalogo-net`
  - *Imagen:* `catalogo-api:v1`
  - *Variables de entorno:* `DB_HOST=catalogo-db`, `DB_PORT=27017`,
    `DB_NAME=catalogodb`, `DB_USER=catalogo_user`, `DB_PASSWORD=catalogo_pass`,
    `APP_VERSION=v1`, `ROOT_PATH=/api`, `SEED_DEMO=true`
  - *Puertos publicados:* el `8000` del contenedor en el `8000` del anfitrión, *solo para depuración*

  Comprobar y registrar:

  #incisos(
    [la salida de `docker exec catalogo-api getent hosts catalogo-db`;],
    [la respuesta de `curl -s localhost:8000/health`;],
    [la cantidad de productos sembrados, mediante `curl -s localhost:8000/productos`
      o consultando la colección con `mongosh`.],
  )

  #resolucion[Ejecutamos el contenedor de la API con la configuración indicada.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-db -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e ROOT_PATH=/api -e SEED_DEMO=true catalogo-api:v1
    0401fa1d5697faae0d65157c448293868ad8d99607709712ae92d20bfaa51e65

    ```
  ]

  #paso[a) Comprobamos la resolución del nombre `catalogo-db` en la red interna.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-api getent hosts catalogo-db
    172.18.0.2      catalogo-db

    ```
  ]

  Consultamos el registro para verificar el inicio de la API y la conexión con MongoDB.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-api
    INFO:     Started server process [1]
    INFO:     Waiting for application startup.
    [2026-10-07T02:05:52+0000] INFO conexión a MongoDB establecida (base=catalogodb)
    [2026-10-07T02:05:52+0000] INFO catálogo de demo sembrado (12 productos)
    INFO:     Application startup complete.
    INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)

    ```
  ]

  #paso[b) Comprobamos el estado de la API mediante `/health`.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/health
    {"status":"ok","db":"ok","version":"v1"}

    ```
  ]

  #paso[c) Consultamos los productos sembrados.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/productos
    [{"sku":999666,"categoria":"Apple","creado_en":"2026-10-07T02:05:52.505000","descripcion":"Clásico de 4.7\" con Touch ID y cuerpo de aluminio.","imagen_hash":"7e23251b780a76a1","imagen_tipo":"image/jpeg","nombre":"Apple iPhone 6 (Gold, 32 GB)","precio":44000,"stock":2,"id":"6ac5a9003376de06cf3ec2d4","imagen":true},{"sku":379182,"categoria":"Apple","creado_en":"2026-10-07T02:05:52.518000","descripcion":"Pantalla Retina HD de 5.5\", carga inalámbrica y chip A11.","imagen_hash":"27cf5a0cc72a5c03","imagen_tipo":"image/jpeg","nombre":"Apple iPhone 8 Plus (Silver, 64 GB)","precio":48000,"stock":6,"id":"6ac5a9003376de06cf3ec2da","imagen":true},{"sku":456654,"categoria":"Apple","creado_en":"2026-10-07T02:05:52.489000","descripcion":"Super Retina de 5.8\", Face ID y chip A11 Bionic.","imagen_hash":"8101c6ff7c22f74d","imagen_tipo":"image/jpeg","nombre":"Apple iPhone X (Space Gray, 256 GB)","precio":25000,"stock":3,"id":"6ac5a9003376de06cf3ec2ca","imagen":true},{"sku":963852,"categoria":"Asus","creado_en":"2026-10-07T02:05:52.502000","descripcion":"Batería de 4000 mAh que funciona también como power bank.","imagen_hash":"95255abbb146483b","imagen_tipo":"image/jpeg","nombre":"Asus ZenFone Max M1 (Black, 32 GB) (3 GB RAM)","precio":84000,"stock":0,"id":"6ac5a9003376de06cf3ec2d2","imagen":true},{"sku":123222,"categoria":"Honor","creado_en":"2026-10-07T02:05:52.495000","descripcion":"Pantalla FullView de 5.84\" con notch y cámara dual de 13 MP.","imagen_hash":"1e45d7360052e1e1","imagen_tipo":"image/jpeg","nombre":"Honor 9N (Midnight Black, 32 GB) (3 GB RAM)","precio":39000,"stock":11,"id":"6ac5a9003376de06cf3ec2ce","imagen":true},{"sku":741852,"categoria":"Lenovo","creado_en":"2026-10-07T02:05:52.499000","descripcion":"Procesador Helio X23 de diez núcleos y Android puro.","imagen_hash":"5bf64a1fb53294cd","imagen_tipo":"image/jpeg","nombre":"Lenovo K8 Note (Venom Black, 64 GB) (4 GB RAM)","precio":36000,"stock":5,"id":"6ac5a9003376de06cf3ec2d0","imagen":true},{"sku":357842,"categoria":"OPPO","creado_en":"2026-10-07T02:05:52.485000","descripcion":"Lector de huellas bajo la pantalla AMOLED y cámara frontal de 25 MP.","imagen_hash":"24b3652bc891267c","imagen_tipo":"image/jpeg","nombre":"OPPO K1 (Piano Black, 64 GB) (4 GB RAM)","precio":65000,"stock":6,"id":"6ac5a9003376de06cf3ec2c8","imagen":true},{"sku":852369,"categoria":"Xiaomi","creado_en":"2026-10-07T02:05:52.476000","descripcion":"Pantalla 5.99\" HD+, cámara dual de 12 MP y batería de 3080 mAh.","imagen_hash":"3926b6235eecc7b3","imagen_tipo":"image/jpeg","nombre":"Redmi Y2 (Black, 32 GB) (3 GB RAM)","precio":25000,"stock":14,"id":"6ac5a9003376de06cf3ec2c4","imagen":true},{"sku":848484,"categoria":"Samsung","creado_en":"2026-10-07T02:05:52.513000","descripcion":"Super AMOLED de 6.3\" y cámara dual de 16 MP + 24 MP.","imagen_hash":"6e0b6f7b0f8514c0","imagen_tipo":"image/jpeg","nombre":"Samsung Galaxy A8 Star (White, 64 GB) (6 GB RAM)","precio":78000,"stock":8,"id":"6ac5a9003376de06cf3ec2d8","imagen":true},{"sku":332211,"categoria":"Samsung","creado_en":"2026-10-07T02:05:52.509000","descripcion":"Primer smartphone con cuatro cámaras traseras y pantalla de 6.3\".","imagen_hash":"97b0b86fea2f5dc7","imagen_tipo":"image/jpeg","nombre":"Samsung Galaxy A9 (Bubblegum Pink, 128 GB)","precio":97000,"stock":4,"id":"6ac5a9003376de06cf3ec2d6","imagen":true},{"sku":159753,"categoria":"Samsung","creado_en":"2026-10-07T02:05:52.481000","descripcion":"Batería de 5000 mAh con carga rápida y pantalla Infinity-V de 6.3\".","imagen_hash":"178a6127bb70f3cb","imagen_tipo":"image/jpeg","nombre":"Samsung Galaxy M20 (Charcoal Black, 4+64GB)","precio":58000,"stock":9,"id":"6ac5a9003376de06cf3ec2c6","imagen":true},{"sku":358426,"categoria":"Vivo","creado_en":"2026-10-07T02:05:52.491000","descripcion":"Cámara frontal pop-up de 32 MP y triple cámara trasera de 48 MP.","imagen_hash":"11814686e87c1818","imagen_tipo":"image/jpeg","nombre":"Vivo V15 Pro (Topaz Blue, 128 GB) (6 GB RAM)","precio":55000,"stock":7,"id":"6ac5a9003376de06cf3ec2cc","imagen":true}]

    ```
  ]

  Contamos los documentos de la colección para confirmar que contiene los 12 productos de demostración.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-db mongosh --quiet 'mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb?authSource=admin' --eval 'db.productos.countDocuments({})'
    12
    ```
  ]

  La variable `DB_HOST` contiene el *nombre* `catalogo-db`, no una dirección IP.
  El servidor DNS interno de Docker resuelve ese nombre dentro de `catalogo-net`.
  La red `bridge` predeterminada no ofrece esa resolución automática de nombres.
]

#pagebreak()

#consigna(4)[
  Distinguir los dos modos de falla del motor, que producen mensajes distintos y se
  diagnostican de manera distinta:

  #incisos(
    [volver a crear la API con `DB_HOST` mal escrito (por ejemplo, `catalogo-bd`) y registrar
      el mensaje del registro, que informará un fallo de *resolución de nombre*;],
    [conectarse con `mongosh` empleando una cadena de conexión *sin* el parámetro
      `?authSource=admin` y registrar el mensaje, que informará un fallo de *autenticación*;],
    [explicar en dos líneas por qué el primero indica que no se alcanzó la base y el segundo
      que sí se la alcanzó.],
  )

  #resolucion[
    a) Eliminamos el contenedor `catalogo-api` y lo recreamos con el nombre de host
    incorrecto `catalogo-bd` en la variable `DB_HOST`.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-bd -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e ROOT_PATH=/api -e SEED_DEMO=true catalogo-api:v1
    6941f8fabac7ac2eac249d2836f2115c6e83a3a459af85b86bb2a17768625225
    ```
  ]

  Esperamos a que la API intente conectarse a MongoDB y consultamos su registro.
  Como `catalogo-bd` no corresponde a un nombre resoluble en la red, el intento
  de conexión falla durante la resolución del nombre.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-api 2>&1 | grep -m 1 "conexión falló"
    [2026-10-07T03:23:47+0000] WARNING intento 1/10 de conexión falló: catalogo-bd:27017: [Errno -3] Temporary failure in name resolution (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ac5bb400697dcddda5f4a97, topology_type: Unknown, servers: [<ServerDescription ('catalogo-bd', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-bd:27017: [Errno -3] Temporary failure in name resolution (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
    ```
  ]

  #paso[
    b) Intentamos conectarnos con `mongosh` sin el parámetro `authSource=admin`.
    La autenticación falla y el comando termina con código de salida 1.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-db mongosh --quiet 'mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb' --eval 'db.runCommand({ping:1})'
    MongoServerError: Authentication failed.
    ```
  ]

  #paso[
    c) El primer error ocurre al resolver `catalogo-bd`, por lo que no se llega a MongoDB.
    En el segundo caso, se llega al motor, pero se intenta autenticar al usuario
    en `catalogodb`, aunque está definido en la base `admin`.
  ]

  Restablecemos la configuración correcta y esperamos a que la API esté disponible.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-db -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e ROOT_PATH=/api -e SEED_DEMO=true catalogo-api:v1
    f348878226ac22f0d04894e2cfe2c70260fef9fd0001f562f92181e6f00acf0f

    homelab@rp5:~/Documents/catalogo-app$ for i in {1..30}; do if curl -fsS localhost:8000/health 2>/dev/null; then break; fi; sleep 1; done
    {"status":"ok","db":"ok","version":"v1"}
    ```
  ]

]

#pagebreak()

#consigna(5)[
  Reproducir el error del frontend de manera deliberada: ejecutarlo *fuera* de la red, es decir,
  omitiendo el parámetro `--network`.

  - *Nombre:* `catalogo-frontend`
  - *Red: ninguna* — ahí está el error que se busca
  - *Imagen:* `catalogo-frontend:v1`
  - *Variables de entorno:* `API_HOST=catalogo-api`, `API_PORT=8000`
  - *Puertos publicados:* el `8080` del contenedor en el `3000` del anfitrión

  Registrar la salida de `docker ps -a`, que informará `Exited (1)`, y la de
  `docker logs catalogo-frontend`. Se solicita transcribir el mensaje textual y explicar en dos líneas
  *por qué el proceso termina en lugar de arrancar en estado degradado*: nginx resuelve el
  _upstream_ de `proxy_pass` una única vez, al iniciar, y si no lo resuelve no reintenta.

  #resolucion[
    Iniciamos el frontend sin la opción `--network`. Docker lo conecta a la red
    predeterminada `bridge`, en lugar de conectarlo a `catalogo-net`.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-frontend -p 3000:8080 -e API_HOST=catalogo-api -e API_PORT=8000 catalogo-frontend:v1
    4c14085d9135731b28912cbfc352cdd22abb54265432dc5f0096132a5943915e
    ```
  ]

  Esperamos unos segundos y comprobamos que el contenedor queda en estado `Exited (1)`.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ sleep 3; docker ps -a
    CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS                     PORTS                                         NAMES
    4c14085d9135   catalogo-frontend:v1   "/docker-entrypoint.…"   3 seconds ago   Exited (1) 2 seconds ago                                                 catalogo-frontend
    f348878226ac   catalogo-api:v1        "uvicorn main:app --…"   6 seconds ago   Up 6 seconds               0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   catalogo-api
    cd59c9d7d1bb   mongo:7                "docker-entrypoint.s…"   4 hours ago     Up 4 hours                 27017/tcp                                     catalogo-db

    ```
  ]

  Inspeccionamos el registro para identificar la causa del fallo.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-frontend 2>&1
    /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
    /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
    10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
    10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf differs from the packaged version
    /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
    20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/default.conf.template to /etc/nginx/conf.d/default.conf
    /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
    /docker-entrypoint.sh: Configuration complete; ready for start up
    2026/10/07 03:23:55 [emerg] 1#1: host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
    nginx: [emerg] host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24

    ```
  ]

  Al cargar la configuración, nginx intenta resolver el nombre del servidor de destino
  (_upstream_). Fuera de `catalogo-net`, no puede resolver `catalogo-api`.
  Este fallo impide el arranque: el proceso principal termina con código de salida 1,
  en lugar de iniciar en un estado degradado o reintentar la resolución.
]

#pagebreak()

#consigna(6)[
  Eliminar el contenedor que quedó en estado `Exited` y volver a crearlo con *las mismas
  opciones del punto anterior, más la conexión a `catalogo-net`*. Adviértase que la imagen
  es la misma y que no se reconstruye nada: lo único que cambia es la red.
  Acceder a `http://localhost:3000`, cargar un producto *con imagen* y observar el
  resultado con las *herramientas de desarrollo del navegador* abiertas en la pestaña _Network_.
  La solicitud debe dirigirse a `/api/productos` sobre el *mismo origen* (`localhost:3000`) y
  no a `localhost:8000`. Corresponde registrar esa observación y señalar la ausencia de
  solicitudes `OPTIONS`.

  #resolucion[
    Eliminamos el contenedor detenido y lo recreamos con las mismas opciones,
    añadiendo únicamente `--network catalogo-net`.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm catalogo-frontend
    catalogo-frontend

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-frontend --network catalogo-net -p 3000:8080 -e API_HOST=catalogo-api -e API_PORT=8000 catalogo-frontend:v1
    547af00c8fec249dd60c86ba7c6f226291835419dfa78032e1d42b735b01e39d

    homelab@rp5:~/Documents/catalogo-app$ sleep 2; curl -s localhost:3000/api/health
    {"status":"ok","db":"ok","version":"v1"}

    ```
  ]

  Mediante la ejecución automatizada en Chromium, completamos el formulario de
  `http://localhost:3000` y cargamos la imagen `backend/imagenes/1.jpeg`.
  A continuación, se muestran la solicitud, su respuesta y el resumen de tráfico
  registrados mediante el dominio Network de Chrome DevTools Protocol:

  #comandos[
    ```text
    POST http://localhost:3000/api/productos -> 201
    {"sku": 7102026, "nombre": "Producto TP3 Bash con imagen", "precio": 12345.0, "categoria": "TP3", "stock": 3, "descripcion": "Verificación de proxy y persistencia desde Chromium.", "imagen_tipo": "image/jpeg", "imagen_hash": "3926b6235eecc7b3", "creado_en": "2026-10-07T03:28:27.265000", "id": "6ac5bc5bce059c6015706f07", "imagen": true}
    OPTIONS observados: 0; solicitudes al puerto 8000: 0

    ```
  ]

  #captura("producto-creado.jpeg", [
    Vista parcial del catálogo después de crear el producto en la ejecución
    del 4 de octubre. El filtro «Prueba TP3» muestra un producto.
  ], ancho: 45%)

  Confirmamos en el registro del proxy que la solicitud de creación del producto se procesó correctamente.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-frontend 2>&1 | grep "POST /api/productos"
    2026/10/07 03:28:27 [warn] 35#35: *13 a client request body is buffered to a temporary file /tmp/client_temp/0000000001, client: 172.18.0.1, server: _, request: "POST /api/productos HTTP/1.1", host: "localhost:3000", referrer: "http://localhost:3000/"
    172.18.0.1 - - [07/Oct/2026:03:28:27 +0000] "POST /api/productos HTTP/1.1" 201 317 "http://localhost:3000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/153.0.8010.12 Safari/537.36" "-"

    ```
  ]

  La solicitud del navegador utiliza el mismo esquema, anfitrión y puerto que la página.
  nginx recibe la petición en `/api/productos` y la reenvía a `catalogo-api:8000`
  con la ruta `/productos`. Como la petición tiene el mismo origen que la página,
  no requiere una solicitud previa de comprobación CORS (_preflight_, con el método `OPTIONS`).
  La corrección consistió en conectar el frontend a `catalogo-net`, sin reconstruir las imágenes.
]

#pagebreak()

#consigna(7)[
  Verificar el proxy y el efecto de `ROOT_PATH`:

  #incisos(
    [comparar `curl -s localhost:8000/productos` con `curl -s localhost:3000/api/productos`;],
    [consultar `curl -s localhost:8000/openapi.json` y localizar la clave `servers`,
      que con `ROOT_PATH=/api` contiene `{"url":"/api"}`;],
    [volver a crear la API *sin* dicha variable, repetir la consulta anterior y comprobar que la
      clave `servers` *desaparece* del documento;],
    [abrir en el navegador `http://localhost:3000/api/docs` en cada caso y explicar por
      escrito la diferencia observada.],
  )

  #paso[
    Ese documento `openapi.json` es el que consume la interfaz de documentación automática:
    sin el prefijo declarado, las direcciones que genera no contemplan el `/api` y la página
    no funciona a través del _proxy_.
  ]

  #resolucion[
    a) Comparamos las respuestas completas obtenidas al consultar la API directamente
    y a través del proxy. La sustitución de procesos `<(...)` es una construcción de Bash.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ diff -s <(curl -fsS localhost:8000/productos) <(curl -fsS localhost:3000/api/productos)
    Files /dev/fd/63 and /dev/fd/62 are identical

    ```
  ]

  #paso[b) Consultamos el valor de la clave `servers` del documento OpenAPI con `ROOT_PATH=/api`.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/openapi.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"servers": d["servers"]}) if "servers" in d else "Clave servers ausente")'
    {"servers": [{"url": "/api"}]}

    ```
  ]

  Al abrir `http://localhost:3000/api/docs` en Chromium con `ROOT_PATH=/api`,
  se observa lo siguiente:

  #comandos[
    ```text
    GET http://localhost:3000/api/openapi.json
    Swagger UI: catálogo cargado; servidor /api disponible.

    ```
  ]

  #captura("docs-con-root-path.jpeg", [
    Swagger con ROOT_PATH=/api: se muestran el servidor /api y las operaciones
    disponibles. Captura del 4 de octubre.
  ])

  #paso[c) Recreamos la API omitiendo completamente `ROOT_PATH`.]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-db -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e SEED_DEMO=true catalogo-api:v1
    2985dbc2e4ee92a07b3087211aabc4a33e27ceb2a367fd74a481b1653fcd99ed

    homelab@rp5:~/Documents/catalogo-app$ for i in {1..30}; do if curl -fsS localhost:8000/health 2>/dev/null; then break; fi; sleep 1; done
    {"status":"ok","db":"ok","version":"v1"}

    ```
  ]

  Reiniciamos nginx para que vuelva a resolver el nombre de la API y obtenga la
  dirección IP del contenedor recreado. Luego verificamos la ausencia de la
  variable de entorno y consultamos el documento OpenAPI.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker restart catalogo-frontend
    catalogo-frontend

    homelab@rp5:~/Documents/catalogo-app$ sleep 2

    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-api python -c 'import os; print("ROOT_PATH en entorno:", repr(os.environ.get("ROOT_PATH")))'
    ROOT_PATH en entorno: None

    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/openapi.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"servers": d["servers"]}) if "servers" in d else "Clave servers ausente")'
    {"servers": [{"url": "/api"}]}

    ```
  ]

  Al abrir `http://localhost:3000/api/docs` en Chromium sin definir la variable `ROOT_PATH`,
  Swagger sigue cargando el catálogo:

  #comandos[
    ```text
    GET http://localhost:3000/api/openapi.json
    Swagger UI: catálogo cargado; servidor /api disponible.

    ```
  ]

  #captura("docs-variable-omitida.jpeg", [
    Swagger con ROOT_PATH omitida: el servidor /api sigue disponible gracias
    al valor predeterminado de la aplicación. Captura del 4 de octubre.
  ])

  #paso[
    d) Omitir la variable no cambia el resultado en esta aplicación, porque
    `backend/main.py` utiliza `os.environ.get("ROOT_PATH", "/api")`.
    Por lo tanto, la clave `servers` conserva la URL `/api` y Swagger funciona
    en ambos casos. Para que la clave desaparezca, como solicita el enunciado,
    es necesario asignar explícitamente una cadena vacía a `ROOT_PATH`.
  ]

  Realizamos una prueba adicional con la variable `ROOT_PATH` definida como una cadena vacía,
  sin cambiar la imagen.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-db -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e ROOT_PATH= -e SEED_DEMO=true catalogo-api:v1
    1719f88754637997ddf4c4e3caa69321ce1f67b6b455ae47871ee35e269ad3e4

    homelab@rp5:~/Documents/catalogo-app$ for i in {1..30}; do if curl -fsS localhost:8000/health 2>/dev/null; then break; fi; sleep 1; done
    {"status":"ok","db":"ok","version":"v1"}

    homelab@rp5:~/Documents/catalogo-app$ docker restart catalogo-frontend
    catalogo-frontend

    homelab@rp5:~/Documents/catalogo-app$ sleep 2

    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/openapi.json | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"servers": d["servers"]}) if "servers" in d else "Clave servers ausente")'
    Clave servers ausente

    ```
  ]

  Al abrir `http://localhost:3000/api/docs` en Chromium con la variable `ROOT_PATH` vacía,
  se observa el siguiente error:

  #comandos[
    ```text
    GET http://localhost:3000/openapi.json
    Swagger UI: Unable to render this definition

    The provided definition does not specify a valid version field.

    Please indicate a valid Swagger or OpenAPI version field. Supported version fields are swagger: "2.0" and openapi: 3.0.x, openapi: 3.1.x, or openapi: 3.2.x (for example, openapi: 3.2.0).

    ```
  ]

  Cuando la variable `ROOT_PATH` está vacía, Swagger solicita `/openapi.json`
  fuera del prefijo `/api/`. Como respuesta, nginx entrega el HTML de la aplicación
  de página única (SPA) mediante su mecanismo de respuesta alternativa (_fallback_),
  en lugar del esquema de FastAPI. La página de Swagger se abre, pero no puede
  interpretar ese HTML como un documento OpenAPI.
  La variable `ROOT_PATH` informa a FastAPI del prefijo público que nginx elimina
  antes de reenviar las peticiones a la API; no modifica la configuración del proxy.

  Restablecemos `ROOT_PATH=/api` y comprobamos la disponibilidad mediante el proxy.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-api --network catalogo-net -p 8000:8000 -e DB_HOST=catalogo-db -e DB_PORT=27017 -e DB_NAME=catalogodb -e DB_USER=catalogo_user -e DB_PASSWORD=catalogo_pass -e APP_VERSION=v1 -e ROOT_PATH=/api -e SEED_DEMO=true catalogo-api:v1
    947445603c34befcd590d6e311dfd65f0f5c0a03c5e21e8dd0577c1aeb137687

    homelab@rp5:~/Documents/catalogo-app$ for i in {1..30}; do if curl -fsS localhost:8000/health 2>/dev/null; then break; fi; sleep 1; done
    {"status":"ok","db":"ok","version":"v1"}

    homelab@rp5:~/Documents/catalogo-app$ docker restart catalogo-frontend
    catalogo-frontend

    homelab@rp5:~/Documents/catalogo-app$ sleep 2; curl -s localhost:3000/api/health
    {"status":"ok","db":"ok","version":"v1"}
    ```
  ]

]

#pagebreak()

#consigna(8)[
  Comprobar la persistencia del dato. Eliminar el contenedor de la base con
  `docker rm -f catalogo-db`, verificar con `docker volume ls` que el volumen persiste, volver a crearlo
  con *las mismas opciones del punto 2*, reiniciar la API y contar nuevamente los documentos
  de la colección. El producto cargado en el punto 6 debe continuar disponible *con su imagen y
  con su identificador original*: los bytes de la imagen residen en el documento de MongoDB
  y no en el disco del contenedor de la API. Ese detalle es lo que mantiene la API sin estado, y
  es la razón por la que en la sexta semana puede escalarse a tres réplicas.

  #resolucion[
    Comprobamos el estado previo: la colección contiene los 12 productos de
    demostración y el producto creado en el punto 6.
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-db mongosh --quiet 'mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb?authSource=admin' --eval 'db.productos.countDocuments({})'
    13

    ```
  ]

  Registramos el identificador original del producto y calculamos la huella SHA-256 de su imagen.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ curl -fsS localhost:3000/api/productos/6ac5bc5bce059c6015706f07
    {"sku":7102026,"nombre":"Producto TP3 Bash con imagen","precio":12345.0,"categoria":"TP3","stock":3,"descripcion":"Verificación de proxy y persistencia desde Chromium.","imagen_tipo":"image/jpeg","imagen_hash":"3926b6235eecc7b3","creado_en":"2026-10-07T03:28:27.265000","id":"6ac5bc5bce059c6015706f07","imagen":true}

    homelab@rp5:~/Documents/catalogo-app$ curl -fsS localhost:3000/api/productos/6ac5bc5bce059c6015706f07/imagen | sha256sum
    3926b6235eecc7b38a957bf98be26644cf73cad42b6d967deaa1ce86d4839a3c  -

    ```
  ]

  Eliminamos el contenedor y verificamos que el volumen nombrado sigue existiendo.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker rm -f catalogo-db
    catalogo-db

    homelab@rp5:~/Documents/catalogo-app$ docker volume ls
    DRIVER    VOLUME NAME
    local     8dbb5fc9bc215afe5a3a5d1418910be2f6829388ddc8066e7343093504e9906b
    local     c0438e22d2bf138e1888a4685f739efeab5691d5056daab1552a5b314f187885
    local     catalogo-db-data

    ```
  ]

  Recreamos el contenedor de MongoDB y montamos el mismo volumen en `/data/db`, con las opciones
  del punto 2. Esperamos a que acepte conexiones y reiniciamos la API.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-db --network catalogo-net -e MONGO_INITDB_ROOT_USERNAME=catalogo_user -e MONGO_INITDB_ROOT_PASSWORD=catalogo_pass -v catalogo-db-data:/data/db mongo:7
    ffc0422e6f53c6da9ade8dc200eda31a1a08838b1658ec445cd7daa63a6696ce

    homelab@rp5:~/Documents/catalogo-app$ sleep 4; docker logs catalogo-db 2>&1 | grep "Waiting for connections"
    {"t":{"$date":"2026-10-07T03:30:28.674+00:00"},"s":"I",  "c":"NETWORK",  "id":23016,   "ctx":"listener","msg":"Waiting for connections","attr":{"port":27017,"ssl":"off"}}

    homelab@rp5:~/Documents/catalogo-app$ docker restart catalogo-api
    catalogo-api

    homelab@rp5:~/Documents/catalogo-app$ for i in {1..30}; do if curl -fsS localhost:8000/health 2>/dev/null; then break; fi; sleep 1; done
    {"status":"ok","db":"ok","version":"v1"}

    ```
  ]

  Repetimos el conteo y las consultas del producto y de su imagen. La colección
  sigue teniendo 13 documentos: la carga inicial de datos es idempotente y el
  producto nuevo se conserva.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-db mongosh --quiet 'mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb?authSource=admin' --eval 'db.productos.countDocuments({})'
    13

    homelab@rp5:~/Documents/catalogo-app$ curl -fsS localhost:3000/api/productos/6ac5bc5bce059c6015706f07
    {"sku":7102026,"nombre":"Producto TP3 Bash con imagen","precio":12345.0,"categoria":"TP3","stock":3,"descripcion":"Verificación de proxy y persistencia desde Chromium.","imagen_tipo":"image/jpeg","imagen_hash":"3926b6235eecc7b3","creado_en":"2026-10-07T03:28:27.265000","id":"6ac5bc5bce059c6015706f07","imagen":true}

    homelab@rp5:~/Documents/catalogo-app$ curl -fsS localhost:3000/api/productos/6ac5bc5bce059c6015706f07/imagen | sha256sum
    3926b6235eecc7b38a957bf98be26644cf73cad42b6d967deaa1ce86d4839a3c  -

    ```
  ]

  Confirmamos que los datos binarios de la imagen están almacenados en el propio documento de MongoDB.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker exec catalogo-db mongosh --quiet 'mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb?authSource=admin' --eval 'const p=db.productos.findOne({sku:7102026}); printjson({id:p._id.toString(),tipo:p.imagen_tipo,bytes:p.imagen_datos.length(),hash:p.imagen_hash})'
    {
      id: '6ac5bc5bce059c6015706f07',
      tipo: 'image/jpeg',
      bytes: 34945,
      hash: '3926b6235eecc7b3'
    }

    ```
  ]

  Al volver a abrir `http://localhost:3000` en Chromium, el producto
  “Producto TP3 Bash con imagen” continúa visible con su imagen después de recrear MongoDB.

  #captura("producto-persistente.jpeg", [
    Vista parcial del catálogo después de recrear MongoDB en la ejecución
    del 4 de octubre. El filtro «Prueba TP3» conserva un producto.
  ], ancho: 45%)

  Comprobamos el estado final de los contenedores y de la API a través del proxy.

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker ps
    CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS                                         NAMES
    ffc0422e6f53   mongo:7                "docker-entrypoint.s…"   16 seconds ago   Up 14 seconds   27017/tcp                                     catalogo-db
    947445603c34   catalogo-api:v1        "uvicorn main:app --…"   48 seconds ago   Up 8 seconds    0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp   catalogo-api
    547af00c8fec   catalogo-frontend:v1   "/docker-entrypoint.…"   6 minutes ago    Up 44 seconds   0.0.0.0:3000->8080/tcp, [::]:3000->8080/tcp   catalogo-frontend

    homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:3000/api/health
    {"status":"ok","db":"ok","version":"v1"}

    ```
  ]

  El identificador, los datos del producto, la cantidad de documentos y la huella
  SHA-256 de la imagen coinciden con los valores registrados antes de recrear el contenedor.
  MongoDB conserva su estado en `catalogo-db-data` aunque se destruya el contenedor.
  La API obtiene las imágenes de los documentos de MongoDB, en lugar de guardarlas
  en el disco de su contenedor. Por eso puede recrearse o replicarse utilizando la misma base de datos,
  sin sincronizar archivos locales entre réplicas.
]

#pagebreak()
#consigna(9)[
  Documentar en el `README.md` el orden de arranque —`red → volumen → base → API → frontend`—
  indicando qué falla exactamente al invertir cada paso, y dejar registrada la
  limitación que se resuelve la semana siguiente: dicho orden reside hoy en la memoria de quien levanta la aplicación y no en ningún archivo ejecutable.

  #resolucion[*Orden de arranque: red → volumen → base → API → frontend.*]

  + Crear `catalogo-net` y `catalogo-db-data`.
  + Iniciar `catalogo-db` con el volumen montado en `/data/db`.
  + Esperar a que MongoDB acepte conexiones y, después, iniciar `catalogo-api`.
  + Comprobar que `/health` devuelva `status=ok` y `db=ok`; luego, iniciar el frontend.
  + Verificar el acceso a `http://localhost:3000` y a `/api/health` a través de nginx.

  #paso[*Qué ocurre al alterar el orden de arranque:*]

  - *Contenedor antes de la red:* el comando que utiliza `--network catalogo-net`
    falla si la red no existe. Si se omite `--network`, el contenedor queda conectado
    a `bridge` y no puede resolver los nombres de los contenedores de `catalogo-net`.
  - *Base antes de crear explícitamente el volumen:* con `-v catalogo-db-data:/data/db`,
    Docker crea automáticamente el volumen si no existe; por lo tanto, ese orden no provoca un fallo.
    Si se omite ese montaje, `mongo:7` usa un volumen anónimo para `/data/db`;
    si se recrea el contenedor sin reutilizar ese volumen, se obtiene una base nueva,
    sin los datos guardados previamente. La red y el volumen son recursos
    independientes, por lo que pueden crearse en cualquier orden.
  - *API antes de la base:* si `catalogo-db` aún no existe, falla la resolución DNS;
    si existe, pero MongoDB todavía no acepta conexiones, falla la conexión al motor.
    La API realiza hasta diez intentos de conexión y puede recuperarse si la base
    queda disponible durante ese período. Si agota los intentos, el arranque falla.
    Que un contenedor figure como `Up` no significa que el servicio esté listo.
  - *Frontend antes de que exista la API en la red:* nginx no resuelve `catalogo-api`
    y termina con `Exited (1)`, como se observó en el punto 5.
    Si el nombre ya se puede resolver, pero la API aún no acepta conexiones, nginx
    puede iniciarse, aunque las solicitudes a `/api/` fallen temporalmente con
    el código de respuesta `502 Bad Gateway`.

  #paso[*Limitación actual:*]

  Este orden, las esperas y las comprobaciones dependen de quien ejecuta los comandos.
  El procedimiento descrito no cuenta con una definición ejecutable del despliegue
  que establezca las dependencias, las comprobaciones de disponibilidad y los
  mecanismos de recuperación. La siguiente etapa automatiza esa coordinación:
  además de ordenar el arranque, es necesario verificar que cada servicio esté
  listo antes de iniciar los que dependen de él.
]
