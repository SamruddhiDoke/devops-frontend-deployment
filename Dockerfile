# ---- Stage 1: build the Vite frontend ----
FROM node:22-alpine AS build
WORKDIR /app

# Install dependencies first (better layer caching)
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Copy the rest of the frontend and build static files into /app/dist
COPY frontend/ ./
RUN npm run build

# ---- Stage 2: serve the static files with Nginx ----
FROM nginx:1.28-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
