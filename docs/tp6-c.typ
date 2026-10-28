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

// Separador entre el enunciado y la resolución de cada consigna.
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

// Capturas con una leyenda separada del texto principal.
#show figure: set block(below: 20pt)
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
    if it.text.contains("\u{200b}") or it.text.len() < 2 {
      it
    } else {
      let ajustado = it.text.clusters().join("\u{200b}")
      raw(ajustado, block: it.block, lang: it.lang)
    }
  }
  #cuerpo
]

// Consignas transcritas de tp-06-C.pdf, páginas 2 y 3.
#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 6 — Variante C]

  Proyecto: `catalogo-app`
]

= Consignas

#consigna(1)[
  Escribir tres Services y tres Deployments con el siguiente reparto de tipos y réplicas:

  #table(
    columns: (1.25fr, 1.4fr, 0.7fr, 2.5fr),
    align: (left, left, left, left),
    inset: 5pt,
    stroke: 0.6pt + rgb("#999999"),
    table.header(
      [*Objeto*],
      [*Tipo de Service*],
      [*Réplicas*],
      [*Justificación*],
    ),
    [`catalogo-db`],
    [`ClusterIP`],
    [1],
    [La base de datos no se expone hacia afuera.],
    [`catalogo-api`],
    [`ClusterIP`],
    [2],
    [Su único cliente es el frontend, desde adentro del clúster.],
    [`catalogo-frontend`],
    [`NodePort 30302 → 8080`],
    [2],
    [Es el único punto de entrada de la aplicación.],
  )
]

#consigna(2)[
  Aplicar los Services *antes* que los Deployments:

  #comandos[
    ```text
    kubectl apply -f k8s/svc-catalogo-db.yaml
    kubectl apply -f k8s/svc-catalogo-api.yaml
    kubectl apply -f k8s/svc-catalogo-frontend.yaml
    kubectl apply -f k8s/deploy-catalogo-db.yaml
    kubectl apply -f k8s/deploy-catalogo-api.yaml
    kubectl apply -f k8s/deploy-catalogo-frontend.yaml
    ```
  ]

  El nombre DNS de un Service existe desde que se crea el objeto, aun sin Pods detrás. Si el
  frontend arranca antes de que exista el Service `catalogo-api`, nginx no resuelve el _upstream_
  y termina. Se solicita *provocar ese error una vez* —aplicando el Deployment del frontend con
  el Service de la API eliminado—, registrar el mensaje y luego aplicar en el orden correcto.
]

/* Registro original de terminal, conservado como fuente para la resolución editada.
homelab@rp5:~/Documents/catalogo-app$ kubectl get service catalogo-api -n catalogo-app
Error from server (NotFound): services "catalogo-api" not found
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-frontend.yaml
deployment.apps/catalogo-frontend created
homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -l app=catalogo-frontend -n catalogo-app -w
NAME                                 READY   STATUS              RESTARTS   AGE
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     ContainerCreating   0          7s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     ContainerCreating   0          7s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     ContainerCreating   0          18s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     ContainerCreating   0          18s
catalogo-frontend-7c84f6c9c8-v64rt   1/1     Running             0          24s
catalogo-frontend-7c84f6c9c8-ndnfr   1/1     Running             0          28s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     Error               0          39s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     Error               0          40s
catalogo-frontend-7c84f6c9c8-v64rt   1/1     Running             1 (11s ago)   44s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     Error               1 (15s ago)   48s
catalogo-frontend-7c84f6c9c8-ndnfr   1/1     Running             1 (16s ago)   49s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     Error               1 (18s ago)   51s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     CrashLoopBackOff    1 (13s ago)   54s
catalogo-frontend-7c84f6c9c8-v64rt   1/1     Running             2 (19s ago)   60s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     CrashLoopBackOff    1 (18s ago)   61s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     Error               2 (21s ago)   62s
catalogo-frontend-7c84f6c9c8-ndnfr   1/1     Running             2 (27s ago)   70s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     Error               2 (31s ago)   74s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     CrashLoopBackOff    2 (24s ago)   80s
catalogo-frontend-7c84f6c9c8-v64rt   1/1     Running             3 (31s ago)   87s
catalogo-frontend-7c84f6c9c8-v64rt   0/1     Error               3 (33s ago)   89s
catalogo-frontend-7c84f6c9c8-ndnfr   0/1     CrashLoopBackOff    2 (26s ago)   90s
^Chomelab@rp5:~/Documents/catalogo-appkubectl logs -l app=catalogo-frontend -n catalogo-app --prefix --tail=50 | tee /tmp/tp6-punto2-error.txt
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] 10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] 10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf differs from the packaged version
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] 20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/default.conf.template to /etc/nginx/conf.d/default.conf
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] /docker-entrypoint.sh: Configuration complete; ready for start up
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] 2026/10/26 21:02:41 [emerg] 1#1: host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
[pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] nginx: [emerg] host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] 10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] 10-listen-on-ipv6-by-default.sh: info: /etc/nginx/conf.d/default.conf differs from the packaged version
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] 20-envsubst-on-templates.sh: Running envsubst on /etc/nginx/templates/default.conf.template to /etc/nginx/conf.d/default.conf
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] /docker-entrypoint.sh: Configuration complete; ready for start up
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] 2026/10/26 21:02:35 [emerg] 1#1: host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
[pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] nginx: [emerg] host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
homelab@rp5:~/Documents/catalogo-app$ kubectl delete deployment catalogo-frontend -n catalogo-app
kubectl wait --for=delete pod -l app=catalogo-frontend -n catalogo-app --timeout=90s
deployment.apps "catalogo-frontend" deleted from catalogo-app namespace
pod/catalogo-frontend-7c84f6c9c8-ndnfr condition met
pod/catalogo-frontend-7c84f6c9c8-v64rt condition met
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-db.yaml
service/catalogo-db created
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-api.yaml
service/catalogo-api created
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-frontend.yaml
service/catalogo-frontend created
homelab@rp5:~/Documents/catalogo-app$ kubectl get services -n catalogo-app
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
catalogo-api        ClusterIP   10.103.4.218    <none>        8000/TCP         15s
catalogo-db         ClusterIP   10.107.179.60   <none>        27017/TCP        23s
catalogo-frontend   NodePort    10.100.153.25   <none>        8080:30302/TCP   7s
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-db.yaml
deployment.apps/catalogo-db created
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-api.yaml
deployment.apps/catalogo-api created
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-frontend.yaml
deployment.apps/catalogo-frontend created
homelab@rp5:~/Documents/catalogo-app$ kubectl get services -n catalogo-app
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
catalogo-api        ClusterIP   10.103.4.218    <none>        8000/TCP         16m
catalogo-db         ClusterIP   10.107.179.60   <none>        27017/TCP        16m
catalogo-frontend   NodePort    10.100.153.25   <none>        8080:30302/TCP   16m
homelab@rp5:~/Documents/catalogo-app$ kubectl get deployments -n catalogo-app
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
catalogo-api        2/2     2            2           16m
catalogo-db         1/1     1            1           16m
catalogo-frontend   2/2     2            2           15m
homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -l 'app in (catalogo-db,catalogo-api,catalogo-frontend)' -n catalogo-app -o wide
NAME                                 READY   STATUS    RESTARTS        AGE   IP            NODE       NOMINATED NODE   READINESS GATES
catalogo-api-9c5f8646d-4xc5b         1/1     Running   2 (7m13s ago)   16m   10.244.0.28   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75         1/1     Running   1 (12m ago)     16m   10.244.0.29   lmurillo   <none>           <none>
catalogo-db-654f9f8fdc-nxl6q         1/1     Running   0               16m   10.244.0.27   lmurillo   <none>           <none>
catalogo-frontend-7c84f6c9c8-sp9gs   1/1     Running   0               16m   10.244.0.31   lmurillo   <none>           <none>
catalogo-frontend-7c84f6c9c8-xdb2b   1/1     Running   0               16m   10.244.0.30   lmurillo   <none>           <none>
homelab@rp5:~/Documents/catalogo-app$
*/

