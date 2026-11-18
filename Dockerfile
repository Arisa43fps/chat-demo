# syntax=docker/dockerfile:1

FROM node:22-alpine AS build
WORKDIR /app
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN npm install -g pnpm@12.16.1
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile
COPY tsconfig.json rspack.config.ts ./
COPY src ./src
COPY LICENSE ./
RUN pnpm build

FROM nginx:1.30-alpine-slim
ENV ROUTER_ORIGIN=http://127.0.0.1:20128 \
    NGINX_ENVSUBST_FILTER=ROUTER_ORIGIN
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1
