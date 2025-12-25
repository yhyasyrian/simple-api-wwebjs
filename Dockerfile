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
# LinuxServer.io images typically have a user with UID 1000 (often named 'abc')
# Ensure a user with UID 1000 exists and try to name it 'whatsapp'
RUN if getent passwd 1000 > /dev/null 2>&1; then \
        # UID 1000 exists, try to rename to whatsapp if different
        EXISTING_USER=$(getent passwd 1000 | cut -d: -f1); \
        if [ "$EXISTING_USER" != "whatsapp" ]; then \
            usermod -l whatsapp -d /home/whatsapp -m "$EXISTING_USER" 2>/dev/null || true; \
        fi; \
    else \
        # UID 1000 doesn't exist, create whatsapp user with UID 1000
        (getent group 1000 > /dev/null 2>&1 || groupadd -g 1000 whatsapp) && \
        useradd -r -u 1000 -g 1000 -m -d /home/whatsapp -s /bin/bash whatsapp; \
    fi && \
    # Ensure whatsapp group exists with GID 1000
    (getent group 1000 > /dev/null 2>&1 || groupadd -g 1000 whatsapp)

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

# Set ownership of app directory to UID 1000 (whatsapp user)
RUN chown -R 1000:1000 /app || true && \
    chmod -R 755 /app

# Copy package files first for better Docker layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm i --only=production && npm cache clean --force

# Copy application files
COPY . .

# Set ownership again after copying files
RUN chown -R 1000:1000 /app || true

# Set entrypoint (runs as root to fix permissions, then switches to whatsapp user)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Expose application port (default 3000, can be overridden via PORT env var)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]