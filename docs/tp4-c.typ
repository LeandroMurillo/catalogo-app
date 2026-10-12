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
    if it.text.contains("\u{200b}") or it.text.len() < 2 {
      it
    } else {
      let ajustado = it.text.clusters().join("\u{200b}")
      raw(ajustado, block: it.block, lang: it.lang)
    }
  }
  #cuerpo
]

// Consignas transcritas de tp-04-C.pdf, páginas 2 a 4.
#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 4 — Variante C]

  Proyecto: `catalogo-app`
]

= Consignas

#consigna(1)[
  Escribir el `docker-compose.yml` con los tres servicios, reproduciendo exactamente la
  configuración de la semana 3: la red `catalogo-net` y el volumen `catalogo-db-data` —
  ambos con `name:` explícito, para que sean los mismos—, las mismas variables de entorno —
  incluida `ROOT_PATH=/api`— y *la base de datos sin puertos publicados*.

  Antes del primer `docker compose up` corresponde *eliminar los contenedores y la red de
  la semana 3* (`docker rm -f ...` y `docker network rm catalogo-net`). Según la
  versión de Compose, una red que Compose no creó hace *fallar* el `up` (versiones 2.x:
  `network catalogo-net was found but has incorrect label com.docker.compose.network set to ""`)
  o produce *una advertencia* y se reutiliza (versiones más nuevas:
  `a network with name catalogo-net exists but was not created by compose`). Eliminarla
  evita la ambigüedad: la red pasa a quedar a cargo de Compose. El volumen, en cambio, se
  reutiliza con una advertencia y conserva los datos, por lo que no debe eliminarse.
]

#consigna(2)[
  Declarar el healthcheck de `catalogo-db`. El cliente `mongosh` ya viene incluido en la imagen
  `mongo:7`, y `ping` es uno de los pocos comandos que no requieren *autenticación*:

  #comandos[
    ```yaml
    healthcheck:
      test:
        - CMD-SHELL
        - mongosh --quiet --eval "db.adminCommand('ping').ok" || exit 1
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s
    ```
  ]

  Explicar en el `README.md` por qué este healthcheck no lleva credenciales —y por qué eso
  constituye una ventaja frente a la variante B, en la que la contraseña debe viajar en el
  comando— y qué *no verifica*: que `ping` responda no prueba que el usuario `catalogo_user`
  exista ni que la contraseña configurada sea la correcta.
]

#consigna(3)[
  Declarar el healthcheck de `catalogo-api` *sin agregar dependencias* a la imagen. La
  biblioteca `urllib` viene incluida con Python:

  #comandos[
    ```yaml
    test:
      - CMD
      - python
      - -c
      - "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"
    ```
  ]

  Explicar en el `README.md` por qué no corresponde instalar `curl` en la imagen solo para el
  healthcheck.
]

#pagebreak()

#consigna(4)[
  Declarar el healthcheck del frontend con `wget` —incluido en BusyBox, ya presente en Alpine—
  contra la ruta `/healthz`.
]

#consigna(5)[
  Declarar `depends_on` con *condición*, tanto en la API como en el frontend:

  #comandos[
    ```yaml
    depends_on:
      catalogo-db:
        condition: service_healthy
    ```
  ]

  Explicar en el `README.md` los dos casos, que no son equivalentes:

  #incisos(
    [`catalogo-api` respecto de `catalogo-db`: la API debe *conectarse* y sembrar el
      catálogo. La forma corta `depends_on: [catalogo-db]` espera a que el contenedor
      *arranque*, no a que MongoDB *acepte conexiones*. La API, además, reintenta la conexión
      durante unos 30 segundos, que es lo único que subsistirá en Kubernetes, donde no existe
      `depends_on`;],
    [`catalogo-frontend` respecto de `catalogo-api`: lo que no puede faltar es *algún*
      `depends_on`. Sin él, el frontend arranca antes que la API, nginx no resuelve el _upstream_
      y termina con `host not found in upstream`. A nginx le basta con que el nombre
      resuelva —la forma corta también funciona—; `service_healthy` hace además que
      arranque con la API ya en funcionamiento, sin respuestas `502` en los primeros segundos.],
  )
]

