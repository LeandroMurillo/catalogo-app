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

// Consignas transcritas de tp-05-C.pdf, páginas 1 a 3.
#align(center)[
  #text(size: 12pt)[Trabajo Práctico N° 5 — Variante C]

  Proyecto: `catalogo-app`
]

= Consignas

#consigna(1)[
  Hacer que el clúster pueda acceder a las imágenes propias. El clúster se ejecuta en *otra
  máquina* y no utiliza la caché de imágenes del Docker Engine local, de modo que las imágenes
  deben publicarse en un registry —tal como se hizo en la segunda entrega— y nombrarse de forma
  completa en los manifiestos:

  #comandos[
    ```text
    docker login
    docker tag catalogo-api:v1       <usuario>/catalogo-api:v1
    docker tag catalogo-frontend:v1 <usuario>/catalogo-frontend:v1
    docker push <usuario>/catalogo-api:v1
    docker push <usuario>/catalogo-frontend:v1
    ```
  ]

  Debe provocarse además el error *una vez de manera deliberada*, aplicando un Pod cuya imagen
  se nombre sin el usuario del registry (`catalogo-api:v1` en lugar de
  `<usuario>/catalogo-api:v1`), y registrarse la salida de `kubectl describe pod` con el estado
  `ErrImagePull` o `ImagePullBackOff`, señalando en la sección Events qué nombre de imagen
  intentó descargar el kubelet.
]

#resolucion[
  Las imágenes ya se encontraban publicadas en Docker Hub como
  `leandromurillo/catalogo-api:v1` y `leandromurillo/catalogo-frontend:v1`. Estos nombres
  completos identifican tanto el usuario del registry como el repositorio y permiten que el
  clúster remoto las descargue sin depender de la caché del Docker Engine local.
]

Para comprobar el comportamiento de un nombre incompleto creamos deliberadamente un Pod con
`catalogo-api:v1`. La política `Always` obliga al kubelet a consultar el registry, mientras que
`--restart=Never` genera un Pod suelto y evita crear otro tipo de recurso controlador.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl run catalogo-api-imagepull-test \
    --image=catalogo-api:v1 \
    --restart=Never \
    --image-pull-policy=Always
  pod/catalogo-api-imagepull-test created
  ```
]

Observamos los cambios de estado en tiempo real. `ErrImagePull` informa el fallo concreto de una
descarga; después de varios intentos, `ImagePullBackOff` indica que Kubernetes aplica esperas
progresivas antes de volver a intentarla. Ninguno de los estados implica que el contenedor haya
llegado a ejecutarse.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api-imagepull-test -w
  NAME                          READY   STATUS             RESTARTS   AGE
  catalogo-api-imagepull-test   0/1     ImagePullBackOff   0          34s
  catalogo-api-imagepull-test   0/1     ErrImagePull       0          35s
  catalogo-api-imagepull-test   0/1     ImagePullBackOff   0          50s
  ^C
  ```
]

Usamos `kubectl describe` porque la causa de un fallo anterior al arranque se encuentra en los
Events del Pod, no en sus logs:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl describe pod catalogo-api-imagepull-test
  Name:             catalogo-api-imagepull-test
  Namespace:        default
  Priority:         0
  Service Account:  default
  Node:             lmurillo/172.16.20.19
  Start Time:       Mon, 19 Oct 2026 19:03:50 -0300
  Labels:           run=catalogo-api-imagepull-test
  Annotations:      <none>
  Status:           Pending
  IP:               10.244.0.7
  IPs:
    IP:  10.244.0.7
  Containers:
    catalogo-api-imagepull-test:
      Container ID:
      Image:          catalogo-api:v1
      Image ID:
      Port:           <none>
      Host Port:      <none>
      State:          Waiting
        Reason:       ImagePullBackOff
      Ready:          False
      Restart Count:  0
      Environment:    <none>
      Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-mzl7h (ro)
  Conditions:
    Type                        Status
    PodReadyToStartContainers   True
    Initialized                 True
    Ready                       False
    ContainersReady             False
    PodScheduled                True
  Volumes:
    kube-api-access-mzl7h:
      Type:                    Projected (a volume that contains injected data from multiple sources)
      TokenExpirationSeconds:  3607
      ConfigMapName:           kube-root-ca.crt
      Optional:                false
      DownwardAPI:             true
  QoS Class:                   BestEffort
  Node-Selectors:              <none>
  Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                               node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
  Events:
    Type     Reason     Age                From               Message
    ----     ------     ----               ----               -------
    Normal   Scheduled  59s                default-scheduler  Successfully assigned default/catalogo-api-imagepull-test to lmurillo
    Normal   BackOff    25s (x2 over 54s)  kubelet            spec.containers{catalogo-api-imagepull-test}: Back-off pulling image "catalogo-api:v1"
    Warning  Failed     25s (x2 over 54s)  kubelet            spec.containers{catalogo-api-imagepull-test}: Error: ImagePullBackOff
    Normal   Pulling    10s (x3 over 56s)  kubelet            spec.containers{catalogo-api-imagepull-test}: Pulling image "catalogo-api:v1"
    Warning  Failed     8s (x3 over 55s)   kubelet            spec.containers{catalogo-api-imagepull-test}: Failed to pull image "catalogo-api:v1": failed to pull and unpack image "docker.io/library/catalogo-api:v1": failed to resolve reference "docker.io/library/catalogo-api:v1": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
    Warning  Failed     8s (x3 over 55s)   kubelet            spec.containers{catalogo-api-imagepull-test}: Error: ErrImagePull
  ```
]

La sección Events confirma que kubelet expandió el nombre corto a
`docker.io/library/catalogo-api:v1`. Es decir, buscó la imagen en el espacio `library` de Docker
Hub y no en `leandromurillo`, donde realmente fue publicada. Por eso el mensaje informa
`pull access denied` y `insufficient_scope`: el problema es el nombre de la imagen, no el arranque
de la aplicación ni su configuración interna.

Finalmente eliminamos el Pod de prueba para no conservar un recurso fallido en el clúster:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api-imagepull-test
  pod "catalogo-api-imagepull-test" deleted from default namespace
  ```
]

#consigna(2)[
  Crear el namespace `catalogo-app` y establecerlo como namespace por defecto del contexto.
  Registrar previamente la salida de `kubectl config current-context`: verificar contra qué
  clúster se está operando *antes* de aplicar cualquier manifiesto constituye el hábito que evita
  intervenir sobre el clúster equivocado.
]

#resolucion[
  Antes de crear recursos consultamos el contexto activo. Un contexto de Kubernetes reúne el
  clúster, las credenciales y el namespace que utilizará `kubectl`; verificarlo evita enviar
  operaciones al destino equivocado.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl config current-context
  lmurillo
  ```
]

La salida confirma que el contexto seleccionado es `lmurillo`. A continuación creamos un
namespace exclusivo para el proyecto. El namespace proporciona un ámbito lógico para sus
recursos y evita mezclarlos con los del namespace `default` u otras aplicaciones.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl create namespace catalogo-app
  namespace/catalogo-app created
  ```
]

