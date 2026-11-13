# build: Astro 7 needs Node >= 22.23
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
ARG BUILD_SHA=dev
ENV PUBLIC_BUILD_SHA=$BUILD_SHA
RUN npm run build

# serve
FROM nginx:1.27-alpine
COPY deploy/site.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