#consigna(6)[
  Validar el archivo antes de levantar el proyecto y verificar que los tres servicios alcanzan el
  estado `healthy`:

  #comandos[
    ```text
    docker compose config
    docker compose up --build -d
    docker compose ps
    docker compose logs -f catalogo-api
    ```
  ]
]

#consigna(7)[
  Comprobar el ciclo de vida completo de los datos:

  #comandos[
    ```text
    docker compose down
    docker compose up -d
    curl -s localhost:3000/api/productos | head -c 300
    docker compose down -v
    ```
  ]

  Documentar la diferencia entre `down` y `down -v`. Se recomienda ejecutar el `down -v` al final,
  o sobre una copia, si se desea conservar el catálogo de las semanas anteriores.
]

#consigna(8)[
  Comprobar que la siembra de datos es idempotente. Con la base ya poblada, ejecutar
  `docker compose up -d --force-recreate catalogo-api` y volver a contar los productos: la
  cantidad *no debe duplicarse*. La siembra realiza un _upsert_ por nombre a propósito, porque en
  la semana 6 arrancarán tres réplicas de la API al mismo tiempo y las tres ejecutarán la
  siembra.
]

#pagebreak()

#consigna(9)[
  Escribir un archivo `.env.example` con el contrato *completo* de variables de las tres capas,
  con comentarios que indiquen qué componente consume cada una, y confirmar que `.env`
  figura en el `.gitignore`. Si se opta por la variable `MONGO_URI` en lugar de las variables
  `DB_*` por separado, dejar asentado que esa cadena contiene la contraseña y que, por lo tanto,
  deberá ubicarse *completa* en el Secret de la semana 7, nunca en un ConfigMap.
]

#consigna(10)[
  Realizar una revisión de seguridad y registrarla en una tabla del `README.md`:

  #incisos(
    [el usuario con el que se ejecuta cada contenedor (`docker compose exec catalogo-api id`,
      `docker compose exec catalogo-frontend id`); las dos imágenes propias deben
      informar un usuario *distinto de root*;],
    [qué servicios publican puertos, según `docker compose ps`, verificando que la base de
      datos no publica ninguno;],
    [que `catalogo-api` publica el puerto `8000` *solo con fines de depuración*, y que en la
      semana 6 pasará a ser interno;],
    [el resultado del escaneo de vulnerabilidades de las dos imágenes propias con Trivy
      ejecutado como contenedor —`docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image catalogo-api:v1`—,
      o con `docker scout cves` si se dispone de Docker Desktop, indicando cuántas
      vulnerabilidades provienen del *sistema base*, cuántas de las *dependencias de Python*
      y cuántas tienen una versión corregida (`Fixed Version`).],
  )
]

#consigna(11)[
  Aplicar el principio de mínimo privilegio. Agregar `cap_drop: [ALL]` a los tres servicios y
  levantar el proyecto. Las dos imágenes propias deben continuar en funcionamiento, ya que no
  se ejecutan como `root` y no necesitan ninguna _capability_. El servicio `catalogo-db`, en
  cambio, terminará: registrar el error que muestra `docker compose logs catalogo-db` y
  agregarle mediante `cap_add` *solo* las _capabilities_ que necesita, de a una y leyendo el error en
  cada paso, hasta que alcance el estado `healthy`. Documentar en el `README.md` la lista final y
  por qué la base de datos requiere _capabilities_ y las otras dos capas no.
]

#consigna(12)[
  Incorporar al `README.md` una sección que compare el `docker-compose.yml` con los tres
  `docker run` de la semana 3, indicando qué desapareció y qué apareció.
]