Establecemos `catalogo-app` como namespace predeterminado del contexto actual. Este comando
modifica el `kubeconfig` local: no cambia una configuración global del clúster ni afecta los
contextos de otros usuarios. Desde este momento, los comandos que omitan `--namespace` o `-n`
operarán sobre `catalogo-app`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl config set-context --current --namespace=catalogo-app
  Context "lmurillo" modified.
  ```
]

Consultamos la configuración efectiva del contexto y extraemos únicamente su namespace. El
resultado confirma que el cambio quedó guardado:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl config view --minify --output 'jsonpath={..namespace}{"\n"}'
  catalogo-app
  ```
]

Finalmente ejecutamos una consulta sin indicar `-n`. El mensaje nombra explícitamente a
`catalogo-app`, lo que demuestra que `kubectl` utilizó el nuevo valor predeterminado. La ausencia
de Pods es esperable porque todavía no se aplicaron los manifiestos de la entrega.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods
  No resources found in catalogo-app namespace.
  ```
]

#consigna(3)[
  *Generar* el primer manifiesto en lugar de escribirlo a mano, mediante
  `kubectl run catalogo-db --image=mongo:7 --dry-run=client -o yaml`, redirigiendo la salida a
  `k8s/pod-catalogo-db.yaml`. Editarlo a continuación para incorporarle las dos variables
  `MONGO_INITDB_ROOT_*` y el puerto `27017`. Generar el manifiesto y editarlo constituye la
  práctica habitual; escribirlo desde cero no aporta ningún mérito.
]

#resolucion[
  Creamos el directorio `k8s` en la raíz del repositorio y generamos el manifiesto base con
  `kubectl run`. La opción `--dry-run=client` construye el objeto localmente sin comunicarse con
  el clúster para crearlo, mientras que `-o yaml` lo serializa como YAML. La redirección guarda
  esa salida en el archivo solicitado, por lo que el comando no imprime contenido en la terminal.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ mkdir -p k8s
  homelab@rp5:~/Documents/catalogo-app$ kubectl run catalogo-db \
    --image=mongo:7 \
    --dry-run=client \
    -o yaml > k8s/pod-catalogo-db.yaml
  ```
]

Editamos el manifiesto generado para incorporar `MONGO_INITDB_ROOT_USERNAME`,
`MONGO_INITDB_ROOT_PASSWORD` y el puerto de contenedor `27017`. Las variables indican al
_entrypoint_ de la imagen oficial qué usuario administrador debe crear durante la inicialización
de una base vacía. La declaración `containerPort` documenta el puerto en el que escucha MongoDB,
pero no lo publica fuera del Pod ni crea conectividad por sí sola; para eso será necesario un
Service en una entrega posterior.

Como todavía no se introdujeron los Secrets de Kubernetes, para la ejecución se completó la
contraseña directamente en los manifiestos. Antes de versionarlos se restituyó el marcador
`REEMPLAZAR_ANTES_DE_APLICAR`; en el informe las salidas se muestran como `[REDACTED]` para evitar
divulgar la credencial utilizada.

Validamos el archivo nuevamente en modo local. La salida confirma que Kubernetes acepta su
estructura, pero la indicación `(dry run)` demuestra que el Pod aún no fue creado:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply --dry-run=client -f k8s/pod-catalogo-db.yaml
  pod/catalogo-db created (dry run)
  ```
]

Solicitamos también el objeto normalizado que produciría `kubectl`. El resultado incorpora el
namespace `catalogo-app` definido en el contexto y la anotación utilizada por `kubectl apply` para
registrar la última configuración aplicada. Estos datos aparecen en la representación generada,
pero el comando no modifica el archivo fuente ni crea recursos en el clúster.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply --dry-run=client \
    -f k8s/pod-catalogo-db.yaml \
    -o yaml
  apiVersion: v1
  kind: Pod
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"labels":{"run":"catalogo-db"},"name":"catalogo-db","namespace":"catalogo-app"},"spec":{"containers":[{"env":[{"name":"MONGO_INITDB_ROOT_USERNAME","value":"catalogo_user"},{"name":"MONGO_INITDB_ROOT_PASSWORD","value":"[REDACTED]"}],"image":"mongo:7","name":"catalogo-db","ports":[{"containerPort":27017,"protocol":"TCP"}]}],"restartPolicy":"Always"}}
    labels:
      run: catalogo-db
    name: catalogo-db
    namespace: catalogo-app
  spec:
    containers:
    - env:
      - name: MONGO_INITDB_ROOT_USERNAME
        value: catalogo_user
      - name: MONGO_INITDB_ROOT_PASSWORD
        value: '[REDACTED]'
      image: mongo:7
      name: catalogo-db
      ports:
      - containerPort: 27017
        protocol: TCP
    restartPolicy: Always
  ```
]

#consigna(4)[
  Escribir los otros dos manifiestos —`pod-catalogo-api.yaml`, con `ROOT_PATH=/api` entre sus
  variables, y `pod-catalogo-frontend.yaml`— con las variables de entorno de la tercera semana,
  y aplicar los tres *en ese orden*, observando el estado con `kubectl get pods -o wide` y
  `kubectl get pods -w`. Registrar la dirección IP que recibe cada Pod.
]

#resolucion[
  Generamos los manifiestos de la API y del frontend con `kubectl run --dry-run=client`, de la
  misma forma que el manifiesto de MongoDB, y luego incorporamos las variables de entorno de la
  tercera semana. En ambos casos usamos los nombres completos de Docker Hub para que el nodo
  pueda descargar las imágenes. La API conserva `ROOT_PATH=/api`, tal como exige la consigna.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl run catalogo-api \
    --image=leandromurillo/catalogo-api:v1 \
    --port=8000 \
    --dry-run=client \
    -o yaml > k8s/pod-catalogo-api.yaml
  homelab@rp5:~/Documents/catalogo-app$ kubectl run catalogo-frontend \
    --image=leandromurillo/catalogo-frontend:v1 \
    --port=8080 \
    --dry-run=client \
    -o yaml > k8s/pod-catalogo-frontend.yaml
  ```
]

Antes de crear recursos validamos conjuntamente los tres archivos. Las tres respuestas incluyen
`(dry run)`, por lo que esta operación solo comprueba los manifiestos:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply --dry-run=client -f k8s/pod-catalogo-db.yaml
  pod/catalogo-db created (dry run)
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply --dry-run=client -f k8s/pod-catalogo-api.yaml
  pod/catalogo-api created (dry run)
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply --dry-run=client -f k8s/pod-catalogo-frontend.yaml
  pod/catalogo-frontend created (dry run)
  ```
]

Aplicamos los manifiestos en el orden indicado: primero la base de datos, después la API y por
último el frontend. Este orden inicia las creaciones secuencialmente, pero no espera a que cada
aplicación esté lista; Kubernetes no proporciona un equivalente directo de `depends_on`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-db.yaml
  pod/catalogo-db created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-api.yaml
  pod/catalogo-api created
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-frontend.yaml
  pod/catalogo-frontend created
  ```
]

La primera consulta se realizó mientras el nodo descargaba y preparaba las imágenes. Por eso los
tres Pods aparecieron en `ContainerCreating` y todavía no tenían una dirección IP asignada:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -o wide
  NAME                READY   STATUS              RESTARTS   AGE   IP       NODE       NOMINATED NODE   READINESS GATES
  catalogo-api        0/1     ContainerCreating   0          31s   <none>   lmurillo   <none>           <none>
  catalogo-db         0/1     ContainerCreating   0          41s   <none>   lmurillo   <none>           <none>
  catalogo-frontend   0/1     ContainerCreating   0          18s   <none>   lmurillo   <none>           <none>
  ```
]

