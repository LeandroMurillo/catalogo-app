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