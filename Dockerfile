FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    postgresql-dev \
    python3 \
    make \
    g++ \
    graphicsmagick \
    ffmpeg \
    ffmpeg-dev \
    ghostscript \
    postgresql-client \
    netcat-openbsd

# Tell Puppeteer to skip installing Chrome
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Copy package files
COPY package*.json ./

# Install global dependencies first
RUN npm install -g node-gyp gulp-cli

# Install dependencies
RUN npm install --save \
    pg@"^8.x.x" \
    pg-hstore@"^2.x.x" \
    sequelize@"^6.x.x" \
    ioredis@"^5.x.x" \
    && npm install \
    && npm rebuild pg --build-from-source

# Create directory structure first
RUN mkdir -p /app/build/assets/images \
    /app/build/assets/stylesheets \
    /app/build/assets/javascripts \
    /app/build/views

    # Copy locale files
COPY locales/ /app/locales/

# Add this to your container startup script
RUN mkdir -p /app/build/locales && \
    cp -r /app/locales/* /app/build/locales/
# Copy application code
COPY . .

# # Create favicon.png if it doesn't exist
# RUN cp -v public/images/sd6-icon-white.svg build/assets/images/favicon.png || \
#     touch build/assets/images/favicon.png

# Build and organize assets
RUN cp -rv public/images/* build/assets/images/ || true && \
    cp -rv public/stylesheets/* build/assets/stylesheets/ || true && \
    cp -rv public/javascripts/* build/assets/javascripts/ || true && \
    cp -rv views/* build/views/ || true

# Verify file structure
RUN ls -la /app/build/assets/images && \
    ls -la /app/build/views

# Set production environment
ENV NODE_ENV=production \
    STORAGE_DIALECT=postgres \
    STORAGE_HOST=postgres \
    STORAGE_DATABASE=spacedeck \
    STORAGE_USERNAME=spacedeck \
    STORAGE_PASSWORD=secret \
    DATABASE_URL=postgres://spacedeck:secret@postgres:5432/spacedeck

EXPOSE 9666

# Create entrypoint script
RUN echo '#!/bin/sh\n\
echo "Waiting for PostgreSQL..."\n\
while ! nc -z postgres 5432; do\n\
  sleep 1\n\
done\n\
echo "PostgreSQL started"\n\
echo "File structure:"\n\
ls -R /app/build\n\
node spacedeck.js' > /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]