Con `-w` observamos la evolución de los estados. MongoDB alcanzó `Running` sin reinicios. La API
y el frontend llegaron a ejecutarse, terminaron con `Error` y fueron reiniciados; después de
repetirse el fallo, Kubernetes aplicó el estado `CrashLoopBackOff`. Las apariciones intermedias en
`Running` solo indican que el proceso acababa de iniciarse, no que permaneciera estable ni que la
aplicación estuviera preparada para atender solicitudes.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -w
  NAME                READY   STATUS              RESTARTS      AGE
  catalogo-api        0/1     ContainerCreating   0             2m56s
  catalogo-db         0/1     ContainerCreating   0             3m6s
  catalogo-frontend   0/1     ContainerCreating   0             2m43s
  catalogo-db         1/1     Running             0             4m8s
  catalogo-api        1/1     Running             0             7m54s
  catalogo-frontend   1/1     Running             0             9m37s
  catalogo-frontend   0/1     Error               0             9m59s
  catalogo-frontend   0/1     CrashLoopBackOff    1 (20s ago)   10m
  catalogo-api        0/1     Error               0             10m
  catalogo-frontend   1/1     Running             2 (25s ago)   10m
  catalogo-api        1/1     Running             1 (17s ago)   10m
  catalogo-frontend   0/1     Error               2 (33s ago)   10m
  catalogo-frontend   0/1     CrashLoopBackOff    2 (22s ago)   10m
  catalogo-frontend   1/1     Running             3 (27s ago)   10m
  catalogo-frontend   0/1     Error               3 (29s ago)   10m
  catalogo-api        0/1     Error               1 (73s ago)   11m
  catalogo-frontend   0/1     CrashLoopBackOff    3 (51s ago)   11m
  catalogo-api        0/1     CrashLoopBackOff    1 (14s ago)   11m
  catalogo-frontend   1/1     Running             4 (55s ago)   11m
  catalogo-api        1/1     Running             2 (19s ago)   11m
  catalogo-frontend   0/1     Error               4 (63s ago)   11m
  ^C
  ```
]

Una nueva vista ampliada permitió registrar las direcciones asignadas. Los tres Pods se ubicaron
en el nodo `lmurillo`: MongoDB recibió `10.244.0.8`, la API `10.244.0.9` y el frontend
`10.244.0.10`. Aunque la captura muestra momentáneamente la API en `Running`, sus dos reinicios y
la secuencia anterior prueban que no se encontraba estable; su causa se diagnostica en la
consigna siguiente.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods -o wide
  NAME                READY   STATUS    RESTARTS       AGE   IP            NODE       NOMINATED NODE   READINESS GATES
  catalogo-api        1/1     Running   2 (63s ago)    12m   10.244.0.9    lmurillo   <none>           <none>
  catalogo-db         1/1     Running   0              12m   10.244.0.8    lmurillo   <none>           <none>
  catalogo-frontend   0/1     Error     4 (102s ago)   12m   10.244.0.10   lmurillo   <none>           <none>
  ```
]

#pagebreak()

#consigna(5)[
  Diagnosticar el `CrashLoopBackOff` de la API. El fallo es esperado, y su causa constituye el
  contenido de la clase: `DB_HOST=catalogo-db` *no resuelve*, porque en Kubernetes un Pod no
  proporciona un nombre DNS a nadie —eso lo hace un *Service*, que todavía no existe—. Registrar
  la salida de `kubectl describe pod catalogo-api` y de `kubectl logs catalogo-api --previous`.

  Esta variante exige aquí una precisión adicional: el error que informa _pymongo_ es
  `ServerSelectionTimeoutError` y no `Authentication failed`. El primero significa que no se
  alcanzó la base de datos; el segundo, que se la alcanzó y rechazó las credenciales. Transcribir
  el mensaje obtenido, indicar cuál de los dos es y justificar por qué.
]

#resolucion[
  Seguimos el Pod de la API para observar un ciclo completo de ejecución y reinicio. La secuencia
  `Running` → `Error` → `CrashLoopBackOff` se repitió porque el proceso inicia, agota sus intentos
  de conexión y termina; Kubernetes lo reinicia y aumenta progresivamente la espera entre
  intentos.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api -w
  NAME           READY   STATUS             RESTARTS        AGE
  catalogo-api   1/1     Running            5 (2m13s ago)   18m
  catalogo-api   0/1     Error              5 (2m30s ago)   18m
  catalogo-api   0/1     CrashLoopBackOff   5 (78s ago)     20m
  catalogo-api   1/1     Running            6 (2m45s ago)   21m
  catalogo-api   0/1     Error              6 (3m54s ago)   22m
  ^C
  ```
]

Inspeccionamos el estado administrado por Kubernetes. La salida registra terminaciones con
`Reason: Error`, código de salida `3`, seis reinicios y Events de tipo `BackOff`. Esto confirma el
ciclo de fallos, pero la causa interna de Python debe buscarse en los logs del contenedor.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl describe pod catalogo-api
Name:             catalogo-api
Namespace:        catalogo-app
Priority:         0
Service Account:  default
Node:             lmurillo/172.16.20.19
Start Time:       Mon, 19 Oct 2026 21:56:25 -0300
Labels:           run=catalogo-api
Annotations:      <none>
Status:           Running
IP:               10.244.0.9
IPs:
  IP:  10.244.0.9
Containers:
  catalogo-api:
    Container ID:   containerd://67a0c48e90b09ce9c2e2cf6a8abbf2582afd1a597cc0dda1d21689774d5f83d7
    Image:          leandromurillo/catalogo-api:v1
    Image ID:       docker.io/leandromurillo/catalogo-api@sha256:9697dad233c5c53b928e4dba28da5a5bf30f14ea765225bafbe073786a5961ea
    Port:           8000/TCP
    Host Port:      0/TCP
    State:          Terminated
      Reason:       Error
      Exit Code:    3
      Started:      Mon, 19 Oct 2026 22:18:05 -0300
      Finished:     Mon, 19 Oct 2026 22:19:12 -0300
    Last State:     Terminated
      Reason:       Error
      Exit Code:    3
      Started:      Mon, 19 Oct 2026 22:14:14 -0300
      Finished:     Mon, 19 Oct 2026 22:15:20 -0300
    Ready:          False
    Restart Count:  6
    Environment:
      DB_HOST:      catalogo-db
      DB_PORT:      27017
      DB_NAME:      catalogodb
      DB_USER:      catalogo_user
      DB_PASSWORD:  [REDACTED]
      APP_VERSION:  v1
      ROOT_PATH:    /api
      SEED_DEMO:    true
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-4gpph (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  kube-api-access-4gpph:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  23m                 default-scheduler  Successfully assigned catalogo-app/catalogo-api to lmurillo
  Normal   Pulling    23m                 kubelet            spec.containers{catalogo-api}: Pulling image "leandromurillo/catalogo-api:v1"
  Normal   Pulled     17m                 kubelet            spec.containers{catalogo-api}: Successfully pulled image "leandromurillo/catalogo-api:v1" in 2m36.689s (6m14.671s including waiting). Image size: 58934122 bytes.
  Normal   Pulled     105s (x6 over 13m)  kubelet            spec.containers{catalogo-api}: Container image "leandromurillo/catalogo-api:v1" already present on machine and can be accessed by the pod
  Normal   Created    104s (x7 over 15m)  kubelet            spec.containers{catalogo-api}: Container created
  Normal   Started    103s (x7 over 15m)  kubelet            spec.containers{catalogo-api}: Container started
  Warning  BackOff    34s (x9 over 12m)   kubelet            spec.containers{catalogo-api}: Back-off restarting failed container catalogo-api in pod catalogo-api_catalogo-app(9f95a5dd-ac11-4e2a-8e3f-5b5d126004e0)
  ```
]

