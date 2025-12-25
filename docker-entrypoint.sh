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

# Get the username for the specified UID (fallback to whatsapp)
USERNAME=$(getent passwd ${PUID} | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    # If no user found with that UID, try to use whatsapp user
    if getent passwd whatsapp > /dev/null 2>&1; then
        USERNAME=whatsapp
    else
        echo "Error: No user found with UID ${PUID} or username 'whatsapp'" >&2
        exit 1
    fi
fi

# Switch to the user and execute the main command
# Use runuser if available, otherwise use su
if command -v runuser > /dev/null 2>&1; then
    exec runuser -u "$USERNAME" -- "$@"
elif command -v su-exec > /dev/null 2>&1; then
    exec su-exec "$USERNAME" "$@"
else
    exec su -s /bin/bash -c "exec \"\$@\"" "$USERNAME" -- "$@"
fi

