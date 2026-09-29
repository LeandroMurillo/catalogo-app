#set page(
  paper: "a4",
  margin: 2cm,
)

#set text(size: 11pt)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.")

#let completar(texto: "COMPLETAR ACÁ") = block(
  width: 100%,
  inset: 10pt,
  stroke: 0.6pt + rgb("#BBBBBB"),
  radius: 3pt,
)[
  #text(fill: rgb("#777777"), style: "italic")[#texto]
]


#let consola(titulo: "PowerShell", cuerpo) = block(
  width: 100%,
  inset: 0pt,
  fill: rgb("#1E1E1E"),
  stroke: 0.8pt + rgb("#444444"),
  radius: 6pt,
  breakable: true,
)[
  #block(
    width: 100%,
    inset: (x: 10pt, y: 6pt),
    fill: rgb("#2D2D30"),
  )[
    #text(fill: white, weight: "bold", size: 9pt)[#titulo]
  ]
  #block(
    width: 100%,
    inset: 10pt,
  )[
    #set text(
      font: "Courier New",
      size: 9pt,
      fill: rgb("#D4D4D4"),
    )
    #cuerpo
  ]
]

= Trabajo Práctico N° 1 — Variante C

Proyecto: `catalogo-app`

== 1) Preparación del repositorio

Crear el repositorio del proyecto en una carpeta denominada `catalogo-app/`, que contendrá
el código de la aplicación provisto por la cátedra —directorios `backend/` y `frontend/`—,
un archivo `README.md` propio y un archivo `.gitignore` que excluya:

```text
node_modules/
__pycache__/
.env
```

#completar(texto: "COMPLETAR ACÁ CON UNA BREVE DESCRIPCIÓN DE CÓMO QUEDÓ ORGANIZADO EL REPOSITORIO")

== 2) Arquitectura

Documentar en el `README.md` la arquitectura de tres capas del proyecto:

```text
navegador ──► catalogo-frontend ──────► catalogo-api ──────► catalogo-db
              React + Vite              Python + FastAPI     MongoDB 7
              nginx :8080               :8000                :27017
              (host 3000)               (host 8000, solo     (sin puerto
                                           depuración)          publicado)
```

| Capa | Imagen | Puerto interno | Puerto publicado |
| --- | --- | --- | --- |
| `catalogo-frontend` | React + Vite servido por nginx | 8080 | 3000 |
| `catalogo-api` | Python + FastAPI | 8000 | 8000 (solo depuración) |
| `catalogo-db` | MongoDB 7 | 27017 | — |

El frontend es el único punto de entrada: nadie le habla a la base directamente,
y a la API le habla el frontend.

3) Ejecutar el motor de base de datos sin configuración alguna y comprobar que, a diferencia de otros motores, el contenedor no finaliza con error:

```bash
docker run -d --name catalogo-db mongo:7
```

Para ello se deberá:

a) registrar la salida de ```bash docker ps```, que mostrará el contenedor en estado Up;

#consola[
  ```
  PS catalogo-app> docker ps
  CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS       NAMES
  3a36853fecf1   mongo:7   "docker-entrypoint.s…"   17 minutes ago   Up 17 minutes   27017/tcp   catalogo-db
  ```
]

#pagebreak()

b) Listar las bases existentes con `mongosh`, sin proporcionar credenciales, y consignar el resultado;

#consola[
  ```text
  PS catalogo-app> docker exec -it catalogo-db mongosh
  Current Mongosh Log ID: 6ab9ba1ee9de2a9a551ed964
  Connecting to:          mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.10.0
  Using MongoDB:          7.0.43
  Using Mongosh:          2.10.0

  For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/


  To help improve our products, anonymous usage data is collected and sent to MongoDB periodically (https://www.mongodb.com/legal/privacy-policy).
  You can opt-out by running the disableTelemetry() command.

  ------
     The server generated these startup warnings when booting
     2026-09-28T00:31:18.893+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
     2026-09-28T00:31:23.911+00:00: Access control is not enabled for the database. Read and write access to data and configuration is unrestricted
     2026-09-28T00:31:23.913+00:00: For customers running MongoDB 7.0, we suggest changing the contents of the following sysfsFile
  ------

  test> show dbs
  admin   40.00 KiB
  config  12.00 KiB
  local   40.00 KiB
  test> exit

  What's next:
      Try Docker Debug for seamless, persistent debugging tools in any container or image → docker debug catalogo-db
      Learn more at https://docs.docker.com/go/debug-cli/
  ```
]

c) Explicar, en dos o tres líneas, por qué esta situación resulta más riesgosa que un
contenedor que se detiene con un mensaje de error.

#completar()

4) Consultar la documentación oficial de la imagen mongo en Docker Hub y determinar cuáles
son las variables de entorno que crean el usuario inicial. Ejecutar nuevamente el contenedor,
esta vez con el usuario catalogo_user y la contraseña catalogo_pass, y acompañar la
salida de docker logs -f hasta la aparición del mensaje que indica que el servidor se
encuentra a la espera de conexiones.