El primer intento de consultar `--previous` no devolvió los registros. En ese instante el
contenedor actual ya estaba terminado, por lo que la opción solicitó una ejecución todavía
anterior cuyos logs containerd no pudo recuperar:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl logs catalogo-api --previous
  unable to retrieve container logs for containerd://c2f1a2fbf32cf7f80361e168a8e903e1bc0c4447151cc0321277095924cde59d
  ```
]

Después del siguiente reinicio repetimos el comando. La ejecución recién terminada pasó a ser la
anterior y sus logs quedaron disponibles:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl logs catalogo-api --previous
INFO:     Started server process [1]
INFO:     Waiting for application startup.
[2026-10-20T01:18:17+0000] WARNING intento 1/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:23+0000] WARNING intento 2/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:29+0000] WARNING intento 3/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:35+0000] WARNING intento 4/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:42+0000] WARNING intento 5/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:48+0000] WARNING intento 6/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:18:54+0000] WARNING intento 7/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:19:00+0000] WARNING intento 8/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:19:06+0000] WARNING intento 9/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
[2026-10-20T01:19:12+0000] WARNING intento 10/10 de conexión falló: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>
ERROR:    Traceback (most recent call last):
  File "/home/catalogo/.local/lib/python3.12/site-packages/starlette/routing.py", line 693, in lifespan
    async with self.lifespan_context(app) as maybe_state:
               ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/contextlib.py", line 210, in __aenter__
    return await anext(self.gen)
           ^^^^^^^^^^^^^^^^^^^^^
  File "/main.py", line 199, in lifespan
    esperar_mongo()
  File "/main.py", line 183, in esperar_mongo
    cliente.admin.command("ping")
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/_csot.py", line 108, in csot_wrapper
    return func(self, *args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/database.py", line 893, in command
    with self.__client._conn_for_reads(read_preference, session, operation=command_name) as (
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/mongo_client.py", line 1375, in _conn_for_reads
    server = self._select_server(read_preference, session, operation)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/mongo_client.py", line 1322, in _select_server
    server = topology.select_server(
             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/topology.py", line 368, in select_server
    server = self._select_server(
             ^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/topology.py", line 346, in _select_server
    servers = self.select_servers(
              ^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/topology.py", line 253, in select_servers
    server_descriptions = self._select_servers_loop(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/catalogo/.local/lib/python3.12/site-packages/pymongo/topology.py", line 303, in _select_servers_loop
    raise ServerSelectionTimeoutError(
pymongo.errors.ServerSelectionTimeoutError: catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms), Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad6c155a487f4bd64fb658e, topology_type: Unknown, servers: [<ServerDescription ('catalogo-db', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('catalogo-db:27017: [Errno -2] Name or service not known (configured timeouts: socketTimeoutMS: 20000.0ms, connectTimeoutMS: 20000.0ms)')>]>

ERROR:    Application startup failed. Exiting.
  ```
]

El mensaje obtenido es `ServerSelectionTimeoutError` y su causa inmediata es
`[Errno -2] Name or service not known` para `catalogo-db:27017`. La API agotó diez intentos sin
poder resolver el nombre: un Pod no crea un registro DNS estable para otros Pods. Ese nombre solo
será resoluble cuando exista un Service llamado `catalogo-db`.

No se trata de `Authentication failed`. Ese error implicaría que la conexión alcanzó MongoDB y
que el servidor rechazó las credenciales. Aquí la resolución DNS falla antes de abrir una
conexión, por lo que MongoDB nunca tuvo oportunidad de autenticar al usuario. Los reintentos de la
aplicación retrasan la terminación y son útiles ante fallos transitorios, pero no pueden corregir
la ausencia permanente del Service.


#consigna(6)[
  Hacer funcionar la API por dirección IP, y comprender por qué ese procedimiento no constituye
  una solución. Reemplazar el valor de `DB_HOST` por la *dirección IP del Pod* de la base de
  datos, volver a aplicar el manifiesto y comprobar que la API alcanza el estado `Running`. A
  continuación, eliminar el Pod de la base de datos, volver a crearlo con el mismo manifiesto y
  registrar su dirección IP nueva. La API vuelve a fallar. Redactar la conclusión: *la dirección
  IP de un Pod es descartable*, y en ese hecho reside la razón de existir de los Services.
]

#resolucion[
  Consultamos la dirección de MongoDB antes de modificar la API. Tanto la vista ampliada como la
  consulta JSONPath identificaron `10.244.0.8` como la IP del Pod original.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-db -o wide
  NAME          READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
  catalogo-db   1/1     Running   0          33m   10.244.0.8   lmurillo   <none>           <none>
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-db -o jsonpath='{.status.podIP}{"\n"}'
  10.244.0.8
  ```
]

Reemplazamos temporalmente `DB_HOST` por `10.244.0.8` en `pod-catalogo-api.yaml`. Como las
variables de entorno de un Pod no se pueden actualizar en el lugar, eliminamos la instancia
anterior y aplicamos nuevamente el manifiesto.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api
  pod "catalogo-api" deleted from catalogo-app namespace
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-api.yaml
  pod/catalogo-api created
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api -w
  NAME           READY   STATUS    RESTARTS   AGE
  catalogo-api   1/1     Running   0          20s
  ^C
  ```
]

Los logs confirmaron que la dirección permitía alcanzar MongoDB, crear los índices y sembrar los
doce productos. La consulta interna a `/health` respondió además que tanto la API como la base de
datos estaban disponibles:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl logs catalogo-api
  INFO:     Started server process [1]
  INFO:     Waiting for application startup.
  [2026-10-20T01:32:49+0000] INFO conexión a MongoDB establecida (base=catalogodb)
  [2026-10-20T01:32:50+0000] INFO catálogo de demo sembrado (12 productos)
  INFO:     Application startup complete.
  INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
  homelab@rp5:~/Documents/catalogo-app$ kubectl exec catalogo-api -- python -c \
    "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health').read().decode())"
  {"status":"ok","db":"ok","version":"v1"}
  ```
]

Registramos nuevamente la IP original y recreamos únicamente el Pod de MongoDB con el mismo
manifiesto. La nueva instancia alcanzó `Running`, pero recibió `10.244.0.12` en lugar de
`10.244.0.8`:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-db -o wide
  NAME          READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
  catalogo-db   1/1     Running   0          37m   10.244.0.8   lmurillo   <none>           <none>
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-db
  pod "catalogo-db" deleted from catalogo-app namespace
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-db.yaml
  pod/catalogo-db created
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-db -w
  NAME          READY   STATUS              RESTARTS   AGE
  catalogo-db   0/1     ContainerCreating   0          9s
  catalogo-db   1/1     Running             0          13s
  ^C
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-db -o wide
  NAME          READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
  catalogo-db   1/1     Running   0          25s   10.244.0.12   lmurillo   <none>           <none>
  ```
]

