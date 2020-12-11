# Base image
FROM node:12-alpine AS base
WORKDIR /app
# Couchbase sdk requirements
RUN apk update && apk add curl bash python g++ make && rm -rf /var/cache/apk/*
# Install node-prune
RUN npm i -g node-prune

# Install dependencies
FROM base AS dependencies
COPY package*.json ./
RUN npm ci && npm cache clean --force

# Build application
FROM dependencies AS build
WORKDIR /app
COPY . .
RUN npm run build

FROM build as prodDependencies
WORKDIR /app
COPY --from=dependencies /app/package*.json ./
COPY --from=dependencies /app/node_modules ./node_modules/
# Remove dev dependencies
RUN npm prune --production && node-prune

FROM node:12-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=prodDependencies /app/node_modules ./node_modules
EXPOSE 4000
CMD ["node", "./dist/main.js"]