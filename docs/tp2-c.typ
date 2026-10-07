#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2cm),
  footer: context {
    set text(font: "Liberation Sans", size: 8.5pt)
    set par(justify: false, leading: 5pt, spacing: 0pt)

    block(
      width: 100%,
      stroke: (top: 0.7pt),
      inset: (top: 3pt),
    )[
      #grid(
        columns: (1fr, auto),
        align: (left, right + bottom),
        [
          Contenedores, Docker y Orquestación con Kubernetes \
          FACET – UNT
        ],
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

#let completar(texto: "COMPLETAR ACÁ") = block(
  width: 100%,
  inset: 10pt,
  stroke: 0.6pt + rgb("#BBBBBB"),
  radius: 3pt,
)[
  #text(fill: rgb("#777777"), style: "italic")[#texto]
]

#let consola(titulo, cuerpo, lenguaje: none) = block(
  width: 100%,
  inset: 0pt,
  fill: rgb("#121314"),
  stroke: 0.8pt + rgb("#444444"),
  radius: 6pt,
  breakable: true,
)[
  #set block(spacing: 0pt)
  #block(
    width: 100%,
    inset: (x: 10pt, y: 6pt),
    fill: rgb("#242526"),
  )[
    #text(fill: white, weight: "bold", size: 9pt)[#titulo]
  ]
  #block(
    width: 100%,
    inset: (x: 10pt, y: 6pt),
  )[
    #set par(justify: false, leading: 0.5em, spacing: 0pt)
    #show raw: set text(font: "Liberation Mono", size: 9pt)
    #set text(
      font: "Liberation Mono",
      size: 9pt,
      fill: rgb("#C9D1D9"),
    )
    #if type(cuerpo) == str {
      raw(
        cuerpo,
        block: true,
        lang: lenguaje,
        syntaxes: "dockerfile-vscode.sublime-syntax",
        theme: "vscode-dark.tmTheme",
      )
    } else {
      cuerpo
    }
    #v(1em, weak: false)
  ]
]

#let consigna(numero, cuerpo) = {
  // Mantiene los marcadores del PDF sin mostrar otro título en la página.
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
  inset: 6pt,
  fill: rgb("#F4F4F4"),
  stroke: 0.6pt + rgb("#CCCCCC"),
  radius: 1.5pt,
  breakable: false,
)[
  #set par(justify: false, leading: 6.9pt, spacing: 0pt)
  #show raw: set text(font: "Liberation Mono", size: 8.1pt)
  #cuerpo
]

#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 2 — Variante C]

  Proyecto: `catalogo-app`
]

= Consignas

