# ShopNow admin

############################
# Stage 1: Build
############################
FROM node:18-alpine AS builder

LABEL org.opencontainers.image.description="ShopNow admin"

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./

RUN npm ci --no-audit --prefer-offline

COPY . .

ENV PUBLIC_URL=/admin
ENV REACT_APP_API_BASE_URL=/api

RUN npm run build

############################
# Stage 2: Runtime
############################
FROM nginx:1.24-alpine

LABEL org.opencontainers.image.description="ShopNow admin runtime"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
