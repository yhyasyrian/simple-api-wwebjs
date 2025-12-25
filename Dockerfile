FROM lscr.io/linuxserver/chromium:latest

# Set environment variables for Puppeteer and Chromium
ENV DEBIAN_FRONTEND=noninteractive \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium" \
    CHROME_PATH="/usr/bin/chromium" \
    PDF_CHROME_PATH="/usr/bin/chromium" \
    PUPPETEER_ARGS="--no-sandbox --disable-setuid-sandbox --disable-gpu --disable-dev-shm-usage"

# Install Node.js 22 (using NodeSource repository)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create non-root user for security (prevents running as root)
# Using PUID/PGID 1000 to match LinuxServer.io convention
# Safely create user/group only if not exists (to avoid conflicts with pre-existing GID/UID 1000)
RUN getent group 1000 || groupadd -g 1000 whatsapp && \
    getent passwd 1000 || useradd -r -u 1000 -g 1000 -m -d /home/whatsapp -s /bin/bash whatsapp

# Create necessary directories for WhatsApp Web.js session storage
RUN mkdir -p session .wwebjs_cache /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Install runuser for switching users in entrypoint
RUN apt-get update && \
    apt-get install -y --no-install-recommends util-linux && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script for fixing permissions on mounted volumes
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set ownership of app directory to whatsapp user
RUN chown -R whatsapp:whatsapp /app || true && \
    chmod -R 755 /app

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm i --only=production && npm cache clean --force

# Copy application files
COPY . .

# Set ownership again after copying files
RUN chown -R whatsapp:whatsapp /app || true

# Set entrypoint (runs as root to fix permissions, then switches to whatsapp user)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Expose application port (default 3000, can be overridden via PORT env var)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]