#consigna(1)[
  *La imagen de la API (`backend/Dockerfile`).* Escribir un primer `Dockerfile` *ingenuo* —
  una sola etapa, base `python:3.12` completa, `COPY . .` seguido de `pip install -r requirements.txt`—
  y medirlo. Registrar la salida de `docker build` y de `docker images catalogo-api`.
  El valor obtenido, que supera el gigabyte, es el punto de comparación de todo el práctico.

  #consola("backend/Dockerfile.naive", read("../backend/Dockerfile.naive"), lenguaje: "dockerfile")

  #consola(
    "PowerShell — docker build",
    [
      ```text
      PS catalogo-app> docker build -f backend/Dockerfile.naive `
      >>   -t catalogo-api:naive ./backend

      ...
      => exporting to image
      => => naming to docker.io/library/catalogo-api:naive
      ```
    ],
  )
]

#consigna(2)[
  Escribir la versión definitiva, *multi-etapa*, con los siguientes requisitos, que no son sugerencias:

  #incisos(
    [una etapa `builder` que ejecute `pip install --user --no-cache-dir -r requirements.txt`.
      El parámetro `--user` deja todo lo instalado en un único directorio, que es lo único que la etapa final necesita copiar;],
    [el `COPY` de `requirements.txt` *antes* que el código, de modo que la capa de instalación salga del cache cuando el manifiesto no cambie;],
    [una etapa final con base mínima (`python:3.12-slim`), el `COPY --from=builder` del directorio de dependencias y la variable `PATH` ajustada para que los ejecutables instalados —`uvicorn` entre ellos— resulten localizables;],
    [*usuario no privilegiado creado explícitamente* con `useradd`: a diferencia de la imagen de Node, la de Python no provee ninguno;],
    [`ENV PYTHONUNBUFFERED=1`, sin la cual la salida del proceso queda en el búfer y `docker logs` no muestra nada;],
    [`ARG APP_VERSION=v1` junto con `ENV APP_VERSION=${APP_VERSION}`;],
    [`EXPOSE 8000` y `CMD` en forma de lista, *incluyendo `--host 0.0.0.0`* (véanse las advertencias).],
  )

  #consola("backend/Dockerfile", read("../backend/Dockerfile"), lenguaje: "dockerfile")
]

#consigna(3)[
  Crear el archivo `backend/.dockerignore` con `__pycache__`, `.git`, `.env`, `*.pyc` y
  `.venv`. Sin él, el entorno virtual de la máquina local viaja al contexto de build.
]

#consigna(4)[
  Construir las dos versiones y comprobar que la variable de versión se hornea efectivamente:

  #comandos[
    ```text
    docker build -t catalogo-api:v1 ./backend
    docker build --build-arg APP_VERSION=v2 -t catalogo-api:v2 ./backend
    docker run --rm --entrypoint sh catalogo-api:v2 -c 'echo $APP_VERSION' # debe
    imprimir v2
    ```
  ]

  Si la segunda imagen imprime `v1`, falta la instrucción `ENV`: `ARG` existe *solo durante la construcción*.
  Sin esto, la actualización progresiva de la sexta semana no mostraría ningún cambio observable.
]

#consigna(5)[
  *La imagen del frontend (`frontend/Dockerfile`).* Escribir un *multi-etapa fuerte*: una
  etapa de construcción con `node:20-alpine` que ejecute `npm ci` y `npm run build`, y una
  etapa final con `nginxinc/nginx-unprivileged:1.27-alpine` que reciba *solo* el
  directorio `dist/`. En la imagen final no puede quedar Node, ni npm, ni `node_modules`, ni el código fuente.
]

#consola("frontend/Dockerfile", read("../frontend/Dockerfile"), lenguaje: "dockerfile")

#consigna(6)[
  Declarar en el `Dockerfile` del frontend la configuración que nginx resolverá *al arrancar*,
  no durante la construcción:

  #comandos[
    ```text
    ENV API_HOST=catalogo-api \
        API_PORT=8000 \
        NGINX_ENVSUBST_FILTER=^API_
    ```
  ]

  La variable `NGINX_ENVSUBST_FILTER` *no es opcional*: sin ella, la sustitución alcanza
  también a las variables propias de nginx (`$uri`, `$host`, `$proxy_add_x_forwarded_for`),
  que quedan vacías y generan una configuración *inválida en silencio*. Corresponde dejar
  registrada esa explicación en el `README.md`.
]

#consigna(7)[
  Verificar las tres propiedades de la imagen del frontend, registrando la salida de cada comando:

  #incisos(
    [`docker run --rm catalogo-frontend:v1 whoami` — debe informar un usuario distinto de `root`;],
    [`docker run --rm catalogo-frontend:v1 node --version` — *debe fallar*. Ese fallo es la evidencia de que la construcción multi-etapa funcionó;],
    [`docker images catalogo-frontend` — el tamaño resultante.],
  )
]

#consigna(8)[
  *Medición.* Elaborar en el `README.md` una tabla comparativa entre la versión ingenua de la
  API, la versión definitiva y la imagen del frontend, con tamaño, imagen base y *porcentaje de
  reducción*, acompañada de una línea por cada decisión que explique qué aportó.
]

#consigna(9)[
  Registrar la salida de `docker history catalogo-api:v1`, identificar la capa que aporta
  la mayor parte del tamaño y explicar a qué corresponde. Se sugiere filtrar las capas de `0B`.
]

#consigna(10)[
  Demostrar el efecto del cache de construcción: modificar el contenido de un archivo de
  código, reconstruir y comprobar en la salida que la instalación de dependencias aparece como
  `CACHED`. Repetir la operación modificando `requirements.txt` y comparar. Explicar en dos
  líneas por qué el orden de las instrucciones lo hace posible.
]

#consigna(11)[
  Publicar *ambas* imágenes en Docker Hub con el usuario propio (`docker tag` seguido de
  `docker push`), documentando los comandos y los nombres completos. Serán necesarias en
  la quinta semana, cuando el clúster deba poder descargarlas.
]