#resolucion[
  Primero se reprodujo de manera controlada el problema de orden solicitado por la consigna. Se
  comprobó que el Service `catalogo-api` no existía y se creó únicamente el Deployment del
  frontend. De ese modo, sus dos réplicas arrancaron sin que Kubernetes hubiera publicado el
  nombre DNS que nginx usa como _upstream_.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get service catalogo-api -n catalogo-app
  Error from server (NotFound): services "catalogo-api" not found
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply \
    -f k8s/deploy-catalogo-frontend.yaml
  deployment.apps/catalogo-frontend created
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-frontend -n catalogo-app -w
  NAME                                 READY   STATUS             RESTARTS   AGE
  catalogo-frontend-7c84f6c9c8-ndnfr   1/1     Running            0          28s
  catalogo-frontend-7c84f6c9c8-ndnfr   0/1     Error              0          39s
  catalogo-frontend-7c84f6c9c8-v64rt   0/1     Error              0          40s
  catalogo-frontend-7c84f6c9c8-v64rt   0/1     CrashLoopBackOff   1          54s
  catalogo-frontend-7c84f6c9c8-ndnfr   0/1     CrashLoopBackOff   1          61s
  ^C
  ```
]

Los contenedores llegaron brevemente a `Running`, pero nginx terminó durante su inicialización y
el kubelet intentó reiniciarlos. Después de varios fallos Kubernetes aplicó una espera progresiva,
representada por `CrashLoopBackOff`. Los logs de ambas réplicas confirmaron la causa concreta:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl logs \
    -l app=catalogo-frontend -n catalogo-app --prefix --tail=50
  [pod/catalogo-frontend-7c84f6c9c8-ndnfr/catalogo-frontend] \
  nginx: [emerg] host not found in upstream "catalogo-api" in \
  /etc/nginx/conf.d/default.conf:24
  [pod/catalogo-frontend-7c84f6c9c8-v64rt/catalogo-frontend] \
  nginx: [emerg] host not found in upstream "catalogo-api" in \
  /etc/nginx/conf.d/default.conf:24
  ```
]

El mensaje `host not found in upstream` demuestra que el fallo ocurre durante la resolución DNS,
antes de que nginx pueda atender solicitudes. Un Deployment crea y mantiene Pods, pero no crea por
sí mismo un nombre estable para acceder a otra carga. Ese nombre lo aporta el Service. Por eso no
bastaría con que alguna réplica de la API estuviera arrancando: el objeto Service debe existir
antes de iniciar nginx.

Se eliminó el Deployment usado en la prueba y se esperó la desaparición de sus Pods para evitar
que las réplicas fallidas se mezclaran con el despliegue definitivo.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete deployment \
    catalogo-frontend -n catalogo-app
  deployment.apps "catalogo-frontend" deleted from catalogo-app namespace
  homelab@rp5:~/Documents/catalogo-app$ kubectl wait --for=delete pod \
    -l app=catalogo-frontend -n catalogo-app --timeout=90s
  pod/catalogo-frontend-7c84f6c9c8-ndnfr condition met
  pod/catalogo-frontend-7c84f6c9c8-v64rt condition met
  ```
]

A continuación se aplicaron primero los tres Services. `catalogo-db` y `catalogo-api` son
`ClusterIP` porque solo reciben tráfico interno del clúster. `catalogo-frontend` es `NodePort`
porque constituye el punto de entrada desde el exterior y publica el puerto `30302` del nodo hacia
el puerto `8080` del contenedor.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-db.yaml
  service/catalogo-db created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-api.yaml
  service/catalogo-api created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/svc-catalogo-frontend.yaml
  service/catalogo-frontend created
  homelab@rp5:~/Documents/catalogo-app$ kubectl get services -n catalogo-app
  NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
  catalogo-api        ClusterIP   10.103.4.218    <none>        8000/TCP
  catalogo-db         ClusterIP   10.107.179.60   <none>        27017/TCP
  catalogo-frontend   NodePort    10.100.153.25   <none>        8080:30302/TCP
  ```
]

Aunque todavía no hubiera Pods detrás, desde ese momento los nombres `catalogo-db`,
`catalogo-api` y `catalogo-frontend` ya estaban registrados en el DNS interno. Luego se aplicaron
los Deployments en el orden de dependencia: base de datos, API y frontend.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-db.yaml
  deployment.apps/catalogo-db created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/deploy-catalogo-api.yaml
  deployment.apps/catalogo-api created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply \
    -f k8s/deploy-catalogo-frontend.yaml
  deployment.apps/catalogo-frontend created
  ```
]

La verificación final mostró la cantidad solicitada de réplicas disponibles: una para MongoDB,
dos para la API y dos para el frontend. La selección por la label `app` excluyó además los Pods
sueltos conservados de la semana anterior, ya que estos usan la label `run` y no forman parte de
los Deployments nuevos.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get deployments -n catalogo-app
  NAME                READY   UP-TO-DATE   AVAILABLE
  catalogo-api        2/2     2            2
  catalogo-db         1/1     1            1
  catalogo-frontend   2/2     2            2
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l 'app in (catalogo-db,catalogo-api,catalogo-frontend)' \
    -n catalogo-app -o wide
  NAME                                 READY   STATUS    RESTARTS   IP
  catalogo-api-9c5f8646d-4xc5b         1/1     Running   2          10.244.0.28
  catalogo-api-9c5f8646d-d2d75         1/1     Running   1          10.244.0.29
  catalogo-db-654f9f8fdc-nxl6q         1/1     Running   0          10.244.0.27
  catalogo-frontend-7c84f6c9c8-sp9gs   1/1     Running   0          10.244.0.31
  catalogo-frontend-7c84f6c9c8-xdb2b   1/1     Running   0          10.244.0.30
  ```
]


#consigna(3)[
  Verificar que los selectors vinculan efectivamente a cada Service con sus Pods mediante
  `kubectl get endpoints -n catalogo-app`, y registrar la salida en el `README.md`. Un Service
  cuyo selector no coincide con ninguna label se crea sin error, pero muestra `<none>` en la
  columna ENDPOINTS.
]

