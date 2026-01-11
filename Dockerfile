# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy assets and source code
COPY assets/ ./assets/
COPY lib/ ./lib/
COPY web/ ./web/

# Create .env file from build args or use defaults
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
RUN echo "SUPABASE_URL=${SUPABASE_URL}" > .env && \
    echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" >> .env

# Build the web app (uses CanvasKit by default in Flutter 3.x+)
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built web files
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