La API continuó ejecutándose porque no existe una probe que haga depender el estado del proceso
de MongoDB, pero seguía configurada con la IP descartada `10.244.0.8`. Su endpoint `/health`
intentó comprobar la base de datos y respondió `503 Service Unavailable`; por lo tanto, un Pod en
estado `Running` no implica que todas sus dependencias estén disponibles.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl exec catalogo-api -- python -c \
    "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health').read().decode())"
  Traceback (most recent call last):
    File "<string>", line 1, in <module>
    File "/usr/local/lib/python3.12/urllib/request.py", line 215, in urlopen
      return opener.open(url, data, timeout)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    File "/usr/local/lib/python3.12/urllib/request.py", line 521, in open
      response = meth(req, response)
                 ^^^^^^^^^^^^^^^^^^^
    File "/usr/local/lib/python3.12/urllib/request.py", line 630, in http_response
      response = self.parent.error(
                 ^^^^^^^^^^^^^^^^^^
    File "/usr/local/lib/python3.12/urllib/request.py", line 559, in error
      return self._call_chain(*args)
             ^^^^^^^^^^^^^^^^^^^^^^^
    File "/usr/local/lib/python3.12/urllib/request.py", line 492, in _call_chain
      result = func(*args)
               ^^^^^^^^^^^
    File "/usr/local/lib/python3.12/urllib/request.py", line 639, in http_error_default
      raise HTTPError(req.full_url, code, msg, hdrs, fp)
  urllib.error.HTTPError: HTTP Error 503: Service Unavailable
  command terminated with exit code 1
  ```
]

La prueba demuestra que una IP pertenece a una instancia concreta y se pierde al eliminar el
Pod. Configurar esa dirección acopla la API a un recurso descartable. Un Service resolverá este
problema al ofrecer una identidad DNS y una dirección virtual estables, independientes de las IP
que reciban los Pods reemplazados.

Finalmente restituimos `DB_HOST=catalogo-db` en el manifiesto y recreamos la API. La entrega queda
deliberadamente sin conectividad hasta incorporar el Service, pero ya no conserva una IP efímera
como configuración permanente.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api
  pod "catalogo-api" deleted from catalogo-app namespace
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-api.yaml
  pod/catalogo-api created
  ```
]

#consigna(7)[
  Aplicar `pod-catalogo-frontend.yaml` y comprobar que termina con el mensaje
  `host not found in upstream`, por tercera vez en el curso. Comparar en el `README.md` este caso
  con el de la tercera semana: el error es idéntico y la causa es distinta —entonces faltaba la
  red; ahora falta el *Service*—.
]

#resolucion[
  Antes de repetir la prueba verificamos el contexto y el namespace efectivos. Ambos valores
  confirman que los comandos se dirigieron al clúster `lmurillo` y al ámbito `catalogo-app`, donde
  se habían creado los tres Pods.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl config current-context
  lmurillo
  homelab@rp5:~/Documents/catalogo-app$ kubectl config view --minify -o jsonpath='{..namespace}{"\n"}'
  catalogo-app
  ```
]

La primera aplicación no produjo cambios porque el Pod creado en la consigna 4 todavía existía y
su especificación coincidía con el manifiesto. Como `kubectl apply` no reinicia un recurso que no
cambió, eliminamos el Pod y volvimos a aplicar el archivo para observar un ciclo de arranque desde
el comienzo.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-frontend.yaml
  pod/catalogo-frontend unchanged
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-frontend
  pod "catalogo-frontend" deleted from catalogo-app namespace
  homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-frontend.yaml
  pod/catalogo-frontend created
  ```
]

La observación continua mostró que el contenedor alcanzaba `Running` solo durante un instante,
terminaba con `Error` y era reiniciado. Después de varios intentos, Kubernetes aplicó esperas
progresivas y mostró `CrashLoopBackOff`. La política `restartPolicy: Always` explica los reinicios,
pero no corrige la causa que hace terminar a nginx.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-frontend -w
  NAME                READY   STATUS              RESTARTS      AGE
  catalogo-frontend   0/1     ContainerCreating   0             13s
  catalogo-frontend   1/1     Running             0             16s
  catalogo-frontend   0/1     Error               0             17s
  catalogo-frontend   1/1     Running             1 (6s ago)    20s
  catalogo-frontend   0/1     Error               1 (8s ago)    22s
  catalogo-frontend   0/1     CrashLoopBackOff    1 (14s ago)   33s
  catalogo-frontend   1/1     Running             2 (18s ago)   37s
  catalogo-frontend   0/1     Error               2 (19s ago)   38s
  catalogo-frontend   0/1     CrashLoopBackOff    2 (29s ago)   64s
  catalogo-frontend   1/1     Running             3 (33s ago)   68s
  catalogo-frontend   0/1     Error               3 (34s ago)   69s
  ^C
  ```
]

Los logs exponen la causa interna. El _entrypoint_ sustituyó `API_HOST` y `API_PORT` en la plantilla
de configuración, pero nginx no pudo resolver `catalogo-api` al validar el `proxy_pass`; por eso
terminó inmediatamente con un error de nivel `emerg`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl logs catalogo-frontend
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
  2026/10/20 19:48:23 [emerg] 1#1: host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
  nginx: [emerg] host not found in upstream "catalogo-api" in /etc/nginx/conf.d/default.conf:24
  ```
]

