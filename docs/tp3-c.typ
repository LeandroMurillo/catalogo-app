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

#let comandos(cuerpo) = block(
  width: 100%, inset: 6pt,
  fill: rgb("#F4F4F4"), stroke: 0.6pt + rgb("#CCCCCC"),
  radius: 1.5pt, breakable: false,
)[
  #set par(justify: false, leading: 6.9pt, spacing: 0pt)
  #show raw: set text(font: "Liberation Mono", size: 8.1pt)
  #cuerpo
]


// La fuente se conserva intacta. Se usa la ejecucion completa del 04/10/2026.
#let registro = read("evidence/tp3.txt")
#let entradas = registro.split("PS> Write-Output \"TP3 - Nueva ejecucion completa").at(1).split("\nPS> ").slice(1)
#assert(entradas.len() >= 80, message: "El registro TP3 no contiene todas las evidencias esperadas.")

#let evidencia(titulo, indices) = {
  block(above: 12pt, below: 5pt, sticky: true)[
    #text(size: 10pt, weight: "bold")[#titulo]
  ]
  for i in indices {
    let contenido = "PS> " + entradas.at(i).trim()
    // Puntos de corte invisibles: permiten ajustar JSON, URLs e identificadores
    // largos al ancho de pagina sin omitir caracteres del registro original.
    let ajustado = contenido.clusters().join("\u{200b}")
    block(
      width: 100%, inset: 8pt,
      fill: rgb("#F4F4F4"), stroke: 0.5pt + rgb("#CCCCCC"),
      radius: 2pt, breakable: true, above: 4pt, below: 5pt,
    )[
      #set par(justify: false, leading: 3pt, spacing: 0pt)
      #show raw: set text(font: "Liberation Mono", size: 8pt)
      #raw(ajustado, block: true, lang: "text")
    ]
  }
}

#let captura(archivo, leyenda) = figure(
  // Las capturas originales tienen contenido JPEG y extension .png.
  image(read("evidence/tp3/" + archivo, encoding: none), format: "jpg", width: 100%),
  caption: leyenda,
)

// Consignas transcritas de tp-03-C.pdf, páginas 2 a 5.
#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 3 — Variante C]

  Proyecto: `catalogo-app`
]

Fuente de las evidencias: `docs/evidence/tp3.txt`. Ejecución del 4 de octubre
 de 2026, de 15:33 a 15:37 (UTC−3). Se reproducen los comandos y las salidas
 de esa sesión; los intentos anteriores permanecen en el registro original.
 Las líneas largas se ajustan al ancho de página. Las justificaciones siguen pendientes.

= Consignas

#consigna(1)[
  Crear la red y el volumen con los nombres estándar de la variante, y registrar la salida de
  `docker network ls` y `docker volume ls`:

  #comandos[
    ```text
    docker network create catalogo-net
    docker volume create catalogo-db-data
    ```
  ]

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

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker run -d --name catalogo-db --network catalogo-net -e MONGO_INITDB_ROOT_USERNAME=catalogo_user -e MONGO_INITDB_ROOT_PASSWORD=catalogo_pass -v catalogo-db-data:/data/db mongo:7
    cd59c9d7d1bbcd2ff291a9ddedcb4ff08f5c65498f074389fe3e8bdb03a6d45a
    ```
  ]

  #comandos[
    ```text
    homelab@rp5:~/Documents/catalogo-app$ docker logs catalogo-db 2>&1 | grep "Waiting for connections"
    {"t":{"$date":"2026-10-06T23:00:45.520+00:00"},"s":"I",  "c":"NETWORK",  "id":23016,   "ctx":"listener","msg":"Waiting for connections","attr":{"port":27017,"ssl":"off"}}
    ```
  ]
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

  El valor `DB_HOST=catalogo-db` es un *nombre*, no una dirección IP: lo resuelve el servidor
  DNS interno de la red. En la red `bridge` predeterminada esa resolución no funcionaría.
]

#evidencia("Arranque de la API y resolución del nombre — inciso a", (12, 13, 16))
#evidencia("Estado de la API — inciso b", (17,))
#evidencia("Productos sembrados y cantidad — inciso c", (18, 19))

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

  Restablecer luego la API con la configuración correcta.
]

#evidencia("Nombre de base incorrecto — inciso a", (21, 22, 23))
#evidencia("Conexión sin authSource — inciso b", (25,))
#evidencia("Restablecimiento de la API", (26, 27))
#text(style: "italic")[Inciso c: explicación pendiente.]

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
]

#evidencia("Frontend fuera de catalogo-net", (29, 30, 31))

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
]

#evidencia("Frontend conectado a catalogo-net", (33, 34, 35))
#evidencia("Producto creado desde el navegador", (36, 37))
#text(style: "italic")[Pendiente: captura de Network en DevTools. La evidencia disponible corresponde al registro de nginx.]
#evidencia("Solicitudes registradas en nginx", (38, 39))

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

  Ese documento `openapi.json` es el que consume la interfaz de documentación automática:
  sin el prefijo declarado, las direcciones que genera no contemplan el `/api` y la página no
  funciona a través del _proxy_.
]

#evidencia("Consulta directa y mediante el proxy — inciso a", (41, 42))
#evidencia("OpenAPI con ROOT_PATH=/api — inciso b", (44, 45, 46, 47))
#captura("docs-con-root-path.png", [Documentación con ROOT_PATH=/api.])
#evidencia("API con ROOT_PATH omitida — inciso c", (49, 50, 51, 52, 53, 54, 55))
#captura("docs-variable-omitida.png", [Documentación con la variable ROOT_PATH omitida.])
#text(style: "italic")[Resultado registrado: la clave servers conserva /api en ambos casos. La explicación del inciso d queda pendiente.]
#evidencia("Restablecimiento de ROOT_PATH=/api", (56, 57))

#pagebreak()

#consigna(8)[
  Comprobar la persistencia del dato. Eliminar el contenedor de la base con
  `docker rm -f catalogo-db`, verificar con `docker volume ls` que el volumen persiste, volver a crearlo
  con *las mismas opciones del punto 2*, reiniciar la API y contar nuevamente los documentos
  de la colección. El producto cargado en el punto 6 debe continuar disponible *con su imagen y
  con su identificador original*: los bytes de la imagen residen en el documento de MongoDB
  y no en el disco del contenedor de la API. Ese detalle es lo que mantiene la API sin estado, y
  es la razón por la que en la sexta semana puede escalarse a tres réplicas.
]

#evidencia("Antes de recrear MongoDB", (59, 60, 61, 62))
#evidencia("Eliminación y recreación del contenedor", (63, 64, 65, 66, 67))
#evidencia("Documentos e imagen después de recrear MongoDB", (68, 69, 70, 71, 72))
#evidencia("Comprobación final de la aplicación", (73, 74, 75, 76))
#consigna(9)[
  Documentar en el `README.md` el orden de arranque —`red → volumen → base → API → frontend`—
  indicando qué falla exactamente al invertir cada paso, y dejar registrada la
  limitación que se resuelve la semana siguiente: dicho orden reside hoy en la memoria de
  quien levanta la aplicación y no en ningún archivo ejecutable.
]

#text(style: "italic")[Pendiente de redacción. El registro no contiene una justificación para esta consigna.]