#resolucion[
  Se compararon los selectors de los Services con las labels de los Pods creados por cada
  Deployment. Los tres Services seleccionan por la clave `app`, cuyo valor identifica a la capa
  correspondiente. Las labels adicionales `pod-template-hash` distinguen el ReplicaSet de origen,
  pero no intervienen en la selección del Service.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get services \
    -n catalogo-app \
    -o custom-columns='SERVICE:.metadata.name,SELECTOR:.spec.selector'
  SERVICE             SELECTOR
  catalogo-api        map[app:catalogo-api]
  catalogo-db         map[app:catalogo-db]
  catalogo-frontend   map[app:catalogo-frontend]
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l 'app in (catalogo-db,catalogo-api,catalogo-frontend)' \
    -n catalogo-app --show-labels
  NAME                                 READY   STATUS    LABELS
  catalogo-api-9c5f8646d-4xc5b         1/1     Running   app=catalogo-api,...
  catalogo-api-9c5f8646d-d2d75         1/1     Running   app=catalogo-api,...
  catalogo-db-654f9f8fdc-nxl6q         1/1     Running   app=catalogo-db,...
  catalogo-frontend-7c84f6c9c8-sp9gs   1/1     Running   app=catalogo-frontend,...
  catalogo-frontend-7c84f6c9c8-xdb2b   1/1     Running   app=catalogo-frontend,...
  ```
]

La consulta de endpoints confirmó que cada coincidencia entre selector y label se tradujo en una
dirección de destino. MongoDB expuso un endpoint porque tiene una réplica; la API y el frontend
expusieron dos cada uno, de acuerdo con sus respectivos Deployments. Los puertos `27017`, `8000` y
`8080` también coincidieron con los `targetPort` declarados en los Services.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get endpoints \
    -n catalogo-app -o wide
  Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
  NAME                ENDPOINTS
  catalogo-api        10.244.0.28:8000,10.244.0.29:8000
  catalogo-db         10.244.0.27:27017
  catalogo-frontend   10.244.0.30:8080,10.244.0.31:8080
  ```
]

Ningún Service mostró `<none>`, por lo que todos encontraron Pods elegibles y listos. Si un
selector no coincidiera con ninguna label, Kubernetes permitiría crear el Service, pero este no
tendría destinos a los cuales reenviar tráfico. Las IP observadas pertenecen a Pods y pueden
cambiar cuando estos se recrean; los consumidores deben usar el nombre DNS estable del Service.

La advertencia no representa un error en la comprobación: `Endpoints` continúa disponible, aunque
la API actual recomienda `EndpointSlice`. La consulta equivalente mostró las mismas direcciones y
puertos en el recurso moderno:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get endpointslices -n catalogo-app
  NAME                      ADDRESSTYPE   PORTS   ENDPOINTS
  catalogo-api-2vcn6        IPv4          8000    10.244.0.28,10.244.0.29
  catalogo-db-6dgnx         IPv4          27017   10.244.0.27
  catalogo-frontend-g87bz   IPv4          8080    10.244.0.31,10.244.0.30
  ```
]

#consigna(4)[
  Acceder a la aplicación en `http://<IP-del-nodo>:30302` y cargar un producto *con imagen*.
]

#resolucion[
  Se obtuvo la dirección interna del único nodo y se comprobó la publicación del frontend. El
  Service `catalogo-frontend` es `NodePort`: recibe conexiones en el puerto `30302` de
  `172.16.20.19` y las reenvía al puerto `8080` de sus Pods. Por eso la aplicación queda accesible
  desde la red local mediante `http://172.16.20.19:30302`.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get nodes -o wide
  NAME       STATUS   ROLES           VERSION   INTERNAL-IP    EXTERNAL-IP
  lmurillo   Ready    control-plane   v1.37.1   172.16.20.19   <none>
  homelab@rp5:~/Documents/catalogo-app$ kubectl get service \
    catalogo-frontend -n catalogo-app
  NAME                TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
  catalogo-frontend   NodePort   10.100.153.25   <none>        8080:30302/TCP
  ```
]

Antes de usar la interfaz se realizó una solicitud HTTP al NodePort. La respuesta `200 OK`, servida
por nginx, confirmó que el tráfico externo llegaba correctamente al frontend.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -I http://172.16.20.19:30302/
  HTTP/1.1 200 OK
  Server: nginx/1.27.5
  Content-Type: text/html
  Content-Length: 397
  Cache-Control: no-store
  ```
]

Desde el navegador se abrió la opción `+ Nuevo producto` y se creó el artículo
`Samsung Clásico de Ejemplo`, con SKU `1000`, adjuntando el archivo JPEG conservado como
`tp6-imagen-producto.jpeg`. La ficha apareció con su fotografía en el catálogo, lo que demuestra
que el formulario y la imagen atravesaron el frontend y la API hasta almacenarse en MongoDB. La
consulta por SKU recuperó el mismo documento a través del proxy `/api` de nginx:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    'http://172.16.20.19:30302/api/productos?q=1000'
  [{"sku":1000,"nombre":"Samsung Clásico de Ejemplo","precio":99.99,
    "categoria":"Clásico","stock":1,"descripcion":"Samsung clásico.",
    "imagen_tipo":"image/jpeg","imagen_hash":"f8631bd99586e0bb",
    "id":"6adfce62f23b08b54246e4be","imagen":true}]
  ```
]

#captura(
  "tp6-producto-con-imagen.png",
  [Producto con SKU `1000` y su imagen visible a través del NodePort `30302`.],
  ancho: 100%,
)

Los campos `"imagen": true` e `"imagen_tipo": "image/jpeg"` confirman que el documento conserva
una imagen y su tipo MIME; `imagen_hash` permite invalidar la caché del navegador cuando se
reemplaza. La captura confirma de forma visual que nginx también pudo solicitar los bytes mediante
la API y mostrarlos en la tarjeta. Por lo tanto, quedaron comprobados tanto el acceso externo por
NodePort como el alta completa de un producto con imagen.


#consigna(5)[
  Crear un Service NodePort de depuración para la API, `catalogo-api-nodeport`, en el puerto
  `30502`, y verificarlo con `curl -s http://<IP-del-nodo>:30502/health`. Dejar asentado en el
  `README.md` que este objeto *no formará parte del chart de la semana 8*: existe solo con fines
  de depuración.
]