La inspección del Pod corroboró el diagnóstico: el contenedor terminó con código 1, no estaba
preparado, acumulaba cuatro reinicios y el evento `BackOff` registraba los intentos fallidos. Las
variables muestran además que nginx intentaba comunicarse con `catalogo-api` por el puerto `8000`.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl describe pod catalogo-frontend
  Name:             catalogo-frontend
  Namespace:        catalogo-app
  Priority:         0
  Service Account:  default
  Node:             lmurillo/172.16.20.19
  Start Time:       Tue, 20 Oct 2026 16:47:22 -0300
  Labels:           run=catalogo-frontend
  Annotations:      <none>
  Status:           Running
  IP:               10.244.0.14
  IPs:
    IP:  10.244.0.14
  Containers:
    catalogo-frontend:
      Container ID:   containerd://dc201367cb4ef7389c6d4a087379b98e21f7217b14caf7cdf1929af265404b24
      Image:          leandromurillo/catalogo-frontend:v1
      Image ID:       docker.io/leandromurillo/catalogo-frontend@sha256:6eba7092ff336ced7ecf6b5d79007625beada079c8b8b7478561e151f133ada1
      Port:           8080/TCP
      Host Port:      0/TCP
      State:          Terminated
        Reason:       Error
        Exit Code:    1
        Started:      Tue, 20 Oct 2026 16:49:19 -0300
        Finished:     Tue, 20 Oct 2026 16:49:19 -0300
      Last State:     Terminated
        Reason:       Error
        Exit Code:    1
        Started:      Tue, 20 Oct 2026 16:48:23 -0300
        Finished:     Tue, 20 Oct 2026 16:48:23 -0300
      Ready:          False
      Restart Count:  4
      Environment:
        API_HOST:  catalogo-api
        API_PORT:  8000
      Mounts:
        /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-rwrgj (ro)
  Conditions:
    Type                        Status
    PodReadyToStartContainers   True
    Initialized                 True
    Ready                       False
    ContainersReady             False
    PodScheduled                True
  Volumes:
    kube-api-access-rwrgj:
      Type:                    Projected (a volume that contains injected data from multiple sources)
      TokenExpirationSeconds:  3607
      ConfigMapName:           kube-root-ca.crt
      Optional:                false
      DownwardAPI:             true
  QoS Class:                   BestEffort
  Node-Selectors:              <none>
  Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                               node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
  Events:
    Type     Reason     Age                  From               Message
    ----     ------     ----                 ----               -------
    Normal   Scheduled  2m32s                default-scheduler  Successfully assigned catalogo-app/catalogo-frontend to lmurillo
    Normal   Pulled     37s (x5 over 2m27s)  kubelet            spec.containers{catalogo-frontend}: Container image "leandromurillo/catalogo-frontend:v1" already present on machine and can be accessed by the pod
    Normal   Created    35s (x5 over 2m24s)  kubelet            spec.containers{catalogo-frontend}: Container created
    Normal   Started    35s (x5 over 2m23s)  kubelet            spec.containers{catalogo-frontend}: Container started
    Warning  BackOff    33s (x4 over 2m16s)  kubelet            spec.containers{catalogo-frontend}: Back-off restarting failed container catalogo-frontend in pod catalogo-frontend_catalogo-app(bb8b21a7-e5f0-4727-a7b9-8e35371c1ffe)
  ```
]

El mensaje coincide con el documentado para la tercera semana, pero no su causa. En la ejecución
manual con Docker, los contenedores debían compartir la red `catalogo-net` para que el DNS interno
resolviera `catalogo-api`; sin esa red, nginx no podía encontrar el upstream. En Kubernetes la red
de Pods sí existe, pero el nombre de un Pod no constituye una identidad DNS estable para los demás
Pods. Esa identidad la proporciona un Service y todavía no se creó ninguno llamado
`catalogo-api`. Por lo tanto, el error vuelve a ser `host not found in upstream`, ahora debido a la
ausencia del Service y no a la ausencia de una red compartida.

#consigna(8)[
  Acceder a la API sin Service, mediante `kubectl port-forward pod/catalogo-api 8000:8000`, y
  registrar las salidas de `curl -s localhost:8000/health` y
  `curl -s localhost:8000/productos`. Comprobar además que `http://localhost:8000/docs` *no
  funciona*, y explicar por qué: con `ROOT_PATH=/api`, FastAPI genera las direcciones con ese
  prefijo y aquí no hay ningún proxy que lo agregue. No se trata de un error, sino de la
  consecuencia directa de una decisión tomada en la tercera semana. Dejar consignado que
  `port-forward` constituye una herramienta de *depuración* y no un mecanismo de publicación.
]

#resolucion[
  Como el Pod de la API había sido recreado al restituir `DB_HOST=catalogo-db`, se encontraba en
  `CrashLoopBackOff`. Para efectuar la prueba lo recreamos temporalmente con la nueva IP de
  MongoDB y, una vez iniciado, restituimos en el archivo tanto el nombre `catalogo-db` como el
  marcador de la contraseña sin volver a aplicar el manifiesto. La ausencia de salida de
  `git diff` confirma que el archivo no conservó la IP descartable ni la credencial utilizada.
]

#comandos[
  ```text
homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api
pod "catalogo-api" deleted from catalogo-app namespace
homelab@rp5:~/Documents/catalogo-app$ kubectl apply -f k8s/pod-catalogo-api.yaml
pod/catalogo-api created
homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api -w
NAME           READY   STATUS    RESTARTS   AGE
catalogo-api   1/1     Running   0          46s
^Chomelab@rp5:~/Documents/catalogo-app$ kubectl logs catalogo-api
INFO:     Started server process [1]
INFO:     Waiting for application startup.
[2026-10-20T20:22:03+0000] WARNING intento 1/10 de conexión falló: No servers found yet, Timeout: 3.0s, Topology Description: <TopologyDescription id: 6ad7cd68304c42d79ac6431a, topology_type: Unknown, servers: [<ServerDescription ('10.244.0.12', 27017) server_type: Unknown, rtt: None>]>
[2026-10-20T20:22:18+0000] INFO conexión a MongoDB establecida (base=catalogodb)
[2026-10-20T20:22:19+0000] INFO catálogo de demo sembrado (12 productos)
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api
NAME           READY   STATUS    RESTARTS   AGE
catalogo-api   1/1     Running   0          92s
homelab@rp5:~/Documents/catalogo-app$ git diff -- k8s/pod-catalogo-api.yaml
homelab@rp5:~/Documents/catalogo-app$ kubectl port-forward pod/catalogo-api 8000:8000
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
Handling connection for 8000
^Chomelab@rp5:~/Documents/catalogo-app$

homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/health
{"status":"ok","db":"ok","version":"v1"}homelab@rp5:~/Documents/catalogo-app$ curl -s localhost:8000/productos
[{"nombre":"Apple iPhone 6 (Gold, 32 GB)","categoria":"Apple","creado_en":"2026-10-20T20:22:19.587000","descripcion":"Clásico de 4.7\" con Touch ID y cuerpo de aluminio.","imagen_hash":"7e23251b780a76a1","imagen_tipo":"image/jpeg","precio":44000,"sku":999666,"stock":2,"id":"6ad7cd7b68fed007a0b5bf84","imagen":true},{"nombre":"Apple iPhone 8 Plus (Silver, 64 GB)","categoria":"Apple","creado_en":"2026-10-20T20:22:19.799000","descripcion":"Pantalla Retina HD de 5.5\", carga inalámbrica y chip A11.","imagen_hash":"27cf5a0cc72a5c03","imagen_tipo":"image/jpeg","precio":48000,"sku":379182,"stock":6,"id":"6ad7cd7b68fed007a0b5bf8a","imagen":true},{"nombre":"Apple iPhone X (Space Gray, 256 GB)","categoria":"Apple","creado_en":"2026-10-20T20:22:19.468000","descripcion":"Super Retina de 5.8\", Face ID y chip A11 Bionic.","imagen_hash":"8101c6ff7c22f74d","imagen_tipo":"image/jpeg","precio":25000,"sku":456654,"stock":3,"id":"6ad7cd7b68fed007a0b5bf7a","imagen":true},{"nombre":"Asus ZenFone Max M1 (Black, 32 GB) (3 GB RAM)","categoria":"Asus","creado_en":"2026-10-20T20:22:19.514000","descripcion":"Batería de 4000 mAh que funciona también como power bank.","imagen_hash":"95255abbb146483b","imagen_tipo":"image/jpeg","precio":84000,"sku":963852,"stock":0,"id":"6ad7cd7b68fed007a0b5bf82","imagen":true},{"nombre":"Honor 9N (Midnight Black, 32 GB) (3 GB RAM)","categoria":"Honor","creado_en":"2026-10-20T20:22:19.470000","descripcion":"Pantalla FullView de 5.84\" con notch y cámara dual de 13 MP.","imagen_hash":"1e45d7360052e1e1","imagen_tipo":"image/jpeg","precio":39000,"sku":123222,"stock":11,"id":"6ad7cd7b68fed007a0b5bf7e","imagen":true},{"nombre":"Lenovo K8 Note (Venom Black, 64 GB) (4 GB RAM)","categoria":"Lenovo","creado_en":"2026-10-20T20:22:19.481000","descripcion":"Procesador Helio X23 de diez núcleos y Android puro.","imagen_hash":"5bf64a1fb53294cd","imagen_tipo":"image/jpeg","precio":36000,"sku":741852,"stock":5,"id":"6ad7cd7b68fed007a0b5bf80","imagen":true},{"nombre":"OPPO K1 (Piano Black, 64 GB) (4 GB RAM)","categoria":"OPPO","creado_en":"2026-10-20T20:22:19.466000","descripcion":"Lector de huellas bajo la pantalla AMOLED y cámara frontal de 25 MP.","imagen_hash":"24b3652bc891267c","imagen_tipo":"image/jpeg","precio":65000,"sku":357842,"stock":6,"id":"6ad7cd7b68fed007a0b5bf78","imagen":true},{"nombre":"Redmi Y2 (Black, 32 GB) (3 GB RAM)","categoria":"Xiaomi","creado_en":"2026-10-20T20:22:18.150000","descripcion":"Pantalla 5.99\" HD+, cámara dual de 12 MP y batería de 3080 mAh.","imagen_hash":"3926b6235eecc7b3","imagen_tipo":"image/jpeg","precio":25000,"sku":852369,"stock":14,"id":"6ad7cd7b68fed007a0b5bf74","imagen":true},{"nombre":"Samsung Galaxy A8 Star (White, 64 GB) (6 GB RAM)","categoria":"Samsung","creado_en":"2026-10-20T20:22:19.778000","descripcion":"Super AMOLED de 6.3\" y cámara dual de 16 MP + 24 MP.","imagen_hash":"6e0b6f7b0f8514c0","imagen_tipo":"image/jpeg","precio":78000,"sku":848484,"stock":8,"id":"6ad7cd7b68fed007a0b5bf88","imagen":true},{"nombre":"Samsung Galaxy A9 (Bubblegum Pink, 128 GB)","categoria":"Samsung","creado_en":"2026-10-20T20:22:19.692000","descripcion":"Primer smartphone con cuatro cámaras traseras y pantalla de 6.3\".","imagen_hash":"97b0b86fea2f5dc7","imagen_tipo":"image/jpeg","precio":97000,"sku":332211,"stock":4,"id":"6ad7cd7b68fed007a0b5bf86","imagen":true},{"nombre":"Samsung Galaxy M20 (Charcoal Black, 4+64GB)","categoria":"Samsung","creado_en":"2026-10-20T20:22:19.465000","descripcion":"Batería de 5000 mAh con carga rápida y pantalla Infinity-V de 6.3\".","imagen_hash":"178a6127bb70f3cb","imagen_tipo":"image/jpeg","precio":58000,"sku":159753,"stock":9,"id":"6ad7cd7b68fed007a0b5bf76","imagen":true},{"nombre":"Vivo V15 Pro (Topaz Blue, 128 GB) (6 GB RAM)","categoria":"Vivo","creado_en":"2026-10-20T20:22:19.469000","descripcion":"Cámara frontal pop-up de 32 MP y triple cámara trasera de 48 MP.","imagen_hash":"11814686e87c1818","imagen_tipo":"image/jpeg","precio":55000,"sku":358426,"stock":7,"id":"6ad7cd7b68fed007a0b5bf7c","imagen":true}]homelcurl -s -o /dev/null -w 'HTTP %{http_code}\n' localhost:8000/api/openapi.json' localhost:8000/api/openapi.json
HTTP 200
homelab@rp5:~/Documents/catalogo-app$ curl -s -o /dev/null -w 'HTTP %{http_code}\n' localhost:8000/openapi.json
HTTP 200
homelab@rp5:~/Documents/catalogo-app$ ^C
homelab@rp5:~/Documents/catalogo-app$
  ```
]