#consola[
  ```text
    PS catalogo-app> docker run -d --name catalogo-db -e MONGO_INITDB_ROOT_USERNAME=catalogo_user -e MONGO_INITDB_ROOT_PASSWORD=catalogo_pass mongo:7
    eb1a675c0dcb77b228a7aa3ed3e544ce01909a73b12b828616be0e0418dbbac3
    PS catalogo-app> docker logs -f catalogo-db
  about to fork child process, waiting until server is ready for connections.
  forked process: 28

  {"t":{"$date":"2026-09-28T01:40:30.586+00:00"},"s":"I",  "c":"CONTROL",  "id":20698,   "ctx":"main","msg":"***** SERVER RESTARTED *****"}
  {"t":{"$date":"2026-09-28T01:40:30.614+00:00"},"s":"I",  "c":"NETWORK",  "id":4915701, "ctx":"main","msg":"Initialized wire specification","attr":{"spec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:30.615+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"parallel execution pool","numThreads":0,"minThreads":0,"maxThreads":128}}
  {"t":{"$date":"2026-09-28T01:40:30.617+00:00"},"s":"I",  "c":"CONTROL",  "id":23285,   "ctx":"main","msg":"Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'"}
  {"t":{"$date":"2026-09-28T01:40:30.624+00:00"},"s":"I",  "c":"NETWORK",  "id":4648601, "ctx":"main","msg":"Implicit TCP FastOpen unavailable. If TCP FastOpen is required, set tcpFastOpenServer, tcpFastOpenClient, and tcpFastOpenQueueSize."}
  {"t":{"$date":"2026-09-28T01:40:30.633+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"OCSPCache","numThreads":0,"minThreads":0,"maxThreads":8}}
  {"t":{"$date":"2026-09-28T01:40:30.642+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"AuthorizationManager","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:30.643+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool1","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:30.644+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool2","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:30.648+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"IndexBuildsCoordinatorMongod","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:30.650+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationDonorService","namespace":"config.tenantMigrationDonors"}}
  {"t":{"$date":"2026-09-28T01:40:30.651+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationRecipientService","namespace":"config.tenantMigrationRecipients"}}
  {"t":{"$date":"2026-09-28T01:40:30.651+00:00"},"s":"W",  "c":"NETWORK",  "id":11621101,"ctx":"main","msg":"Overriding max connections to honor `capMemoryConsumptionForPreAuthBuffers` settings","attr":{"limit":49369}}
  {"t":{"$date":"2026-09-28T01:40:30.651+00:00"},"s":"I",  "c":"CONTROL",  "id":5945603, "ctx":"main","msg":"Multi threading initialized"}
  {"t":{"$date":"2026-09-28T01:40:30.652+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ReadWriteConcernDefaults","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:30.652+00:00"},"s":"I",  "c":"TENANT_M", "id":7091600, "ctx":"main","msg":"Starting TenantMigrationAccessBlockerRegistry"}
  {"t":{"$date":"2026-09-28T01:40:30.653+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"TenantMigrationBlockerAsyncThreadPool","numThreads":0,"minThreads":0,"maxThreads":4}}
  {"t":{"$date":"2026-09-28T01:40:30.659+00:00"},"s":"I",  "c":"CONTROL",  "id":4615611, "ctx":"initandlisten","msg":"MongoDB starting","attr":{"pid":28,"port":27017,"dbPath":"/data/db","architecture":"64-bit","host":"eb1a675c0dcb"}}
  {"t":{"$date":"2026-09-28T01:40:30.660+00:00"},"s":"I",  "c":"CONTROL",  "id":23403,   "ctx":"initandlisten","msg":"Build Info","attr":{"buildInfo":{"version":"7.0.43","gitVersion":"ef5a7d3480b59feae13d564376129fc4ceee6177","openSSLVersion":"OpenSSL 3.0.2 15 Mar 2022","modules":[],"allocator":"tcmalloc","environment":{"distmod":"ubuntu2204","distarch":"x86_64","target_arch":"x86_64"}}}}
  {"t":{"$date":"2026-09-28T01:40:30.660+00:00"},"s":"I",  "c":"CONTROL",  "id":51765,   "ctx":"initandlisten","msg":"Operating System","attr":{"os":{"name":"Ubuntu","version":"22.04"}}}
  {"t":{"$date":"2026-09-28T01:40:30.660+00:00"},"s":"I",  "c":"CONTROL",  "id":21951,   "ctx":"initandlisten","msg":"Options set by command line","attr":{"options":{"net":{"bindIp":"127.0.0.1","port":27017,"tls":{"mode":"disabled"}},"processManagement":{"fork":true,"pidFilePath":"/tmp/docker-entrypoint-temp-mongod.pid"},"systemLog":{"destination":"file","logAppend":true,"path":"/proc/1/fd/1"}}}}
  {"t":{"$date":"2026-09-28T01:40:30.660+00:00"},"s":"W",  "c":"NETWORK",  "id":11621101,"ctx":"initandlisten","msg":"Overriding max connections to honor `capMemoryConsumptionForPreAuthBuffers` settings","attr":{"limit":49369}}
  {"t":{"$date":"2026-09-28T01:40:30.661+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"OCSPManagerHTTP","numThreads":0,"minThreads":1,"maxThreads":10}}
  {"t":{"$date":"2026-09-28T01:40:30.672+00:00"},"s":"I",  "c":"STORAGE",  "id":22297,   "ctx":"initandlisten","msg":"Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem","tags":["startupWarnings"]}
  {"t":{"$date":"2026-09-28T01:40:30.676+00:00"},"s":"I",  "c":"STORAGE",  "id":22315,   "ctx":"initandlisten","msg":"Opening WiredTiger","attr":{"config":"create,cache_size=1416M,session_max=33000,eviction=(threads_min=4,threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,remove=true,path=journal,compressor=snappy),builtin_extension_config=(zstd=(compression_level=6)),file_manager=(close_idle_time=600,close_scan_interval=10,close_handle_minimum=2000),statistics_log=(wait=0),json_output=(error,message),verbose=[recovery_progress:1,checkpoint_progress:1,compact_progress:1,backup:0,checkpoint:0,compact:0,evict:0,history_store:0,recovery:0,rts:0,salvage:0,tiered:0,timestamp:0,transaction:0,verify:0,log:0],"}}
  {"t":{"$date":"2026-09-28T01:40:31.580+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559631,"ts_usec":580283,"thread":"28:0x7f7256a67cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery log replay has successfully finished and ran for 0 milliseconds"}}}
  {"t":{"$date":"2026-09-28T01:40:31.580+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559631,"ts_usec":580398,"thread":"28:0x7f7256a67cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Set global recovery timestamp: (0, 0)"}}}
  {"t":{"$date":"2026-09-28T01:40:31.580+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559631,"ts_usec":580415,"thread":"28:0x7f7256a67cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Set global oldest timestamp: (0, 0)"}}}
  {"t":{"$date":"2026-09-28T01:40:31.580+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559631,"ts_usec":580474,"thread":"28:0x7f7256a67cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery was completed successfully and took 0ms, including 0ms for the log replay, 0ms for the rollback to stable, and 0ms for the checkpoint."}}}
  {"t":{"$date":"2026-09-28T01:40:31.595+00:00"},"s":"I",  "c":"STORAGE",  "id":4795906, "ctx":"initandlisten","msg":"WiredTiger opened","attr":{"durationMillis":919}}
  {"t":{"$date":"2026-09-28T01:40:31.595+00:00"},"s":"I",  "c":"RECOVERY", "id":23987,   "ctx":"initandlisten","msg":"WiredTiger recoveryTimestamp","attr":{"recoveryTimestamp":{"$timestamp":{"t":0,"i":0}}}}
  {"t":{"$date":"2026-09-28T01:40:31.660+00:00"},"s":"W",  "c":"CONTROL",  "id":22120,   "ctx":"initandlisten","msg":"Access control is not enabled for the database. Read and write access to data and configuration is unrestricted","tags":["startupWarnings"]}
  {"t":{"$date":"2026-09-28T01:40:31.662+00:00"},"s":"W",  "c":"CONTROL",  "id":9068900, "ctx":"initandlisten","msg":"For customers running MongoDB 7.0, we suggest changing the contents of the following sysfsFile","attr":{"sysfsFile":"/sys/kernel/mm/transparent_hugepage","currentValue":"always","desiredValue":"never"},"tags":["startupWarnings"]}
  {"t":{"$date":"2026-09-28T01:40:31.664+00:00"},"s":"I",  "c":"STORAGE",  "id":20320,   "ctx":"initandlisten","msg":"createCollection","attr":{"namespace":"admin.system.version","uuidDisposition":"provided","uuid":{"uuid":{"$uuid":"51968e5e-bdb4-469c-9873-4992815b4009"}},"options":{"uuid":{"$uuid":"51968e5e-bdb4-469c-9873-4992815b4009"}}}}
  {"t":{"$date":"2026-09-28T01:40:31.689+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"initandlisten","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"51968e5e-bdb4-469c-9873-4992815b4009"}},"namespace":"admin.system.version","index":"_id_","ident":"index-1--7413776804062931694","collectionIdent":"collection-0--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:31.691+00:00"},"s":"I",  "c":"REPL",     "id":20459,   "ctx":"initandlisten","msg":"Setting featureCompatibilityVersion","attr":{"newVersion":"7.0"}}
  {"t":{"$date":"2026-09-28T01:40:31.691+00:00"},"s":"I",  "c":"REPL",     "id":5853300, "ctx":"initandlisten","msg":"current featureCompatibilityVersion value","attr":{"featureCompatibilityVersion":"7.0","context":"setFCV"}}
  {"t":{"$date":"2026-09-28T01:40:31.691+00:00"},"s":"I",  "c":"NETWORK",  "id":4915702, "ctx":"initandlisten","msg":"Updated wire specification","attr":{"oldSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true},"newSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":21,"maxWireVersion":21},"outgoing":{"minWireVersion":21,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:31.692+00:00"},"s":"I",  "c":"NETWORK",  "id":4915702, "ctx":"initandlisten","msg":"Updated wire specification","attr":{"oldSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":21,"maxWireVersion":21},"outgoing":{"minWireVersion":21,"maxWireVersion":21},"isInternalClient":true},"newSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":21,"maxWireVersion":21},"outgoing":{"minWireVersion":21,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:31.692+00:00"},"s":"I",  "c":"REPL",     "id":5853300, "ctx":"initandlisten","msg":"current featureCompatibilityVersion value","attr":{"featureCompatibilityVersion":"7.0","context":"startup"}}
  {"t":{"$date":"2026-09-28T01:40:31.692+00:00"},"s":"I",  "c":"STORAGE",  "id":5071100, "ctx":"initandlisten","msg":"Clearing temp directory"}
  {"t":{"$date":"2026-09-28T01:40:31.693+00:00"},"s":"I",  "c":"CONTROL",  "id":6608200, "ctx":"initandlisten","msg":"Initializing cluster server parameters from disk"}
  {"t":{"$date":"2026-09-28T01:40:31.694+00:00"},"s":"I",  "c":"CONTROL",  "id":20536,   "ctx":"initandlisten","msg":"Flow Control is enabled on this deployment"}
  {"t":{"$date":"2026-09-28T01:40:31.705+00:00"},"s":"I",  "c":"FTDC",     "id":20625,   "ctx":"initandlisten","msg":"Initializing full-time diagnostic data capture","attr":{"dataDirectory":"/data/db/diagnostic.data"}}
  {"t":{"$date":"2026-09-28T01:40:31.719+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"deferred writer pool","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:31.719+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"StandaloneThreadPool","numThreads":0,"minThreads":1,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:31.722+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"WaitForMajorityServiceReadThreadPool","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:31.722+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"WaitForMajorityServiceWriteThreadPool","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:31.723+00:00"},"s":"I",  "c":"STORAGE",  "id":20320,   "ctx":"initandlisten","msg":"createCollection","attr":{"namespace":"local.startup_log","uuidDisposition":"generated","uuid":{"uuid":{"$uuid":"033db694-8529-4484-be5d-485e432e9905"}},"options":{"capped":true,"size":10485760}}}
  {"t":{"$date":"2026-09-28T01:40:31.743+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"initandlisten","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"033db694-8529-4484-be5d-485e432e9905"}},"namespace":"local.startup_log","index":"_id_","ident":"index-3--7413776804062931694","collectionIdent":"collection-2--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:31.743+00:00"},"s":"I",  "c":"REPL",     "id":6015317, "ctx":"initandlisten","msg":"Setting new configuration state","attr":{"newState":"ConfigReplicationDisabled","oldState":"ConfigPreStart"}}
  {"t":{"$date":"2026-09-28T01:40:31.743+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"TTLMonitorMetadataRefresh","numThreads":0,"minThreads":0,"maxThreads":5}}
  {"t":{"$date":"2026-09-28T01:40:31.743+00:00"},"s":"I",  "c":"STORAGE",  "id":22262,   "ctx":"initandlisten","msg":"Timestamp monitor starting"}
  {"t":{"$date":"2026-09-28T01:40:31.745+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"StatsCache","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:31.745+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"ServiceExecutorFixed","numThreads":0,"minThreads":0,"maxThreads":1000}}
  {"t":{"$date":"2026-09-28T01:40:31.746+00:00"},"s":"I",  "c":"NETWORK",  "id":23015,   "ctx":"listener","msg":"Listening on","attr":{"address":"/tmp/mongodb-27017.sock"}}
  {"t":{"$date":"2026-09-28T01:40:31.746+00:00"},"s":"I",  "c":"NETWORK",  "id":23015,   "ctx":"listener","msg":"Listening on","attr":{"address":"127.0.0.1"}}
  {"t":{"$date":"2026-09-28T01:40:31.746+00:00"},"s":"I",  "c":"NETWORK",  "id":23016,   "ctx":"listener","msg":"Waiting for connections","attr":{"port":27017,"ssl":"off"}}
  {"t":{"$date":"2026-09-28T01:40:31.746+00:00"},"s":"I",  "c":"CONTROL",  "id":8423403, "ctx":"initandlisten","msg":"mongod startup complete","attr":{"Summary of time elapsed":{"Startup from clean shutdown?":true,"Statistics":{"Transport layer setup":"1 ms","Run initial syncer crash recovery":"0 ms","Create storage engine lock file in the data directory":"0 ms","Get metadata describing storage engine":"0 ms","Create storage engine":"973 ms","Write current PID to file":"0 ms","Write a new metadata for storage engine":"10 ms","Initialize FCV before rebuilding indexes":"1 ms","Drop abandoned idents and get back indexes that need to be rebuilt or builds that need to be restarted":"0 ms","Rebuild indexes for collections":"0 ms","Load cluster parameters from disk for a standalone":"1 ms","Build user and roles graph":"0 ms","Set up the background thread pool responsible for waiting for opTimes to be majority committed":"2 ms","Initialize information needed to make a mongod instance shard aware":"0 ms","Start up the replication coordinator":"0 ms","Start transport layer":"0 ms","_initAndListen total elapsed time":"1087 ms"}}}}
  child process started successfully, parent exiting
  {"t":{"$date":"2026-09-28T01:40:31.752+00:00"},"s":"I",  "c":"CONTROL",  "id":20712,   "ctx":"LogicalSessionCacheReap","msg":"Sessions collection is not set up; waiting until next sessions reap interval","attr":{"error":"NamespaceNotFound: config.system.sessions does not exist"}}
  {"t":{"$date":"2026-09-28T01:40:31.752+00:00"},"s":"I",  "c":"STORAGE",  "id":20320,   "ctx":"LogicalSessionCacheRefresh","msg":"createCollection","attr":{"namespace":"config.system.sessions","uuidDisposition":"generated","uuid":{"uuid":{"$uuid":"e20baaca-081e-4cf9-94f0-650e54ea2ed7"}},"options":{}}}
  {"t":{"$date":"2026-09-28T01:40:31.790+00:00"},"s":"I",  "c":"REPL",     "id":7360102, "ctx":"LogicalSessionCacheRefresh","msg":"Added oplog entry for create to transaction","attr":{"namespace":"config.$cmd","uuid":{"uuid":{"$uuid":"e20baaca-081e-4cf9-94f0-650e54ea2ed7"}},"object":{"create":"system.sessions","idIndex":{"v":2,"key":{"_id":1},"name":"_id_"}}}}
  {"t":{"$date":"2026-09-28T01:40:31.790+00:00"},"s":"I",  "c":"REPL",     "id":7360100, "ctx":"LogicalSessionCacheRefresh","msg":"Added oplog entry for createIndexes to transaction","attr":{"namespace":"config.$cmd","uuid":{"uuid":{"$uuid":"e20baaca-081e-4cf9-94f0-650e54ea2ed7"}},"object":{"createIndexes":"system.sessions","v":2,"key":{"lastUse":1},"name":"lsidTTLIndex","expireAfterSeconds":1800}}}
  {"t":{"$date":"2026-09-28T01:40:31.809+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"LogicalSessionCacheRefresh","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"e20baaca-081e-4cf9-94f0-650e54ea2ed7"}},"namespace":"config.system.sessions","index":"_id_","ident":"index-5--7413776804062931694","collectionIdent":"collection-4--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:31.809+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"LogicalSessionCacheRefresh","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"e20baaca-081e-4cf9-94f0-650e54ea2ed7"}},"namespace":"config.system.sessions","index":"lsidTTLIndex","ident":"index-6--7413776804062931694","collectionIdent":"collection-4--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:33.217+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43310","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"3efe1b95-8fff-451e-99c2-475ddc772461"}},"connectionId":1,"connectionCount":1}}
  {"t":{"$date":"2026-09-28T01:40:33.221+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn1","msg":"client metadata","attr":{"remote":"127.0.0.1:43310","client":"conn1","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.221+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn1","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43310","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.232+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43312","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"86413f9d-aefe-46c3-b01b-bc2a61ce97a2"}},"connectionId":2,"connectionCount":2}}
  {"t":{"$date":"2026-09-28T01:40:33.234+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn2","msg":"client metadata","attr":{"remote":"127.0.0.1:43312","client":"conn2","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.234+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn2","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43312","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.262+00:00"},"s":"I",  "c":"NETWORK",  "id":6788700, "ctx":"conn2","msg":"Received first command on ingress connection since session start or auth handshake","attr":{"elapsedMillis":28}}
  {"t":{"$date":"2026-09-28T01:40:33.479+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn2","msg":"Connection ended","attr":{"remote":"127.0.0.1:43312","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"86413f9d-aefe-46c3-b01b-bc2a61ce97a2"}},"connectionId":2,"connectionCount":1}}
  {"t":{"$date":"2026-09-28T01:40:33.484+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43316","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"ea442e20-b087-427f-a68c-8a7eeeeec4ec"}},"connectionId":3,"connectionCount":2}}
  {"t":{"$date":"2026-09-28T01:40:33.485+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43330","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"fe8087ee-e722-401c-97b6-97f285e98f3a"}},"connectionId":4,"connectionCount":3}}
  {"t":{"$date":"2026-09-28T01:40:33.487+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn3","msg":"client metadata","attr":{"remote":"127.0.0.1:43316","client":"conn3","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.488+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn3","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43316","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.488+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn4","msg":"client metadata","attr":{"remote":"127.0.0.1:43330","client":"conn4","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.488+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn4","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43330","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:33.495+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn1","msg":"Connection ended","attr":{"remote":"127.0.0.1:43310","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"3efe1b95-8fff-451e-99c2-475ddc772461"}},"connectionId":1,"connectionCount":2}}
  {"t":{"$date":"2026-09-28T01:40:33.497+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn3","msg":"Connection ended","attr":{"remote":"127.0.0.1:43316","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"ea442e20-b087-427f-a68c-8a7eeeeec4ec"}},"connectionId":3,"connectionCount":1}}
  {"t":{"$date":"2026-09-28T01:40:33.503+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn4","msg":"Connection ended","attr":{"remote":"127.0.0.1:43330","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"fe8087ee-e722-401c-97b6-97f285e98f3a"}},"connectionId":4,"connectionCount":0}}
  {"t":{"$date":"2026-09-28T01:40:34.131+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43336","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"411b6c50-3462-4b6e-ab25-8244d99dd918"}},"connectionId":5,"connectionCount":1}}
  {"t":{"$date":"2026-09-28T01:40:34.135+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn5","msg":"client metadata","attr":{"remote":"127.0.0.1:43336","client":"conn5","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:34.135+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn5","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43336","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:34.143+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43350","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"c0feb435-d846-4116-84c0-4a357fe5eb83"}},"connectionId":6,"connectionCount":2}}
  {"t":{"$date":"2026-09-28T01:40:34.146+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn6","msg":"client metadata","attr":{"remote":"127.0.0.1:43350","client":"conn6","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:34.147+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn6","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43350","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:34.174+00:00"},"s":"I",  "c":"NETWORK",  "id":6788700, "ctx":"conn6","msg":"Received first command on ingress connection since session start or auth handshake","attr":{"elapsedMillis":28}}
  {"t":{"$date":"2026-09-28T01:40:35.183+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43362","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"0b68ebb0-3a81-4b4f-af93-f01e96c4c436"}},"connectionId":7,"connectionCount":3}}
  {"t":{"$date":"2026-09-28T01:40:35.184+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43368","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"62980a92-94f0-434a-970c-ef30ceecf813"}},"connectionId":8,"connectionCount":4}}
  {"t":{"$date":"2026-09-28T01:40:35.191+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn7","msg":"client metadata","attr":{"remote":"127.0.0.1:43362","client":"conn7","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.191+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn7","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43362","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.192+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn8","msg":"client metadata","attr":{"remote":"127.0.0.1:43368","client":"conn8","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.192+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn8","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43368","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.194+00:00"},"s":"I",  "c":"NETWORK",  "id":22943,   "ctx":"listener","msg":"Connection accepted","attr":{"remote":"127.0.0.1:43384","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"245413e6-2b5c-485f-88ba-22cbdafbed0a"}},"connectionId":9,"connectionCount":5}}
  {"t":{"$date":"2026-09-28T01:40:35.197+00:00"},"s":"I",  "c":"NETWORK",  "id":6788700, "ctx":"conn8","msg":"Received first command on ingress connection since session start or auth handshake","attr":{"elapsedMillis":5}}
  {"t":{"$date":"2026-09-28T01:40:35.198+00:00"},"s":"I",  "c":"NETWORK",  "id":51800,   "ctx":"conn9","msg":"client metadata","attr":{"remote":"127.0.0.1:43384","client":"conn9","negotiatedCompressors":[],"doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.198+00:00"},"s":"I",  "c":"ACCESS",   "id":10483900,"ctx":"conn9","msg":"Connection not authenticating","attr":{"client":"127.0.0.1:43384","doc":{"application":{"name":"mongosh 2.10.0"},"driver":{"name":"nodejs|mongosh","version":"7.5.0|2.10.0"},"platform":"Node.js v24.18.1, LE","os":{"name":"linux","architecture":"x64","version":"3.10.0-327.22.2.el7.x86_64","type":"Linux"},"env":{"container":{"runtime":"docker"}}}}}
  {"t":{"$date":"2026-09-28T01:40:35.201+00:00"},"s":"I",  "c":"NETWORK",  "id":6788700, "ctx":"conn9","msg":"Received first command on ingress connection since session start or auth handshake","attr":{"elapsedMillis":3}}
  {"t":{"$date":"2026-09-28T01:40:35.581+00:00"},"s":"I",  "c":"COMMAND",  "id":51803,   "ctx":"conn9","msg":"Slow query","attr":{"type":"command","ns":"admin.$cmd","appName":"mongosh 2.10.0","command":{"getParameter":"foo","lsid":{"id":{"$uuid":"d35480ba-4d2f-4d82-a506-3b8d0005436c"}},"$db":"admin"},"numYields":0,"ok":0,"errMsg":"no option found to get","errName":"InvalidOptions","errCode":72,"reslen":112,"locks":{},"cpuNanos":288569000,"remote":"127.0.0.1:43384","protocol":"op_msg","durationMillis":288}}
  {"t":{"$date":"2026-09-28T01:40:35.691+00:00"},"s":"I",  "c":"COMMAND",  "id":51803,   "ctx":"conn6","msg":"Slow query","attr":{"type":"command","ns":"admin.atlascli","appName":"mongosh 2.10.0","command":{"aggregate":"atlascli","pipeline":[{"$match":{"managedClusterType":"atlasCliLocalDevCluster"}},{"$group":{"_id":1,"n":{"$sum":1}}}],"cursor":{},"lsid":{"id":{"$uuid":"859bc7ec-c125-49fc-ab8a-20f10a26c428"}},"$db":"admin"},"planSummary":"EOF","planningTimeMicros":197680,"keysExamined":0,"docsExamined":0,"cursorExhausted":true,"numYields":0,"nreturned":0,"queryFramework":"classic","reslen":103,"locks":{"FeatureCompatibilityVersion":{"acquireCount":{"r":2}},"Global":{"acquireCount":{"r":2}}},"storage":{},"cpuNanos":384117600,"remote":"127.0.0.1:43350","protocol":"op_msg","durationMillis":385}}
  admin> | | | | {"t":{"$date":"2026-09-28T01:40:37.753+00:00"},"s":"I",  "c":"WRITE",    "id":51803,   "ctx":"conn6","msg":"Slow query","attr":{"type":"update","ns":"admin.system.version","appName":"mongosh 2.10.0","command":{"q":{"_id":"authSchema"},"u":{"$set":{"currentVersion":5}},"multi":false,"upsert":true},"planSummary":"IDHACK","planningTimeMicros":1180,"keysExamined":0,"docsExamined":0,"nMatched":0,"nModified":0,"nUpserted":1,"keysInserted":1,"numYields":0,"locks":{"ParallelBatchWriterMode":{"acquireCount":{"r":1}},"FeatureCompatibilityVersion":{"acquireCount":{"w":1}},"ReplicationStateTransition":{"acquireCount":{"w":1}},"Global":{"acquireCount":{"w":1}},"Database":{"acquireCount":{"w":1}},"Collection":{"acquireCount":{"w":1}}},"flowControl":{"acquireCount":1},"storage":{},"cpuNanos":102450200,"remote":"127.0.0.1:43350","durationMillis":102}}
  {"t":{"$date":"2026-09-28T01:40:37.754+00:00"},"s":"I",  "c":"COMMAND",  "id":51803,   "ctx":"conn6","msg":"Slow query","attr":{"type":"command","ns":"admin.$cmd","appName":"mongosh 2.10.0","command":{"update":"system.version","bypassDocumentValidation":false,"ordered":true,"$db":"admin"},"numYields":0,"reslen":114,"locks":{"ParallelBatchWriterMode":{"acquireCount":{"r":1}},"FeatureCompatibilityVersion":{"acquireCount":{"r":1,"w":1}},"ReplicationStateTransition":{"acquireCount":{"w":1}},"Global":{"acquireCount":{"r":1,"w":1}},"Database":{"acquireCount":{"w":1}},"Collection":{"acquireCount":{"w":1}}},"flowControl":{"acquireCount":1},"storage":{},"cpuNanos":277944000,"remote":"127.0.0.1:43350","protocol":"op_msg","durationMillis":278}}
  {"t":{"$date":"2026-09-28T01:40:38.186+00:00"},"s":"I",  "c":"STORAGE",  "id":20320,   "ctx":"conn6","msg":"createCollection","attr":{"namespace":"admin.system.users","uuidDisposition":"generated","uuid":{"uuid":{"$uuid":"194b285a-c42c-49d2-b1b5-13f280d630b2"}},"options":{}}}
  {"t":{"$date":"2026-09-28T01:40:38.717+00:00"},"s":"I",  "c":"REPL",     "id":7360102, "ctx":"conn6","msg":"Added oplog entry for create to transaction","attr":{"namespace":"admin.$cmd","uuid":{"uuid":{"$uuid":"194b285a-c42c-49d2-b1b5-13f280d630b2"}},"object":{"create":"system.users","idIndex":{"v":2,"key":{"_id":1},"name":"_id_"}}}}
  {"t":{"$date":"2026-09-28T01:40:38.717+00:00"},"s":"I",  "c":"REPL",     "id":7360100, "ctx":"conn6","msg":"Added oplog entry for createIndexes to transaction","attr":{"namespace":"admin.$cmd","uuid":{"uuid":{"$uuid":"194b285a-c42c-49d2-b1b5-13f280d630b2"}},"object":{"createIndexes":"system.users","name":"user_1_db_1","key":{"user":1,"db":1},"unique":true,"v":2}}}
  {"t":{"$date":"2026-09-28T01:40:38.732+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"conn6","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"194b285a-c42c-49d2-b1b5-13f280d630b2"}},"namespace":"admin.system.users","index":"_id_","ident":"index-8--7413776804062931694","collectionIdent":"collection-7--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:38.732+00:00"},"s":"I",  "c":"INDEX",    "id":20345,   "ctx":"conn6","msg":"Index build: done building","attr":{"buildUUID":null,"collectionUUID":{"uuid":{"$uuid":"194b285a-c42c-49d2-b1b5-13f280d630b2"}},"namespace":"admin.system.users","index":"user_1_db_1","ident":"index-9--7413776804062931694","collectionIdent":"collection-7--7413776804062931694","commitTimestamp":null}}
  {"t":{"$date":"2026-09-28T01:40:38.734+00:00"},"s":"I",  "c":"COMMAND",  "id":51803,   "ctx":"conn6","msg":"Slow query","attr":{"type":"command","ns":"admin.system.users","appName":"mongosh 2.10.0","command":{"insert":"system.users","bypassDocumentValidation":false,"ordered":true,"$db":"admin"},"ninserted":1,"keysInserted":2,"numYields":0,"reslen":45,"locks":{"ParallelBatchWriterMode":{"acquireCount":{"r":3}},"FeatureCompatibilityVersion":{"acquireCount":{"w":3}},"ReplicationStateTransition":{"acquireCount":{"w":3}},"Global":{"acquireCount":{"w":3}},"Database":{"acquireCount":{"w":3}},"Collection":{"acquireCount":{"w":3}},"Mutex":{"acquireCount":{"r":1}}},"flowControl":{"acquireCount":4},"storage":{},"cpuNanos":97083100,"remote":"127.0.0.1:43350","protocol":"op_msg","durationMillis":548}}
  {"t":{"$date":"2026-09-28T01:40:38.734+00:00"},"s":"I",  "c":"COMMAND",  "id":51803,   "ctx":"conn6","msg":"Slow query","attr":{"type":"command","ns":"admin.$cmd","appName":"mongosh 2.10.0","command":{"createUser":"catalogo_user","pwd":"xxx","roles":[{"role":"root","db":"admin"}],"lsid":{"id":{"$uuid":"859bc7ec-c125-49fc-ab8a-20f10a26c428"}},"$db":"admin"},"numYields":0,"reslen":38,"locks":{"ParallelBatchWriterMode":{"acquireCount":{"r":4}},"FeatureCompatibilityVersion":{"acquireCount":{"r":3,"w":4}},"ReplicationStateTransition":{"acquireCount":{"w":4}},"Global":{"acquireCount":{"r":3,"w":4}},"Database":{"acquireCount":{"w":4}},"Collection":{"acquireCount":{"w":4}},"Mutex":{"acquireCount":{"r":1}}},"flowControl":{"acquireCount":4},"storage":{},"cpuNanos":1028646200,"remote":"127.0.0.1:43350","protocol":"op_msg","durationMillis":1823}}
  { ok: 1 }
  admin> {"t":{"$date":"2026-09-28T01:40:38.744+00:00"},"s":"I",  "c":"-",        "id":20883,   "ctx":"conn5","msg":"Interrupted operation as its client disconnected","attr":{"opId":62}}
  {"t":{"$date":"2026-09-28T01:40:38.745+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn6","msg":"Connection ended","attr":{"remote":"127.0.0.1:43350","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"c0feb435-d846-4116-84c0-4a357fe5eb83"}},"connectionId":6,"connectionCount":4}}
  {"t":{"$date":"2026-09-28T01:40:38.745+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn8","msg":"Connection ended","attr":{"remote":"127.0.0.1:43368","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"62980a92-94f0-434a-970c-ef30ceecf813"}},"connectionId":8,"connectionCount":3}}
  {"t":{"$date":"2026-09-28T01:40:38.745+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn9","msg":"Connection ended","attr":{"remote":"127.0.0.1:43384","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"245413e6-2b5c-485f-88ba-22cbdafbed0a"}},"connectionId":9,"connectionCount":2}}
  {"t":{"$date":"2026-09-28T01:40:38.745+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn7","msg":"Connection ended","attr":{"remote":"127.0.0.1:43362","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"0b68ebb0-3a81-4b4f-af93-f01e96c4c436"}},"connectionId":7,"connectionCount":1}}
  {"t":{"$date":"2026-09-28T01:40:38.747+00:00"},"s":"I",  "c":"NETWORK",  "id":22944,   "ctx":"conn5","msg":"Connection ended","attr":{"remote":"127.0.0.1:43336","isLoadBalanced":false,"uuid":{"uuid":{"$uuid":"411b6c50-3462-4b6e-ab25-8244d99dd918"}},"connectionId":5,"connectionCount":0}}

  /usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*


  {"t":{"$date":"2026-09-28T01:40:38.790+00:00"},"s":"I",  "c":"CONTROL",  "id":20698,   "ctx":"main","msg":"***** SERVER RESTARTED *****"}
  {"t":{"$date":"2026-09-28T01:40:38.793+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"parallel execution pool","numThreads":0,"minThreads":0,"maxThreads":128}}
  {"t":{"$date":"2026-09-28T01:40:38.794+00:00"},"s":"I",  "c":"NETWORK",  "id":4915701, "ctx":"main","msg":"Initialized wire specification","attr":{"spec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:38.794+00:00"},"s":"I",  "c":"CONTROL",  "id":23285,   "ctx":"main","msg":"Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'"}
  {"t":{"$date":"2026-09-28T01:40:38.795+00:00"},"s":"I",  "c":"NETWORK",  "id":4648601, "ctx":"main","msg":"Implicit TCP FastOpen unavailable. If TCP FastOpen is required, set tcpFastOpenServer, tcpFastOpenClient, and tcpFastOpenQueueSize."}
  {"t":{"$date":"2026-09-28T01:40:38.795+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool1","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:38.795+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"AuthorizationManager","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:38.796+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"OCSPCache","numThreads":0,"minThreads":0,"maxThreads":8}}
  {"t":{"$date":"2026-09-28T01:40:38.797+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool2","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:38.797+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"IndexBuildsCoordinatorMongod","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:38.797+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationDonorService","namespace":"config.tenantMigrationDonors"}}
  {"t":{"$date":"2026-09-28T01:40:38.797+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationRecipientService","namespace":"config.tenantMigrationRecipients"}}
  {"t":{"$date":"2026-09-28T01:40:38.797+00:00"},"s":"W",  "c":"NETWORK",  "id":11621101,"ctx":"main","msg":"Overriding max connections to honor `capMemoryConsumptionForPreAuthBuffers` settings","attr":{"limit":49369}}
  Killing process with pid: 28
  {"t":{"$date":"2026-09-28T01:40:38.798+00:00"},"s":"I",  "c":"CONTROL",  "id":23377,   "ctx":"SignalHandler","msg":"Received signal","attr":{"signal":15,"error":"Terminated"}}
  {"t":{"$date":"2026-09-28T01:40:38.798+00:00"},"s":"I",  "c":"CONTROL",  "id":23378,   "ctx":"SignalHandler","msg":"Signal was sent by kill(2)","attr":{"pid":107,"uid":999}}
  {"t":{"$date":"2026-09-28T01:40:38.798+00:00"},"s":"I",  "c":"CONTROL",  "id":23381,   "ctx":"SignalHandler","msg":"will terminate after current cmd ends"}
  {"t":{"$date":"2026-09-28T01:40:38.800+00:00"},"s":"I",  "c":"REPL",     "id":4784900, "ctx":"SignalHandler","msg":"Stepping down the ReplicationCoordinator for shutdown","attr":{"waitTimeMillis":15000}}
  {"t":{"$date":"2026-09-28T01:40:38.808+00:00"},"s":"I",  "c":"REPL",     "id":4794602, "ctx":"SignalHandler","msg":"Attempting to enter quiesce mode"}
  {"t":{"$date":"2026-09-28T01:40:38.808+00:00"},"s":"I",  "c":"-",        "id":6371601, "ctx":"SignalHandler","msg":"Shutting down the FLE Crud thread pool"}
  {"t":{"$date":"2026-09-28T01:40:38.808+00:00"},"s":"I",  "c":"COMMAND",  "id":4784901, "ctx":"SignalHandler","msg":"Shutting down the MirrorMaestro"}
  {"t":{"$date":"2026-09-28T01:40:38.808+00:00"},"s":"I",  "c":"SHARDING", "id":4784902, "ctx":"SignalHandler","msg":"Shutting down the WaitForMajorityService"}
  {"t":{"$date":"2026-09-28T01:40:38.808+00:00"},"s":"I",  "c":"CONTROL",  "id":4784903, "ctx":"SignalHandler","msg":"Shutting down the LogicalSessionCache"}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"NETWORK",  "id":20562,   "ctx":"SignalHandler","msg":"Shutdown: going to close listening sockets"}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"NETWORK",  "id":23017,   "ctx":"listener","msg":"removing socket file","attr":{"path":"/tmp/mongodb-27017.sock"}}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"NETWORK",  "id":4784905, "ctx":"SignalHandler","msg":"Shutting down the global connection pool"}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"CONTROL",  "id":4784906, "ctx":"SignalHandler","msg":"Shutting down the FlowControlTicketholder"}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"-",        "id":20520,   "ctx":"SignalHandler","msg":"Stopping further Flow Control ticket acquisitions."}
  {"t":{"$date":"2026-09-28T01:40:38.809+00:00"},"s":"I",  "c":"CONTROL",  "id":4784908, "ctx":"SignalHandler","msg":"Shutting down the PeriodicThreadToAbortExpiredTransactions"}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"REPL",     "id":4784909, "ctx":"SignalHandler","msg":"Shutting down the ReplicationCoordinator"}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"SHARDING", "id":4784910, "ctx":"SignalHandler","msg":"Shutting down the ShardingInitializationMongoD"}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"REPL",     "id":4784911, "ctx":"SignalHandler","msg":"Enqueuing the ReplicationStateTransitionLock for shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"-",        "id":4784912, "ctx":"SignalHandler","msg":"Killing all operations for shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"-",        "id":4695300, "ctx":"SignalHandler","msg":"Interrupted all currently running operations","attr":{"opsKilled":3}}
  {"t":{"$date":"2026-09-28T01:40:38.810+00:00"},"s":"I",  "c":"TENANT_M", "id":5093807, "ctx":"SignalHandler","msg":"Shutting down all TenantMigrationAccessBlockers on global shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.814+00:00"},"s":"I",  "c":"ASIO",     "id":22582,   "ctx":"TenantMigrationBlockerNet","msg":"Killing all outstanding egress activity."}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"ASIO",     "id":6529201, "ctx":"SignalHandler","msg":"Network interface redundant shutdown","attr":{"state":"Stopped"}}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"ASIO",     "id":22582,   "ctx":"SignalHandler","msg":"Killing all outstanding egress activity."}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"COMMAND",  "id":4784913, "ctx":"SignalHandler","msg":"Shutting down all open transactions"}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"REPL",     "id":4784914, "ctx":"SignalHandler","msg":"Acquiring the ReplicationStateTransitionLock for shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"INDEX",    "id":4784915, "ctx":"SignalHandler","msg":"Shutting down the IndexBuildsCoordinator"}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"NETWORK",  "id":4784918, "ctx":"SignalHandler","msg":"Shutting down the ReplicaSetMonitor"}
  {"t":{"$date":"2026-09-28T01:40:38.816+00:00"},"s":"I",  "c":"SHARDING", "id":4784921, "ctx":"SignalHandler","msg":"Shutting down the MigrationUtilExecutor"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"SignalHandler","msg":"Starting thread pool","attr":{"poolName":"MoveChunk","numThreads":0,"minThreads":0,"maxThreads":16}}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"ASIO",     "id":22582,   "ctx":"MigrationUtil-TaskExecutor","msg":"Killing all outstanding egress activity."}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"COMMAND",  "id":4784923, "ctx":"SignalHandler","msg":"Shutting down the ServiceEntryPoint"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"CONTROL",  "id":4784927, "ctx":"SignalHandler","msg":"Shutting down the HealthLog"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"CONTROL",  "id":4784928, "ctx":"SignalHandler","msg":"Shutting down the TTL monitor"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"INDEX",    "id":3684100, "ctx":"SignalHandler","msg":"Shutting down TTL collection monitor thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"ASIO",     "id":22582,   "ctx":"TTLMonitorMetadataRefreshNetwork","msg":"Killing all outstanding egress activity."}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"INDEX",    "id":3684101, "ctx":"SignalHandler","msg":"Finished shutting down TTL collection monitor thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"CONTROL",  "id":6278511, "ctx":"SignalHandler","msg":"Shutting down the Change Stream Expired Pre-images Remover"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"CONTROL",  "id":4784929, "ctx":"SignalHandler","msg":"Acquiring the global lock for shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"CONTROL",  "id":4784930, "ctx":"SignalHandler","msg":"Shutting down the storage engine"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"STORAGE",  "id":22320,   "ctx":"SignalHandler","msg":"Shutting down journal flusher thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"STORAGE",  "id":22321,   "ctx":"SignalHandler","msg":"Finished shutting down journal flusher thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"STORAGE",  "id":22322,   "ctx":"SignalHandler","msg":"Shutting down checkpoint thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"STORAGE",  "id":22323,   "ctx":"SignalHandler","msg":"Finished shutting down checkpoint thread"}
  {"t":{"$date":"2026-09-28T01:40:38.817+00:00"},"s":"I",  "c":"STORAGE",  "id":22261,   "ctx":"SignalHandler","msg":"Timestamp monitor shutting down"}
  {"t":{"$date":"2026-09-28T01:40:38.818+00:00"},"s":"I",  "c":"STORAGE",  "id":20282,   "ctx":"SignalHandler","msg":"Deregistering all the collections"}
  {"t":{"$date":"2026-09-28T01:40:38.818+00:00"},"s":"I",  "c":"STORAGE",  "id":22317,   "ctx":"SignalHandler","msg":"WiredTigerKVEngine shutting down"}
  {"t":{"$date":"2026-09-28T01:40:38.818+00:00"},"s":"I",  "c":"STORAGE",  "id":22318,   "ctx":"SignalHandler","msg":"Shutting down session sweeper thread"}
  {"t":{"$date":"2026-09-28T01:40:38.818+00:00"},"s":"I",  "c":"STORAGE",  "id":22319,   "ctx":"SignalHandler","msg":"Finished shutting down session sweeper thread"}
  {"t":{"$date":"2026-09-28T01:40:38.823+00:00"},"s":"I",  "c":"STORAGE",  "id":4795902, "ctx":"SignalHandler","msg":"Closing WiredTiger","attr":{"closeConfig":"leak_memory=true,use_timestamp=false,"}}
  {"t":{"$date":"2026-09-28T01:40:38.825+00:00"},"s":"I",  "c":"WTCHKPT",  "id":22430,   "ctx":"SignalHandler","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559638,"ts_usec":825517,"thread":"28:0x7f7256a66640","session_name":"close_ckpt","category":"WT_VERB_CHECKPOINT_PROGRESS","category_id":6,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"saving checkpoint snapshot min: 46, snapshot max: 46 snapshot count: 0, oldest timestamp: (0, 0) , meta checkpoint timestamp: (0, 0) base write gen: 1"}}}
  {"t":{"$date":"2026-09-28T01:40:38.916+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"SignalHandler","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559638,"ts_usec":916862,"thread":"28:0x7f7256a66640","session_name":"WT_CONNECTION.close","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"shutdown checkpoint has successfully finished and ran for 93 milliseconds"}}}
  {"t":{"$date":"2026-09-28T01:40:38.917+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"SignalHandler","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559638,"ts_usec":917169,"thread":"28:0x7f7256a66640","session_name":"WT_CONNECTION.close","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"shutdown was completed successfully and took 93ms, including 0ms for the rollback to stable, and 93ms for the checkpoint."}}}
  {"t":{"$date":"2026-09-28T01:40:38.952+00:00"},"s":"I",  "c":"STORAGE",  "id":4795901, "ctx":"SignalHandler","msg":"WiredTiger closed","attr":{"durationMillis":129}}
  {"t":{"$date":"2026-09-28T01:40:38.952+00:00"},"s":"I",  "c":"STORAGE",  "id":22279,   "ctx":"SignalHandler","msg":"shutdown: removing fs lock..."}
  {"t":{"$date":"2026-09-28T01:40:38.952+00:00"},"s":"I",  "c":"-",        "id":4784931, "ctx":"SignalHandler","msg":"Dropping the scope cache for shutdown"}
  {"t":{"$date":"2026-09-28T01:40:38.952+00:00"},"s":"I",  "c":"FTDC",     "id":20626,   "ctx":"SignalHandler","msg":"Shutting down full-time diagnostic data capture"}
  {"t":{"$date":"2026-09-28T01:40:38.954+00:00"},"s":"I",  "c":"-",        "id":10175800,"ctx":"SignalHandler","msg":"Shutting down the standalone executor"}
  {"t":{"$date":"2026-09-28T01:40:38.954+00:00"},"s":"I",  "c":"ASIO",     "id":22582,   "ctx":"StandaloneNetwork","msg":"Killing all outstanding egress activity."}
  {"t":{"$date":"2026-09-28T01:40:38.955+00:00"},"s":"I",  "c":"CONTROL",  "id":20565,   "ctx":"SignalHandler","msg":"Now exiting"}
  {"t":{"$date":"2026-09-28T01:40:38.955+00:00"},"s":"I",  "c":"CONTROL",  "id":8423404, "ctx":"SignalHandler","msg":"mongod shutdown complete","attr":{"Summary of time elapsed":{"Statistics":{"Enter terminal shutdown":"0 ms","Step down the replication coordinator for shutdown":"7 ms","Time spent in quiesce mode":"1 ms","Shut down FLE Crud subsystem":"0 ms","Shut down MirrorMaestro":"0 ms","Shut down WaitForMajorityService":"0 ms","Shut down the logical session cache":"0 ms","Shut down the transport layer":"1 ms","Shut down the global connection pool":"0 ms","Shut down the flow control ticket holder":"0 ms","Kill all operations for shutdown":"0 ms","Shut down all tenant migration access blockers on global shutdown":"6 ms","Shut down all open transactions":"0 ms","Acquire the RSTL for shutdown":"0 ms","Shut down the IndexBuildsCoordinator and wait for index builds to finish":"0 ms","Shut down the replica set monitor":"0 ms","Shut down the migration util executor":"0 ms","Shut down the health log":"0 ms","Shut down the TTL monitor":"0 ms","Shut down expired pre-images and documents removers":"0 ms","Shut down the storage engine":"135 ms","Wait for the oplog cap maintainer thread to stop":"0 ms","Shut down full-time data capture":"0 ms","Shut down standalone executor":"2 ms","shutdownTask total elapsed time":"155 ms"}}}}
  {"t":{"$date":"2026-09-28T01:40:38.955+00:00"},"s":"I",  "c":"CONTROL",  "id":23138,   "ctx":"SignalHandler","msg":"Shutting down","attr":{"exitCode":0}}

  MongoDB init process complete; ready for start up.

  {"t":{"$date":"2026-09-28T01:40:39.836+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"parallel execution pool","numThreads":0,"minThreads":0,"maxThreads":128}}
  {"t":{"$date":"2026-09-28T01:40:39.837+00:00"},"s":"I",  "c":"NETWORK",  "id":4915701, "ctx":"main","msg":"Initialized wire specification","attr":{"spec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:39.837+00:00"},"s":"I",  "c":"CONTROL",  "id":23285,   "ctx":"main","msg":"Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'"}
  {"t":{"$date":"2026-09-28T01:40:39.837+00:00"},"s":"I",  "c":"NETWORK",  "id":4648601, "ctx":"main","msg":"Implicit TCP FastOpen unavailable. If TCP FastOpen is required, set tcpFastOpenServer, tcpFastOpenClient, and tcpFastOpenQueueSize."}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"OCSPCache","numThreads":0,"minThreads":0,"maxThreads":8}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool1","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"AuthorizationManager","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ThreadPool2","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"IndexBuildsCoordinatorMongod","numThreads":0,"minThreads":0,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationDonorService","namespace":"config.tenantMigrationDonors"}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"REPL",     "id":5123008, "ctx":"main","msg":"Successfully registered PrimaryOnlyService","attr":{"service":"TenantMigrationRecipientService","namespace":"config.tenantMigrationRecipients"}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"W",  "c":"NETWORK",  "id":11621101,"ctx":"main","msg":"Overriding max connections to honor `capMemoryConsumptionForPreAuthBuffers` settings","attr":{"limit":49369}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"CONTROL",  "id":5945603, "ctx":"main","msg":"Multi threading initialized"}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"ReadWriteConcernDefaults","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:39.838+00:00"},"s":"I",  "c":"TENANT_M", "id":7091600, "ctx":"main","msg":"Starting TenantMigrationAccessBlockerRegistry"}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"TenantMigrationBlockerAsyncThreadPool","numThreads":0,"minThreads":0,"maxThreads":4}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"CONTROL",  "id":4615611, "ctx":"initandlisten","msg":"MongoDB starting","attr":{"pid":1,"port":27017,"dbPath":"/data/db","architecture":"64-bit","host":"eb1a675c0dcb"}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"CONTROL",  "id":23403,   "ctx":"initandlisten","msg":"Build Info","attr":{"buildInfo":{"version":"7.0.43","gitVersion":"ef5a7d3480b59feae13d564376129fc4ceee6177","openSSLVersion":"OpenSSL 3.0.2 15 Mar 2022","modules":[],"allocator":"tcmalloc","environment":{"distmod":"ubuntu2204","distarch":"x86_64","target_arch":"x86_64"}}}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"CONTROL",  "id":51765,   "ctx":"initandlisten","msg":"Operating System","attr":{"os":{"name":"Ubuntu","version":"22.04"}}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"CONTROL",  "id":21951,   "ctx":"initandlisten","msg":"Options set by command line","attr":{"options":{"net":{"bindIp":"*"},"security":{"authorization":"enabled"}}}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"W",  "c":"NETWORK",  "id":11621101,"ctx":"initandlisten","msg":"Overriding max connections to honor `capMemoryConsumptionForPreAuthBuffers` settings","attr":{"limit":49369}}
  {"t":{"$date":"2026-09-28T01:40:39.839+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"OCSPManagerHTTP","numThreads":0,"minThreads":1,"maxThreads":10}}
  {"t":{"$date":"2026-09-28T01:40:39.840+00:00"},"s":"I",  "c":"STORAGE",  "id":22270,   "ctx":"initandlisten","msg":"Storage engine to use detected by data files","attr":{"dbpath":"/data/db","storageEngine":"wiredTiger"}}
  {"t":{"$date":"2026-09-28T01:40:39.840+00:00"},"s":"I",  "c":"STORAGE",  "id":22297,   "ctx":"initandlisten","msg":"Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem","tags":["startupWarnings"]}
  {"t":{"$date":"2026-09-28T01:40:39.840+00:00"},"s":"I",  "c":"STORAGE",  "id":22315,   "ctx":"initandlisten","msg":"Opening WiredTiger","attr":{"config":"create,cache_size=1416M,session_max=33000,eviction=(threads_min=4,threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,remove=true,path=journal,compressor=snappy),builtin_extension_config=(zstd=(compression_level=6)),file_manager=(close_idle_time=600,close_scan_interval=10,close_handle_minimum=2000),statistics_log=(wait=0),json_output=(error,message),verbose=[recovery_progress:1,checkpoint_progress:1,compact_progress:1,backup:0,checkpoint:0,compact:0,evict:0,history_store:0,recovery:0,rts:0,salvage:0,tiered:0,timestamp:0,transaction:0,verify:0,log:0],"}}
  {"t":{"$date":"2026-09-28T01:40:40.541+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":541776,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Recovering log 1 through 2"}}}
  {"t":{"$date":"2026-09-28T01:40:40.619+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":619417,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Recovering log 2 through 2"}}}
  {"t":{"$date":"2026-09-28T01:40:40.698+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":698929,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Main recovery loop: starting at 1/31744 to 2/256"}}}
  {"t":{"$date":"2026-09-28T01:40:40.788+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":788430,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Recovering log 1 through 2"}}}
  {"t":{"$date":"2026-09-28T01:40:40.877+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":877708,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Recovering log 2 through 2"}}}
  {"t":{"$date":"2026-09-28T01:40:40.925+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":925719,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery log replay has successfully finished and ran for 384 milliseconds"}}}
  {"t":{"$date":"2026-09-28T01:40:40.925+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":925932,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Set global recovery timestamp: (0, 0)"}}}
  {"t":{"$date":"2026-09-28T01:40:40.925+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":925964,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"Set global oldest timestamp: (0, 0)"}}}
  {"t":{"$date":"2026-09-28T01:40:40.928+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":928861,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery rollback to stable has successfully finished and ran for 2 milliseconds"}}}
  {"t":{"$date":"2026-09-28T01:40:40.933+00:00"},"s":"I",  "c":"WTCHKPT",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":933771,"thread":"1:0x7f3999649cc0","session_name":"WT_SESSION.checkpoint","category":"WT_VERB_CHECKPOINT_PROGRESS","category_id":6,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"saving checkpoint snapshot min: 1, snapshot max: 1 snapshot count: 0, oldest timestamp: (0, 0) , meta checkpoint timestamp: (0, 0) base write gen: 7"}}}
  {"t":{"$date":"2026-09-28T01:40:40.996+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":996654,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery checkpoint has successfully finished and ran for 67 milliseconds"}}}
  {"t":{"$date":"2026-09-28T01:40:40.996+00:00"},"s":"I",  "c":"WTRECOV",  "id":22430,   "ctx":"initandlisten","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559640,"ts_usec":996811,"thread":"1:0x7f3999649cc0","session_name":"txn-recover","category":"WT_VERB_RECOVERY_PROGRESS","category_id":30,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"recovery was completed successfully and took 455ms, including 384ms for the log replay, 2ms for the rollback to stable, and 67ms for the checkpoint."}}}
  {"t":{"$date":"2026-09-28T01:40:40.999+00:00"},"s":"I",  "c":"STORAGE",  "id":4795906, "ctx":"initandlisten","msg":"WiredTiger opened","attr":{"durationMillis":1159}}
  {"t":{"$date":"2026-09-28T01:40:40.999+00:00"},"s":"I",  "c":"RECOVERY", "id":23987,   "ctx":"initandlisten","msg":"WiredTiger recoveryTimestamp","attr":{"recoveryTimestamp":{"$timestamp":{"t":0,"i":0}}}}
  {"t":{"$date":"2026-09-28T01:40:41.017+00:00"},"s":"W",  "c":"CONTROL",  "id":9068900, "ctx":"initandlisten","msg":"For customers running MongoDB 7.0, we suggest changing the contents of the following sysfsFile","attr":{"sysfsFile":"/sys/kernel/mm/transparent_hugepage","currentValue":"always","desiredValue":"never"},"tags":["startupWarnings"]}
  {"t":{"$date":"2026-09-28T01:40:41.022+00:00"},"s":"I",  "c":"NETWORK",  "id":4915702, "ctx":"initandlisten","msg":"Updated wire specification","attr":{"oldSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true},"newSpec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":21,"maxWireVersion":21},"outgoing":{"minWireVersion":21,"maxWireVersion":21},"isInternalClient":true}}}
  {"t":{"$date":"2026-09-28T01:40:41.022+00:00"},"s":"I",  "c":"REPL",     "id":5853300, "ctx":"initandlisten","msg":"current featureCompatibilityVersion value","attr":{"featureCompatibilityVersion":"7.0","context":"startup"}}
  {"t":{"$date":"2026-09-28T01:40:41.023+00:00"},"s":"I",  "c":"STORAGE",  "id":5071100, "ctx":"initandlisten","msg":"Clearing temp directory"}
  {"t":{"$date":"2026-09-28T01:40:41.024+00:00"},"s":"I",  "c":"CONTROL",  "id":6608200, "ctx":"initandlisten","msg":"Initializing cluster server parameters from disk"}
  {"t":{"$date":"2026-09-28T01:40:41.024+00:00"},"s":"I",  "c":"CONTROL",  "id":20536,   "ctx":"initandlisten","msg":"Flow Control is enabled on this deployment"}
  {"t":{"$date":"2026-09-28T01:40:41.024+00:00"},"s":"I",  "c":"FTDC",     "id":20625,   "ctx":"initandlisten","msg":"Initializing full-time diagnostic data capture","attr":{"dataDirectory":"/data/db/diagnostic.data"}}
  {"t":{"$date":"2026-09-28T01:40:41.025+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"deferred writer pool","numThreads":0,"minThreads":0,"maxThreads":1}}
  {"t":{"$date":"2026-09-28T01:40:41.025+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"StandaloneThreadPool","numThreads":0,"minThreads":1,"maxThreads":1000000000}}
  {"t":{"$date":"2026-09-28T01:40:41.025+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"WaitForMajorityServiceReadThreadPool","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:41.025+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"WaitForMajorityServiceWriteThreadPool","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:41.027+00:00"},"s":"I",  "c":"REPL",     "id":6015317, "ctx":"initandlisten","msg":"Setting new configuration state","attr":{"newState":"ConfigReplicationDisabled","oldState":"ConfigPreStart"}}
  {"t":{"$date":"2026-09-28T01:40:41.027+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"TTLMonitorMetadataRefresh","numThreads":0,"minThreads":0,"maxThreads":5}}
  {"t":{"$date":"2026-09-28T01:40:41.027+00:00"},"s":"I",  "c":"STORAGE",  "id":22262,   "ctx":"initandlisten","msg":"Timestamp monitor starting"}
  {"t":{"$date":"2026-09-28T01:40:41.028+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"StatsCache","numThreads":0,"minThreads":0,"maxThreads":2}}
  {"t":{"$date":"2026-09-28T01:40:41.028+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"initandlisten","msg":"Starting thread pool","attr":{"poolName":"ServiceExecutorFixed","numThreads":0,"minThreads":0,"maxThreads":1000}}
  {"t":{"$date":"2026-09-28T01:40:41.029+00:00"},"s":"I",  "c":"NETWORK",  "id":23015,   "ctx":"listener","msg":"Listening on","attr":{"address":"/tmp/mongodb-27017.sock"}}
  {"t":{"$date":"2026-09-28T01:40:41.029+00:00"},"s":"I",  "c":"NETWORK",  "id":23015,   "ctx":"listener","msg":"Listening on","attr":{"address":"0.0.0.0"}}
  {"t":{"$date":"2026-09-28T01:40:41.029+00:00"},"s":"I",  "c":"NETWORK",  "id":23016,   "ctx":"listener","msg":"Waiting for connections","attr":{"port":27017,"ssl":"off"}}
  {"t":{"$date":"2026-09-28T01:40:41.029+00:00"},"s":"I",  "c":"CONTROL",  "id":8423403, "ctx":"initandlisten","msg":"mongod startup complete","attr":{"Summary of time elapsed":{"Startup from clean shutdown?":true,"Statistics":{"Transport layer setup":"0 ms","Run initial syncer crash recovery":"0 ms","Create storage engine lock file in the data directory":"0 ms","Get metadata describing storage engine":"0 ms","Validate options in metadata against current startup options":"0 ms","Create storage engine":"1160 ms","Write current PID to file":"10 ms","Initialize FCV before rebuilding indexes":"5 ms","Drop abandoned idents and get back indexes that need to be rebuilt or builds that need to be restarted":"0 ms","Rebuild indexes for collections":"0 ms","Load cluster parameters from disk for a standalone":"0 ms","Build user and roles graph":"0 ms","Verify indexes for admin.system.users collection":"0 ms","Set up the background thread pool responsible for waiting for opTimes to be majority committed":"0 ms","Initialize information needed to make a mongod instance shard aware":"0 ms","Start up the replication coordinator":"1 ms","Start transport layer":"0 ms","_initAndListen total elapsed time":"1190 ms"}}}}
  {"t":{"$date":"2026-09-28T01:41:41.013+00:00"},"s":"I",  "c":"WTCHKPT",  "id":22430,   "ctx":"Checkpointer","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559701,"ts_usec":13838,"thread":"1:0x7f3990636640","session_name":"WT_SESSION.checkpoint","category":"WT_VERB_CHECKPOINT_PROGRESS","category_id":6,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"saving checkpoint snapshot min: 4, snapshot max: 4 snapshot count: 0, oldest timestamp: (0, 0) , meta checkpoint timestamp: (0, 0) base write gen: 7"}}}
  {"t":{"$date":"2026-09-28T01:42:41.067+00:00"},"s":"I",  "c":"WTCHKPT",  "id":22430,   "ctx":"Checkpointer","msg":"WiredTiger message","attr":{"message":{"ts_sec":1790559761,"ts_usec":67312,"thread":"1:0x7f3990636640","session_name":"WT_SESSION.checkpoint","category":"WT_VERB_CHECKPOINT_PROGRESS","category_id":6,"verbose_level":"DEBUG_1","verbose_level_id":1,"msg":"saving checkpoint snapshot min: 5, snapshot max: 5 snapshot count: 0, oldest timestamp: (0, 0) , meta checkpoint timestamp: (0, 0) base write gen: 7"}}}

  ```
]