#resolucion[
  Se agregó el manifiesto `k8s/svc-catalogo-api-nodeport.yaml` para publicar temporalmente la API
  fuera del clúster. El Service usa el mismo selector `app: catalogo-api` que el Service interno,
  pero cambia el tipo a `NodePort`: conserva el puerto de servicio y destino `8000` y reserva el
  puerto `30502` en cada nodo.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply \
    -f k8s/svc-catalogo-api-nodeport.yaml
  service/catalogo-api-nodeport created
  homelab@rp5:~/Documents/catalogo-app$ kubectl get service \
    catalogo-api-nodeport -n catalogo-app
  NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
  catalogo-api-nodeport   NodePort   10.105.92.232   <none>        8000:30502/TCP
  ```
]

El resultado `8000:30502/TCP` indica que el Service escucha internamente en `8000` y queda
disponible desde el exterior en `<IP-del-nodo>:30502`. El valor `30502` pertenece al intervalo
predeterminado de NodePort, `30000` a `32767`.

Se compararon los endpoints del Service interno y del Service de depuración. Ambos seleccionaron
las mismas dos réplicas, lo cual confirma que el nuevo acceso no crea ni duplica Pods: solamente
ofrece otra vía de entrada hacia la API existente.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get endpoints \
    catalogo-api catalogo-api-nodeport -n catalogo-app -o wide
  Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
  NAME                    ENDPOINTS
  catalogo-api            10.244.0.28:8000,10.244.0.29:8000
  catalogo-api-nodeport   10.244.0.28:8000,10.244.0.29:8000
  ```
]