El Pod alcanzó `Running` sin reinicios. El primer intento de conexión encontró a MongoDB todavía
no disponible, pero los reintentos de la aplicación permitieron establecer la conexión, sembrar
los doce productos y completar el arranque. A continuación, `port-forward` abrió un túnel entre el
puerto `8000` de la máquina local y el mismo puerto del Pod. Las líneas `Handling connection`
registran las solicitudes transportadas mientras el comando permaneció activo.

La consulta a `/health` confirmó que tanto la API como MongoDB respondían correctamente, y
`/productos` devolvió el catálogo completo. El acceso se realizó directamente al Pod, sin crear un
Service ni publicar un puerto permanente en el nodo.

Repetimos de forma limpia las comprobaciones de la documentación y del esquema OpenAPI. Contra lo
esperado por la consigna, las tres direcciones respondieron con estado `200` y la interfaz de
Swagger mostró correctamente las operaciones de la API.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ curl -s -o /dev/null -w 'docs: HTTP %{http_code}\n' localhost:8000/docs
  docs: HTTP 200
  homelab@rp5:~/Documents/catalogo-app$ curl -s -o /dev/null -w 'OpenAPI con prefijo: HTTP %{http_code}\n' localhost:8000/api/openapi.json
  OpenAPI con prefijo: HTTP 200
  homelab@rp5:~/Documents/catalogo-app$ curl -s -o /dev/null -w 'OpenAPI interno: HTTP %{http_code}\n' localhost:8000/openapi.json
  OpenAPI interno: HTTP 200
  ```
]

Verificamos dentro del contenedor las versiones responsables de este comportamiento. La imagen
ejecuta FastAPI 0.115.0 junto con Starlette 0.38.6:

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl exec catalogo-api -- python -c "import fastapi, starlette; print('FastAPI', fastapi.__version__); print('Starlette', starlette.__version__)"
  FastAPI 0.115.0
  Starlette 0.38.6
  ```
]

`ROOT_PATH=/api` hace que FastAPI informe el prefijo público en el _scope_ ASGI y genere para
Swagger la dirección `/api/openapi.json`. En Starlette 0.38.6, el enrutador elimina ese `root_path`
cuando está presente antes de comparar la dirección solicitada con las rutas internas. De este
modo, una solicitud a `/api/openapi.json` se compara internamente con `/openapi.json` y encuentra
el esquema. Si la solicitud llega directamente a `/openapi.json`, tampoco hay un prefijo que
eliminar y la misma ruta vuelve a coincidir. Por eso ambas direcciones respondieron `200` y
Swagger funcionó aun sin el proxy.

El resultado real no coincide con el `404` anticipado por el enunciado, pero no invalida la función
de `ROOT_PATH`: continúa describiendo el prefijo bajo el cual la aplicación se publica normalmente
detrás de nginx. La diferencia se debe al comportamiento de las versiones efectivamente
ejecutadas y se documenta sin reemplazar la evidencia por el resultado esperado.

Finalmente, `port-forward` constituye una herramienta de depuración y no un mecanismo de
publicación. El túnel depende del proceso local de `kubectl` y de un Pod concreto: termina al
presionar `Ctrl+C` y no proporciona una dirección estable, balanceo ni recuperación frente al
reemplazo del Pod. Esas responsabilidades corresponden a otros recursos de Kubernetes, entre
ellos los Services.


#pagebreak()