5) Verificar que la autenticación se encuentra efectivamente habilitada, ejecutando los dos
comandos siguientes y comparando sus resultados:

a) la operación administrativa ping, sin proporcionar credenciales, que deberá completarse
con éxito;

#consola[
  ```text
  PS catalogo-app> docker exec catalogo-db mongosh --quiet --eval "db.adminCommand('ping')"
  { ok: 1 }
  PS catalogo-app> docker exec catalogo-db mongosh --quiet --eval "db.adminCommand({listDatabases: 1})"
  MongoServerError: Command listDatabases requires authentication
  PS catalogo-app>
  ```
]

b) el listado de bases de datos, sin proporcionar credenciales, que deberá ser rechazado.

#consola[
  ```text
  PS catalogo-app> docker exec catalogo-db mongosh --quiet --eval "db.adminCommand({listDatabases: 1})"
  MongoServerError: Command listDatabases requires authentication
  PS catalogo-app>
  ```
]

Se solicita transcribir el mensaje obtenido en el segundo caso y explicar por qué el primero no
resulta rechazado. Esta diferencia será relevante al configurar las comprobaciones de estado
en la cuarta semana.

#completar()

6) Establecer conexión con las credenciales configuradas, en las dos formas que se indican a
continuación, y comparar los resultados:

a) mediante una cadena de conexión que no especifique la base de datos de autenticación;

#consola[
  ```text
  PS catalogo-app> docker exec -it catalogo-db mongosh "mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb"
  Current Mongosh Log ID: 6ab9c9fc3625a1c2b4b23266
  Connecting to:          mongodb://<credentials>@localhost:27017/catalogodb?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.10.0
  MongoServerError: Authentication failed.

  What's next:
      Try Docker Debug for seamless, persistent debugging tools in any container or image → docker debug catalogo-db
      Learn more at https://docs.docker.com/go/debug-cli/
  PS catalogo-app>
  ```
]

b) mediante una cadena de conexión que incluya el parámetro ?authSource=admin.


#consola[
  ```text
  PS catalogo-app> docker exec -it catalogo-db mongosh "mongodb://catalogo_user:catalogo_pass@localhost:27017/catalogodb?authSource=admin"
  Current Mongosh Log ID: 6ab9ca5639e93e4e1a4f0185
  Connecting to:          mongodb://<credentials>@localhost:27017/catalogodb?authSource=admin&directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.10.0
  Using MongoDB:          7.0.43
  Using Mongosh:          2.10.0

  For mongosh info see: https://www.mongodb.com/docs/mongodb-shell/


  To help improve our products, anonymous usage data is collected and sent to MongoDB periodically (https://www.mongodb.com/legal/privacy-policy).
  You can opt-out by running the disableTelemetry() command.

  ------
     The server generated these startup warnings when booting
     2026-09-28T01:40:39.840+00:00: Using the XFS filesystem is strongly recommended with the WiredTiger storage engine. See http://dochub.mongodb.org/core/prodnotes-filesystem
     2026-09-28T01:40:41.017+00:00: For customers running MongoDB 7.0, we suggest changing the contents of the following sysfsFile
  ------
  ```
]

Se solicita explicar por escrito la razón de la diferencia observada. El usuario creado por las
variables de entorno de la imagen reside en la base admin; en ausencia de dicho parámetro, el
motor lo busca en la base de la aplicación, no lo encuentra e informa un fallo de
autenticación. Este hallazgo conviene dejarlo anotado en el README.md, dado que se
manifestará nuevamente en las semanas posteriores.

7) Ejecutar docker inspect --format '{{json .Config.Env}}' catalogo-db y
observar el tratamiento que recibe la contraseña configurada. Redactar una línea acerca de las
implicancias de seguridad de este hallazgo.

8) Comprobar la ausencia de persistencia. Para ello se deberá insertar un documento de prueba
en una colección, eliminar el contenedor con docker rm -f, volver a crearlo con el mismo
comando del punto 4 y contar nuevamente los documentos existentes. Documentar las tres
salidas y explicar el resultado obtenido.