Finalmente se consultó `/health` en la IP y el puerto del nodo. En este acceso directo no se usa
el prefijo `/api`, porque la solicitud llega a FastAPI sin pasar por el proxy nginx del frontend.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    http://172.16.20.19:30502/health
  {"status":"ok","db":"ok","version":"v1"}
  ```
]

La respuesta confirmó que la API estaba disponible, que podía comunicarse con MongoDB y que
ejecutaba la versión `v1`. Este Service se conserva solo como herramienta temporal de depuración:
la arquitectura normal mantiene `catalogo-api` como `ClusterIP` y permite que únicamente el
frontend la consuma desde dentro del clúster. Por esa razón `catalogo-api-nodeport` *no formará
parte del chart de la semana 8*.


#consigna(6)[
  Comprobar la autorreparación. Con la aplicación abierta en el navegador, eliminar una réplica
  de la API indicándola por su nombre y observar con `kubectl get pods -w` cómo se recrea,
  verificando que la aplicación no deja de responder. Contrastarlo con lo observado en la
  semana 5.
]

/* Registro original de terminal, conservado como fuente para la resolución editada.
homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -l app=catalogo-api -n catalogo-app -w -o wide
NAME                           READY   STATUS    RESTARTS      AGE   IP            NODE       NOMINATED NODE   READINESS GATES
catalogo-api-9c5f8646d-4xc5b   1/1     Running   2 (74m ago)   83m   10.244.0.28   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   1/1     Running   1 (79m ago)   83m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   1/1     Terminating   1 (81m ago)   84m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   1/1     Terminating   1 (81m ago)   84m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-qz8gh   0/1     Pending       0             3s    <none>        <none>     <none>           <none>
catalogo-api-9c5f8646d-qz8gh   0/1     Pending       0             7s    <none>        lmurillo   <none>           <none>
catalogo-api-9c5f8646d-qz8gh   0/1     ContainerCreating   0             12s   <none>        lmurillo   <none>           <none>
catalogo-api-9c5f8646d-qz8gh   0/1     ContainerCreating   0             71s   <none>        lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   0/1     Completed           1 (82m ago)   86m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   0/1     Completed           1 (82m ago)   86m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-d2d75   0/1     Completed           1 (82m ago)   86m   10.244.0.29   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-qz8gh   1/1     Running             0             97s   10.244.0.32   lmurillo   <none>           <none>
^Chomelab@rp5:~/Documents/catalogo-appkubectl wait --for=condition=Ready pod \ \
  -l app=catalogo-api \
  -n catalogo-app \
  --timeout=180s
pod/catalogo-api-9c5f8646d-4xc5b condition met
pod/catalogo-api-9c5f8646d-qz8gh condition met
homelab@rp5:~/Documents/catalogo-app$ kubectl get deployment catalogo-api -n catalogo-app
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
catalogo-api   2/2     2            2           87m
homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -l app=catalogo-api -n catalogo-app -o wide
NAME                           READY   STATUS    RESTARTS      AGE     IP            NODE       NOMINATED NODE   READINESS GATES
catalogo-api-9c5f8646d-4xc5b   1/1     Running   2 (78m ago)   88m     10.244.0.28   lmurillo   <none>           <none>
catalogo-api-9c5f8646d-qz8gh   1/1     Running   0             3m15s   10.244.0.32   lmurillo   <none>           <none>
homelab@rp5:~/Documents/catalogo-app$

homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -l app=catalogo-api -n catalogo-app
NAME                           READY   STATUS    RESTARTS      AGE
catalogo-api-9c5f8646d-4xc5b   1/1     Running   2 (75m ago)   84m
catalogo-api-9c5f8646d-d2d75   1/1     Running   1 (80m ago)   84m
homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api-9c5f8646d-d2d75 -n catalogo-app
pod "catalogo-api-9c5f8646d-d2d75" deleted from catalogo-app namespace
homelab@rp5:~/Documents/catalogo-app$

homelab@rp5:~/Documents/catalogo-app$ while true; do
  printf '%s ' "$(date +%H:%M:%S)"
  curl -sS -o /dev/null \
    -w 'HTTP %{http_code}\n' \
    http://172.16.20.19:30302/api/health
  sleep 1
done
19:29:23 HTTP 200
19:29:24 HTTP 200
19:29:25 HTTP 200
19:29:27 HTTP 200
19:29:28 HTTP 200
19:29:29 HTTP 200
19:29:30 HTTP 200
19:29:31 HTTP 200
19:29:32 HTTP 200
19:29:33 HTTP 200
19:29:34 HTTP 200
19:29:35 HTTP 200
19:29:36 HTTP 200
19:29:37 HTTP 200
19:29:38 HTTP 200
19:29:39 HTTP 200
19:29:40 HTTP 200
19:29:41 HTTP 200
19:29:42 HTTP 200
19:29:43 HTTP 200
19:29:44 HTTP 200
19:29:45 HTTP 200
19:29:46 HTTP 200
19:29:47 HTTP 200
19:29:48 HTTP 200
19:29:49 HTTP 200
19:29:50 HTTP 200
19:29:51 HTTP 200
19:29:52 HTTP 200
19:29:53 HTTP 200
19:29:54 HTTP 200
19:29:55 HTTP 200
19:29:56 HTTP 200
19:29:57 HTTP 200
19:29:58 HTTP 200
19:29:59 HTTP 200
19:30:00 HTTP 200
19:30:01 HTTP 200
19:30:02 HTTP 200
19:30:04 HTTP 200
19:30:05 HTTP 200
19:30:06 HTTP 200
19:30:07 HTTP 200
19:30:08 HTTP 200
19:30:09 HTTP 200
19:30:10 HTTP 200
19:30:11 HTTP 200
19:30:12 HTTP 200
19:30:13 HTTP 200
19:30:14 HTTP 200
19:30:15 HTTP 200
19:30:16 HTTP 200
19:30:17 HTTP 200
19:30:18 HTTP 200
19:30:19 HTTP 200
19:30:20 HTTP 200
19:30:21 HTTP 200
19:30:22 HTTP 200
19:30:23 HTTP 200
19:30:24 HTTP 200
19:30:25 HTTP 200
19:30:26 HTTP 200
19:30:27 HTTP 200
19:30:28 HTTP 200
19:30:29 HTTP 200
19:30:30 HTTP 200
19:30:31 HTTP 200
19:30:32 HTTP 200
19:30:33 HTTP 200
19:30:34 HTTP 200
19:30:35 HTTP 200
19:30:36 HTTP 200
19:30:37 HTTP 200
19:30:38 HTTP 200
19:30:39 HTTP 200
19:30:40 HTTP 200
19:30:42 HTTP 200
19:30:43 HTTP 200
19:30:44 HTTP 200
19:30:45 HTTP 200
19:30:46 HTTP 200
19:30:47 HTTP 200
19:30:48 HTTP 200
19:30:49 HTTP 200
19:30:50 HTTP 200
19:30:51 HTTP 200
19:30:52 HTTP 200
19:30:53 HTTP 200
19:30:54 HTTP 200
19:30:55 HTTP 200
19:30:56 HTTP 200
19:30:57 HTTP 200
19:30:58 HTTP 200
19:30:59 HTTP 200
19:31:00 HTTP 200
19:31:01 HTTP 200
19:31:02 HTTP 200
19:31:03 HTTP 200
19:31:04 HTTP 200
19:31:05 HTTP 200
19:31:06 HTTP 200
19:31:07 HTTP 200
19:31:08 HTTP 200
19:31:09 HTTP 200
19:31:10 HTTP 200
19:31:11 HTTP 200
19:31:12 HTTP 200
19:31:13 HTTP 200
19:31:14 HTTP 200
19:31:15 HTTP 200
19:31:16 HTTP 200
19:31:17 HTTP 200
19:31:18 HTTP 200
19:31:20 HTTP 200
19:31:21 HTTP 200
19:31:22 HTTP 200
19:31:23 HTTP 200
19:31:24 HTTP 200
19:31:25 HTTP 200
19:31:26 HTTP 200
19:31:27 HTTP 200
19:31:28 HTTP 200
19:31:29 HTTP 200
19:31:30 HTTP 200
19:31:31 HTTP 200
19:31:32 HTTP 200
19:31:33 HTTP 200
19:31:34 HTTP 200
19:31:35 HTTP 200
19:31:36 HTTP 200
19:31:37 HTTP 200
19:31:38 HTTP 200
19:31:39 HTTP 200
19:31:40 HTTP 200
19:31:41 HTTP 200
19:31:42 HTTP 200
19:31:43 HTTP 200
19:31:44 HTTP 200
19:31:45 HTTP 200
19:31:46 HTTP 200
19:31:47 HTTP 200
19:31:48 HTTP 200
19:31:49 HTTP 200
19:31:50 HTTP 200
19:31:51 HTTP 200
19:31:52 HTTP 200
19:31:53 HTTP 200
19:31:54 HTTP 200
19:31:55 HTTP 200
19:31:56 HTTP 200
19:31:58 HTTP 200
19:31:59 HTTP 200
19:32:00 HTTP 200
19:32:01 HTTP 200
19:32:02 HTTP 200
19:32:03 HTTP 200
19:32:04 HTTP 200
19:32:05 HTTP 200
19:32:06 HTTP 200
19:32:07 HTTP 200
19:32:08 HTTP 200
19:32:09 HTTP 200
19:32:10 HTTP 200
19:32:11 HTTP 200
19:32:12 HTTP 200
19:32:13 HTTP 200
19:32:14 HTTP 200
19:32:15 HTTP 200
19:32:16 HTTP 200
19:32:17 HTTP 200
19:32:18 HTTP 200
19:32:19 HTTP 200
19:32:20 HTTP 200
19:32:21 HTTP 200
19:32:22 HTTP 200
19:32:23 HTTP 200
19:32:24 HTTP 200
19:32:25 HTTP 200
19:32:26 HTTP 200
19:32:27 HTTP 200
19:32:28 HTTP 200
19:32:29 HTTP 200
19:32:30 HTTP 200
19:32:31 HTTP 200
19:32:32 HTTP 200
19:32:33 HTTP 200
19:32:34 HTTP 200
19:32:36 HTTP 200
19:32:37 HTTP 200
19:32:38 HTTP 200
19:32:39 HTTP 200
19:32:40 HTTP 200
19:32:41 HTTP 200
19:32:42 HTTP 200
19:32:43 HTTP 200
19:32:44 HTTP 200
19:32:45 HTTP 200
19:32:46 HTTP 200
19:32:47 HTTP 200
19:32:48 HTTP 200
19:32:49 HTTP 200
19:32:50 HTTP 200
19:32:51 HTTP 200
19:32:52 HTTP 200
19:32:53 HTTP 200
19:32:54 HTTP 200
19:32:55 HTTP 200
19:32:56 HTTP 200
19:32:57 HTTP 200
19:32:58 HTTP 200
19:32:59 HTTP 200
19:33:00 HTTP 200
19:33:01 HTTP 200
19:33:02 HTTP 200
19:33:03 HTTP 200
19:33:04 HTTP 200
19:33:05 HTTP 200
19:33:06 HTTP 200
19:33:07 HTTP 200
19:33:08 HTTP 200
19:33:09 HTTP 200
19:33:10 HTTP 200
19:33:11 HTTP 200
19:33:12 HTTP 200
19:33:14 HTTP 200
19:33:15 HTTP 200
19:33:16 HTTP 200
19:33:17 HTTP 200
19:33:18 HTTP 200
19:33:19 HTTP 200
19:33:20 HTTP 200
19:33:21 HTTP 200
19:33:22 HTTP 200
19:33:23 HTTP 200
19:33:24 HTTP 200
19:33:25 HTTP 200
19:33:26 HTTP 200
19:33:28 HTTP 200
19:33:29 HTTP 200
19:33:30 HTTP 200
19:33:31 HTTP 200
19:33:32 HTTP 200
19:33:33 HTTP 200
19:33:34 HTTP 200
19:33:35 HTTP 200
19:33:36 HTTP 200
19:33:37 HTTP 200
19:33:38 HTTP 200
19:33:39 HTTP 200
19:33:40 HTTP 200
19:33:41 HTTP 200
19:33:42 HTTP 200
19:33:43 HTTP 200
19:33:44 HTTP 200
19:33:45 HTTP 200
19:33:46 HTTP 200
19:33:48 HTTP 200
19:33:49 HTTP 200
19:33:50 HTTP 200
19:33:51 HTTP 200
^C
homelab@rp5:~/Documents/catalogo-app$
*/

#resolucion[
  La prueba se realizó manteniendo la aplicación abierta en el navegador y observando en paralelo
  los Pods de la API. Al inicio, el Deployment tenía sus dos réplicas disponibles. Se eligió por su
  nombre una de ellas, `catalogo-api-9c5f8646d-d2d75`, y se eliminó únicamente ese Pod, sin borrar
  el Deployment ni el ReplicaSet.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app
  NAME                           READY   STATUS    RESTARTS   AGE
  catalogo-api-9c5f8646d-4xc5b   1/1     Running   2          84m
  catalogo-api-9c5f8646d-d2d75   1/1     Running   1          84m
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod \
    catalogo-api-9c5f8646d-d2d75 -n catalogo-app
  pod "catalogo-api-9c5f8646d-d2d75" deleted from catalogo-app namespace
  ```
]