#consigna(9)[
  Comprobar que ningún componente vigila a los Pods. Eliminar el Pod de la API con
  `kubectl delete pod` y verificar con `kubectl get pods` que no se recrea. Un Pod es mortal y
  nadie lo resucita: ese hecho es exactamente el punto de partida de la clase siguiente.
]

#resolucion[
  Antes de eliminar el recurso comprobamos que `catalogo-api` existía, estaba preparado y llevaba
  dieciocho minutos en estado `Running` sin reinicios. De esta manera, su desaparición posterior
  puede atribuirse al comando de eliminación y no a un fallo de la aplicación.
]

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api
  NAME           READY   STATUS    RESTARTS   AGE
  catalogo-api   1/1     Running   0          18m
  homelab@rp5:~/Documents/catalogo-app$ kubectl delete pod catalogo-api
  pod "catalogo-api" deleted from catalogo-app namespace
  ```
]

La consulta posterior mostró únicamente a MongoDB y al frontend. La API no reapareció en la lista
y una búsqueda directa devolvió `NotFound`, confirmando que el objeto dejó de existir y que ningún
controlador creó un reemplazo.

#comandos[
  ```text
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pods
  NAME                READY   STATUS    RESTARTS        AGE
  catalogo-db         1/1     Running   0               19h
  catalogo-frontend   0/1     Error     15 (6m5s ago)   53m
  homelab@rp5:~/Documents/catalogo-app$ kubectl get pod catalogo-api
  Error from server (NotFound): pods "catalogo-api" not found
  ```
]

Los manifiestos de esta entrega crean objetos de tipo `Pod` directamente. El archivo
`pod-catalogo-api.yaml` guardado en el repositorio describe cómo volver a crearlo, pero no vigila
el clúster ni se aplica por sí solo. Para recuperar la API sería necesario ejecutar nuevamente
`kubectl apply`.

La política `restartPolicy: Always` tampoco cambia este resultado. Esa política permite que el
kubelet reinicie un contenedor que termina dentro de un Pod existente, como ocurrió con los
`CrashLoopBackOff` anteriores. Al eliminar el Pod se elimina también su especificación, incluida
la política de reinicio. Como no existe un Deployment, ReplicaSet ni otro controlador que declare
una cantidad deseada de réplicas, Kubernetes no tiene ningún estado que reconciliar y no crea un
Pod nuevo.

La prueba demuestra que un Pod suelto es un recurso mortal: una vez eliminado, permanece ausente.
En una etapa posterior, un Deployment asumirá la vigilancia y ordenará crear un reemplazo cuando
falte una de sus réplicas.

#consigna(10)[
  Incorporar al `README.md` un *cheatsheet propio* con los diez comandos de `kubectl`
  efectivamente utilizados y la descripción de lo que hace cada uno. No corresponde copiar el de
  la clase, sino redactar el propio.
]

#consigna(11)[
  Incorporar asimismo una sección que compare el `docker-compose.yml` de la semana anterior con
  los tres manifiestos de esta entrega, indicando qué se conservó, qué desapareció y qué todavía
  falta.
]

#resolucion[
  Los tres manifiestos reproducen la composición básica de la aplicación, pero todavía no
  trasladan todas las responsabilidades que Docker Compose resolvía en un único archivo. La
  comparación permite separar la configuración propia de los procesos de las funciones de
  coordinación que deberán incorporarse mediante otros recursos de Kubernetes.
]

*Qué se conservó.*

- La aplicación continúa dividida en frontend, API y MongoDB, ahora representados por tres Pods.
- Se mantienen las imágenes `mongo:7`, `catalogo-api:v1` y `catalogo-frontend:v1`; las dos imágenes
  propias utilizan además sus nombres completos de Docker Hub para que el nodo pueda descargarlas.
- Se trasladaron las principales variables de entorno de cada componente, incluidas las variables
  `DB_*`, `MONGO_INITDB_ROOT_*`, `API_*`, `APP_VERSION`, `SEED_DEMO` y `ROOT_PATH=/api`.
- Se conservaron los puertos internos `27017`, `8000` y `8080`. En Kubernetes, `containerPort`
  documenta el puerto del contenedor, pero no lo publica fuera del Pod.
- La API conserva sus reintentos de conexión a MongoDB. Esta defensa pertenece a la aplicación y
  sigue siendo necesaria aunque cambie el orquestador.

*Qué desapareció.*

- Las secciones `build` ya no existen: Kubernetes no construye las imágenes, sino que descarga las
  que fueron creadas y publicadas previamente en un registry.
- Desapareció la red de proyecto `catalogo-net` y, con ella, el DNS que Compose proporcionaba a los
  servicios por sus nombres. El clúster posee una red de Pods, pero los Pods sueltos no obtienen
  por ello una identidad DNS estable.
- Se eliminaron `depends_on` y sus condiciones `service_healthy`. Kubernetes no ordena el arranque
  de estos Pods ni espera que una dependencia esté saludable antes de iniciar otra.
- Los tres `healthcheck` de Compose no se trasladaron a probes de Kubernetes. Por eso `Running` no
  garantiza que un componente esté preparado ni que sus dependencias respondan.
- El volumen nombrado `catalogo-db-data` no tiene equivalente en el manifiesto de MongoDB. Los
  datos se almacenan en la capa escribible del contenedor y se pierden junto con el Pod.
- Desaparecieron las publicaciones de puertos `3000:8080` y `127.0.0.1:8000:8000`. En esta entrega
  ningún componente se publica de forma permanente; `port-forward` solo permitió depurarlo.
- Ya no se cargan variables desde `.env` ni se validan con las expresiones obligatorias de Compose.
  Los valores quedaron repetidos directamente en los manifiestos.
- Tampoco se trasladaron `cap_drop` y `cap_add`, por lo que los Pods no expresan mediante un
  `securityContext` la política de mínimo privilegio definida la semana anterior.
- Se perdió la administración conjunta que ofrecían `docker compose up` y `docker compose down`:
  cada manifiesto se aplica y elimina por separado.

*Qué todavía falta.*

- Services que proporcionen nombres DNS y direcciones virtuales estables para `catalogo-db` y
  `catalogo-api`, además de un punto de acceso adecuado para el frontend.
- Deployments y ReplicaSets que declaren la cantidad deseada de réplicas y recreen los Pods cuando
  desaparezcan.
- Un PersistentVolumeClaim para desacoplar los datos de MongoDB del ciclo de vida de su Pod.
- ConfigMaps para la configuración no sensible y Secrets para las credenciales, en lugar de
  escribir todos los valores directamente en los manifiestos.
- Probes de inicio, disponibilidad y vida. Junto con los reintentos de las aplicaciones, estas
  reemplazarán la coordinación basada en los `healthcheck` y `depends_on` de Compose.
- Un mecanismo de publicación, mediante Services y eventualmente un Ingress, que permita acceder
  a la aplicación sin depender de `port-forward`.
- Un `securityContext` que declare usuarios, capabilities y demás restricciones de ejecución, así
  como solicitudes y límites de recursos para que el scheduler pueda administrar la carga.

En síntesis, los Pods conservaron los procesos y su configuración básica, pero todavía faltan los
recursos que aportan descubrimiento, persistencia, salud, publicación y recuperación automática.
Esta entrega deja esas ausencias de manera deliberada: los fallos observados muestran por qué una
aplicación de Kubernetes no se resuelve únicamente convirtiendo cada servicio de Compose en un Pod.
