FROM node:22

# Set environment variables for Puppeteer and Chromium
ENV DEBIAN_FRONTEND=noninteractive \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium" \
    CHROME_PATH="/usr/bin/chromium" \
    PDF_CHROME_PATH="/usr/bin/chromium" \
    PUPPETEER_ARGS="--no-sandbox --disable-setuid-sandbox --disable-gpu --disable-dev-shm-usage"

# Install Chromium and required system dependencies for headless browser operation
# Debian/Ubuntu uses 'apt-get' package manager
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-sandbox \
    fonts-liberation \
    fonts-dejavu \
    fontconfig \
    fonts-noto-core \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create non-root user for security (prevents running as root)
# Debian uses 'groupadd' and 'useradd' instead of Alpine's 'addgroup' and 'adduser'
RUN groupadd -g 1001 whatsapp && \
    useradd -r -u 1001 -g whatsapp -m -d /home/whatsapp -s /bin/bash whatsapp



# Create necessary directories for WhatsApp Web.js session storage
RUN mkdir -p session .wwebjs_cache /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Set ownership of app directory to whatsapp user
RUN chown -R whatsapp:whatsapp /app && \
    chmod -R 755 /app

# Switch to non-root user for security
USER whatsapp

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm i --only=production && npm cache clean --force

# Copy application files
COPY . .

# Expose application port (default 3000, can be overridden via PORT env var)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]