En otra terminal, `kubectl get pods -w` mostró la transición completa. El Pod eliminado pasó a
`Terminating`; casi inmediatamente apareció `catalogo-api-9c5f8646d-qz8gh`, primero como `Pending`,
luego como `ContainerCreating` y finalmente como `Running`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app -w -o wide
  NAME                           READY   STATUS              IP
  catalogo-api-9c5f8646d-d2d75   1/1     Terminating         10.244.0.29
  catalogo-api-9c5f8646d-qz8gh   0/1     Pending             <none>
  catalogo-api-9c5f8646d-qz8gh   0/1     ContainerCreating   <none>
  catalogo-api-9c5f8646d-d2d75   0/1     Completed           10.244.0.29
  catalogo-api-9c5f8646d-qz8gh   1/1     Running             10.244.0.32
  ^C
  ```
]

El prefijo `catalogo-api-9c5f8646d` se mantuvo porque ambos Pods pertenecen al mismo ReplicaSet;
solo cambió el sufijo aleatorio de la instancia. También cambió la IP de `10.244.0.29` a
`10.244.0.32`, lo que confirma que se creó un Pod nuevo y no se reinició el anterior. El
controlador detectó que la cantidad real había descendido por debajo de las dos réplicas deseadas
y creó el reemplazo automáticamente.

Durante todo el procedimiento se consultó `/api/health` a través del frontend. Todas las respuestas
fueron `HTTP 200`, desde antes de la eliminación hasta después de que la nueva réplica quedara
lista. Se muestran muestras del intervalo registrado:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ while true; do
    printf '%s ' "$(date +%H:%M:%S)"
    curl -sS -o /dev/null -w 'HTTP %{http_code}\n' \
      http://172.16.20.19:30302/api/health
    sleep 1
  done
  19:29:23 HTTP 200
  19:29:24 HTTP 200
  19:29:25 HTTP 200
  ...
  19:31:00 HTTP 200
  ...
  19:33:49 HTTP 200
  19:33:50 HTTP 200
  19:33:51 HTTP 200
  ^C
  ```
]

La continuidad fue posible porque el Service siguió enviando tráfico a la otra réplica disponible
mientras se creaba el reemplazo. Los clientes usan el Service y no la IP particular del Pod, por
lo que el cambio de `10.244.0.29` a `10.244.0.32` no requirió modificar el frontend.

Por último se esperó que todos los Pods seleccionados recuperaran la condición `Ready` y se
comprobó que el Deployment volviera al estado deseado `2/2`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl wait \
    --for=condition=Ready pod -l app=catalogo-api \
    -n catalogo-app --timeout=180s
  pod/catalogo-api-9c5f8646d-4xc5b condition met
  pod/catalogo-api-9c5f8646d-qz8gh condition met
  homelab@rp5:~/Documents/catalogo-app$ kubectl get deployment \
    catalogo-api -n catalogo-app
  NAME           READY   UP-TO-DATE   AVAILABLE
  catalogo-api   2/2     2            2
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app -o wide
  NAME                           READY   STATUS    IP
  catalogo-api-9c5f8646d-4xc5b   1/1     Running   10.244.0.28
  catalogo-api-9c5f8646d-qz8gh   1/1     Running   10.244.0.32
  ```
]

El comportamiento contrasta con la semana 5. En aquella entrega `catalogo-api` era un Pod suelto,
sin un controlador propietario: al eliminarlo permanecía ausente y era necesario ejecutar otra
vez `kubectl apply`. En esta entrega el Deployment declara dos réplicas y su ReplicaSet reconcilia
continuamente el estado real con ese estado deseado. La recreación automática y la réplica que
permanece atendiendo aportan autorreparación y continuidad de servicio.

#pagebreak()

#consigna(7)[
  Ejecutar una actualización progresiva y su _rollback_, observando el indicador de versión del
  frontend. La versión v2 debe construirse con el argumento de la semana 2 y *publicarse* en el
  registro, ya que el clúster solo descarga imágenes de allí:

  #comandos[
    ```text
    docker build --build-arg APP_VERSION=v2 -t <tu_usuario>/catalogo-api:v2 ./backend
    docker push <tu_usuario>/catalogo-api:v2
    kubectl set image deployment/catalogo-api \
      catalogo-api=<tu_usuario>/catalogo-api:v2 -n catalogo-app
    kubectl rollout status deployment/catalogo-api -n catalogo-app
    kubectl rollout history deployment/catalogo-api -n catalogo-app
    kubectl rollout undo deployment/catalogo-api -n catalogo-app
    ```
  ]

  El indicador debe pasar de `v1` a `v2` y volver. Si no cambia, falta el par ARG/ENV
  `APP_VERSION` de la semana 2. Si la actualización se detiene con un Pod en
  `ImagePullBackOff`, la imagen v2 no está publicada: la versión anterior continúa atendiendo,
  y se revierte con `rollout undo`.
]

#resolucion[
  La imagen `v2` se construyó con `APP_VERSION=v2` y se publicó para `linux/amd64`, la
  arquitectura del nodo del clúster. Se utilizó `buildx` con `--push`, por lo que la imagen quedó
  disponible en Docker Hub sin depender del almacenamiento local del equipo de construcción.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ docker buildx build \
    --platform linux/amd64 \
    --build-arg APP_VERSION=v2 \
    -t leandromurillo/catalogo-api:v2 \
    --push ./backend
  ...
  => exporting manifest list sha256:6060d71a5b1aab6a93f0c94b06da0042e56ab2fdbadcba22af145b27095d5f1b
  => pushing manifest for docker.io/leandromurillo/catalogo-api:v2
  ```
]

El argumento de construcción queda incorporado en la imagen mediante el par `ARG`/`ENV` del
Dockerfile. El Deployment no sobrescribe `APP_VERSION`, de modo que `/health` y el indicador del
frontend muestran la versión de la imagen que realmente está ejecutando cada Pod.

