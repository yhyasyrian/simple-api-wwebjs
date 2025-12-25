#!/bin/bash
set -e

# Get PUID and PGID from environment variables (default to 1000)
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Fix permissions for mounted volumes
# This ensures the whatsapp user can write to the session and cache directories
if [ -d "/app/session" ]; then
    chown -R ${PUID}:${PGID} /app/session 2>/dev/null || true
    chmod -R 755 /app/session 2>/dev/null || true
fi

if [ -d "/app/.wwebjs_cache" ]; then
    chown -R ${PUID}:${PGID} /app/.wwebjs_cache 2>/dev/null || true
    chmod -R 755 /app/.wwebjs_cache 2>/dev/null || true
fi

# Switch to whatsapp user and execute the main command
# Use runuser if available, otherwise use su
if command -v runuser > /dev/null 2>&1; then
    exec runuser -u whatsapp -- "$@"
elif command -v su-exec > /dev/null 2>&1; then
    exec su-exec whatsapp "$@"
else
    exec su -s /bin/bash -c "exec \"\$@\"" whatsapp -- "$@"
fi

