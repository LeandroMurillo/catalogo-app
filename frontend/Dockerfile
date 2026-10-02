FROM node:20-alpine AS builder
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY --from=builder dist/ /usr/share/nginx/html/
COPY nginx/templates/default.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 8080
ENV API_HOST=catalogo-api API_PORT=8000 NGINX_ENVSUBST_FILTER=^API_