La actualización se inició cambiando solo la imagen de la plantilla del Deployment. Kubernetes
creó el ReplicaSet `catalogo-api-dbd95f999` para `v2` y conservó temporalmente Pods del ReplicaSet
`catalogo-api-5dd5c57dbb` de `v1`. Cada Pod anterior terminó únicamente después de que un Pod nuevo
estuviera `Running`, comportamiento propio de la estrategia `RollingUpdate`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl set image deployment/catalogo-api \
    catalogo-api=leandromurillo/catalogo-api:v2 -n catalogo-app
  deployment.apps/catalogo-api image updated

  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app -w -o wide
  NAME                            READY   STATUS              IP
  catalogo-api-5dd5c57dbb-dnq5g   1/1     Running             10.244.0.39
  catalogo-api-5dd5c57dbb-lbjmg   1/1     Running             10.244.0.38
  catalogo-api-dbd95f999-hg447    0/1     ContainerCreating   <none>
  catalogo-api-dbd95f999-hg447    1/1     Running             10.244.0.40
  catalogo-api-5dd5c57dbb-lbjmg   1/1     Terminating         10.244.0.38
  catalogo-api-dbd95f999-bx22g    0/1     ContainerCreating   <none>
  catalogo-api-dbd95f999-bx22g    1/1     Running             10.244.0.41
  catalogo-api-5dd5c57dbb-dnq5g   1/1     Terminating         10.244.0.39
  ^C

  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout status \
    deployment/catalogo-api -n catalogo-app --timeout=300s
  Waiting for deployment "catalogo-api" rollout to finish: 1 out of 2 new replicas have been updated...
  Waiting for deployment "catalogo-api" rollout to finish: 1 old replicas are pending termination...
  deployment "catalogo-api" successfully rolled out
  ```
]

Al finalizar, las consultas dejaron de alternar entre versiones y devolvieron `v2` de forma
estable. El mismo valor apareció en el indicador del frontend, ya que este consulta
`/api/health` a través del Service.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    http://172.16.20.19:30302/api/health
  {"status":"ok","db":"ok","version":"v2"}

  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout history \
    deployment/catalogo-api -n catalogo-app
  deployment.apps/catalogo-api
  REVISION  CHANGE-CAUSE
  1         <none>
  2         <none>
  ```
]

Luego se ejecutó el rollback. `rollout undo` recuperó la plantilla anterior como una nueva
revisión: el ReplicaSet de `v1` volvió a escalar a dos réplicas y el de `v2` quedó en cero. El
historial no elimina revisiones; registra el rollback como la revisión 3, lo que permite auditar la
secuencia `v1` a `v2` a `v1`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout undo \
    deployment/catalogo-api -n catalogo-app
  deployment.apps/catalogo-api rolled back

  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout status \
    deployment/catalogo-api -n catalogo-app --timeout=300s
  deployment "catalogo-api" successfully rolled out

  homelab@rp5:~/Documents/catalogo-app$ kubectl get deployment,rs \
    -l app=catalogo-api -n catalogo-app
  NAME                           READY   UP-TO-DATE   AVAILABLE
  deployment.apps/catalogo-api   2/2     2            2

  NAME                                      DESIRED   CURRENT   READY
  replicaset.apps/catalogo-api-5dd5c57dbb   2         2         2
  replicaset.apps/catalogo-api-dbd95f999    0         0         0

  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app
  NAME                            READY   STATUS    RESTARTS
  catalogo-api-5dd5c57dbb-mfqfp   1/1     Running   0
  catalogo-api-5dd5c57dbb-vktvm   1/1     Running   0

  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout history \
    deployment/catalogo-api -n catalogo-app
  deployment.apps/catalogo-api
  REVISION  CHANGE-CAUSE
  2         <none>
  3         <none>

  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    http://172.16.20.19:30302/api/health
  {"status":"ok","db":"ok","version":"v1"}
  ```
]

El resultado final coincide con el estado previo a la actualización: dos réplicas disponibles,
respuesta saludable de la base de datos y versión `v1` visible nuevamente en el frontend. El
Service permaneció estable durante ambos cambios; lo que se reemplazó fueron los Pods administrados
por los ReplicaSets.


#consigna(8)[
  Escalar la API a tres réplicas, cargar un producto con imagen y verificar que la aplicación
  responde desde cualquiera de ellas:

  #comandos[
    ```text
    kubectl scale deployment catalogo-api --replicas=3 -n catalogo-app
    for i in $(seq 1 10); do
      curl -s -o /dev/null -w "%{http_code} " http://<IP-del-nodo>:30502/productos
    done
    ```
  ]

  Comprobar luego qué ocurriría si la API guardara las imágenes en el disco del contenedor en
  lugar de en la base de datos, escribiendo un archivo en una réplica y buscándolo en otra:

  #comandos[
    ```text
    kubectl exec deploy/catalogo-api -n catalogo-app -- \
      sh -c 'echo prueba > /tmp/foto.bin; ls -l /tmp/foto.bin'
    kubectl exec <otro-pod-de-la-api> -n catalogo-app -- ls -l /tmp/foto.bin
    ```
  ]

  Responder por escrito: un archivo escrito en el disco de un Pod *no lo ve ninguna otra
  réplica*, y desaparece cuando el Pod se recrea. Por esa razón esta variante guarda los bytes de
  la imagen en el documento de MongoDB, y por esa razón la API no tiene estado.
]

#resolucion[
  Primero se aumentó de dos a tres la cantidad deseada de réplicas del Deployment. El controlador
  creó el Pod `catalogo-api-5dd5c57dbb-p8g9f` sin reemplazar los dos existentes. Los tres nombres
  conservan el hash `5dd5c57dbb` porque pertenecen al mismo ReplicaSet y ejecutan la misma plantilla
  e imagen de la API.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl scale deployment \
    catalogo-api --replicas=3 -n catalogo-app
  deployment.apps/catalogo-api scaled

  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout status \
    deployment/catalogo-api -n catalogo-app
  Waiting for deployment "catalogo-api" rollout to finish: 2 of 3 updated replicas are available...
  deployment "catalogo-api" successfully rolled out

  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-api -n catalogo-app -o wide
  NAME                            READY   STATUS    IP            NODE
  catalogo-api-5dd5c57dbb-mfqfp   1/1     Running   10.244.0.42   lmurillo
  catalogo-api-5dd5c57dbb-p8g9f   1/1     Running   10.244.0.44   lmurillo
  catalogo-api-5dd5c57dbb-vktvm   1/1     Running   10.244.0.43   lmurillo
  ```
]

El estado `1/1 Running` en los tres Pods confirma que todas las réplicas superaron su prueba de
disponibilidad y pueden incorporarse como endpoints del Service. Cada una tiene una IP diferente,
pero el cliente no necesita conocerlas: accede al NodePort estable y Kubernetes selecciona un
backend disponible.

Con las tres réplicas activas se creó desde el frontend el producto `Celular de Ejemplo`, con SKU
`1001`, adjuntando el archivo conservado como `tp6-imagen-producto-escalado.jpeg`. La nueva tarjeta
apareció correctamente en el catálogo junto con los productos ya existentes.

#captura(
  "tp6-producto-tres-replicas.png",
  [Producto con SKU `1001` e imagen visible después de escalar la API a tres réplicas.],
  ancho: 100%,
)

Después se realizaron diez consultas consecutivas directamente al NodePort de depuración de la
API. Todas devolvieron `HTTP 200`. El Service mantiene una dirección única y distribuye las
conexiones entre los Pods `Ready`, por lo que el funcionamiento del cliente no depende de una
réplica ni de una IP de Pod determinada.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ for i in $(seq 1 10); do
    curl -s -o /dev/null -w "%{http_code} " \
      http://172.16.20.19:30502/productos
  done
  printf '\n'
  200 200 200 200 200 200 200 200 200 200
  ```
]

Por último se simuló el almacenamiento de una imagen en el disco local del contenedor. Se escribió
`/tmp/foto.bin` dentro de `catalogo-api-5dd5c57dbb-mfqfp`; el archivo quedó asociado exclusivamente
a la capa escribible de ese Pod. Al buscar la misma ruta en las otras dos réplicas, ambas
respondieron que el archivo no existía.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl exec \
    catalogo-api-5dd5c57dbb-mfqfp -n catalogo-app -- \
    sh -c 'echo prueba > /tmp/foto.bin; ls -l /tmp/foto.bin'
  -rw-r--r-- 1 catalogo catalogo 7 Oct 26 23:50 /tmp/foto.bin

  homelab@rp5:~/Documents/catalogo-app$ kubectl exec \
    catalogo-api-5dd5c57dbb-p8g9f -n catalogo-app -- \
    ls -l /tmp/foto.bin
  ls: cannot access '/tmp/foto.bin': No such file or directory
  command terminated with exit code 2

  homelab@rp5:~/Documents/catalogo-app$ kubectl exec \
    catalogo-api-5dd5c57dbb-vktvm -n catalogo-app -- \
    ls -l /tmp/foto.bin
  ls: cannot access '/tmp/foto.bin': No such file or directory
  command terminated with exit code 2
  ```
]

Cada Pod posee un filesystem aislado y efímero. Por eso un archivo escrito dentro de una réplica no
es visible desde las demás y desaparece cuando esa réplica se elimina o se recrea. Guardar allí las
imágenes produciría respuestas diferentes según el Pod elegido por el Service.

La aplicación evita ese problema almacenando los bytes y el tipo MIME de cada imagen dentro del
documento de MongoDB. Las tres instancias de la API consultan la misma base de datos y no conservan
datos de negocio en su filesystem local. En consecuencia, cualquiera de ellas puede responder con
el mismo producto y su imagen: la API es _stateless_ y puede escalarse horizontalmente.

#consigna(9)[
  Documentar la limitación que queda declarada. `catalogo-db` es un Deployment *sin
  persistencia*. Eliminar su Pod con
  `kubectl delete pod -l app=catalogo-db -n catalogo-app`, esperar a que se recree y listar los
  productos: el catálogo está vacío. Reiniciar luego la API con
  `kubectl rollout restart deployment/catalogo-api -n catalogo-app` y listar de nuevo: reaparece
  el catálogo de demostración, porque la siembra se ejecuta al arrancar la API, pero los productos
  cargados a mano no están. Registrarlo en el `README.md` como limitación conocida y explícita,
  que se resuelve en la semana 7 con un volumen persistente.
]

#resolucion[
  Antes de eliminar MongoDB se comprobó que el producto cargado manualmente en el punto anterior
  seguía almacenado. La búsqueda por SKU recuperó `Celular de Ejemplo`, incluido su indicador de
  imagen, por lo que existía un dato concreto cuya pérdida podía verificarse.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    'http://172.16.20.19:30502/productos?q=1001'
  [{"sku":1001,"nombre":"Celular de Ejemplo","precio":98.99,
    "categoria":"Ejemplo","stock":2,"imagen_tipo":"image/jpeg",
    "imagen_hash":"cc84746e03788c7e","imagen":true}]
  ```
]

El Pod de la base era `catalogo-db-654f9f8fdc-nxl6q`, con IP `10.244.0.27`. Se eliminó mediante
su label, sin borrar el Deployment. El ReplicaSet creó automáticamente
`catalogo-db-654f9f8fdc-xf72p`, que atravesó `ContainerCreating` y `Running` y recibió la nueva IP
`10.244.0.45`. El hash permaneció igual porque no cambió la plantilla del Deployment; solo se
reemplazó su instancia.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-db -n catalogo-app -o wide
  NAME                           READY   STATUS    IP            NODE
  catalogo-db-654f9f8fdc-nxl6q   1/1     Running   10.244.0.27   lmurillo

  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod \
    -l app=catalogo-db -n catalogo-app
  pod "catalogo-db-654f9f8fdc-nxl6q" deleted from catalogo-app namespace

  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods \
    -l app=catalogo-db -n catalogo-app -w -o wide
  NAME                           READY   STATUS              IP
  catalogo-db-654f9f8fdc-nxl6q   1/1     Terminating         10.244.0.27
  catalogo-db-654f9f8fdc-xf72p   0/1     ContainerCreating   <none>
  catalogo-db-654f9f8fdc-nxl6q   0/1     Completed           10.244.0.27
  catalogo-db-654f9f8fdc-xf72p   1/1     Running             10.244.0.45
  ^C
  ```
]

Una vez que MongoDB aceptó conexiones, `/health` volvió a informar `db: ok`. Sin embargo, el nuevo
Pod comenzó con `/data/db` vacío: el listado general y la búsqueda del SKU manual devolvieron
arreglos vacíos. El Deployment recuperó la disponibilidad del proceso, pero no los datos del Pod
eliminado.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    http://172.16.20.19:30502/health
  {"status":"ok","db":"ok","version":"v1"}

  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    http://172.16.20.19:30502/productos
  []

  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    'http://172.16.20.19:30502/productos?q=1001'
  []
  ```
]

Después se reinició el Deployment de la API. El primer Pod de la nueva revisión se conectó a la
base vacía y ejecutó la siembra idempotente configurada mediante `SEED_DEMO=true`. Sus logs
confirmaron la inserción de los doce productos incluidos en la imagen.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl rollout restart \
    deployment/catalogo-api -n catalogo-app
  deployment.apps/catalogo-api restarted

  homelab@rp5:~/Documents/catalogo-app$ kubectl logs \
    catalogo-api-8596b7cf95-2nf5w -n catalogo-app
  INFO:     Waiting for application startup.
  [2026-10-27T00:18:53+0000] INFO conexión a MongoDB establecida (base=catalogodb)
  [2026-10-27T00:18:58+0000] INFO catálogo de demo sembrado (12 productos)
  INFO:     Application startup complete.
  ```
]

La consulta final recuperó nuevamente un producto de demostración, `Honor 9N`, mientras que el SKU
`1001` siguió ausente. La siembra puede reconstruir el conjunto empacado con la aplicación, pero no
puede reconstruir productos creados por los usuarios.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    'http://172.16.20.19:30502/productos?q=Honor'
  [{"nombre":"Honor 9N (Midnight Black, 32 GB) (3 GB RAM)",
    "categoria":"Honor","precio":39000,"sku":123222,"stock":11,
    "imagen_tipo":"image/jpeg","imagen":true}]

  homelab@rp5:~/Documents/catalogo-app$ curl -s \
    'http://172.16.20.19:30502/productos?q=1001'
  []
  ```
]

La causa es que `k8s/deploy-catalogo-db.yaml` no monta un volumen persistente. Los archivos de
MongoDB residen en la capa escribible del contenedor y desaparecen junto con el Pod. Kubernetes
garantiza que el Deployment vuelva a tener una réplica, pero no conserva el contenido de esa
réplica. Esta limitación se resolverá en la semana 7 montando un volumen persistente en `/data/db`.
