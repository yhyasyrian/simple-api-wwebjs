FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000
# Install nodejs
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y nano vim curl wget git net-tools iputils-ping
RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt-get install -y nodejs

# Install a real browser binary (Google Chrome deb). Ubuntu's chromium packages often require snap, which won't work in Docker.
RUN apt-get update -y && apt-get install -y --no-install-recommends ca-certificates wget gnupg \
 && wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-linux-signing-keyring.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

# Runtime deps for Chrome
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libgbm-dev \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgcc1 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    ca-certificates \
    fonts-liberation \
    libnss3 \
    lsb-release \
    xdg-utils \
    wget \
    libasound2t64 \
 && rm -rf /var/lib/apt/lists/*

# Create a non-root user that matches the host UID/GID (for volume permissions)
RUN groupadd -g $GID whatsapp && useradd -m -u $UID -g $GID -s /bin/bash whatsapp

# Ensure Puppeteer has a sane default; main.js will still auto-detect if this path differs.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
# init project
WORKDIR /app
COPY . .
RUN npm install
RUN chown -R $UID:$GID /app
EXPOSE 3000
USER whatsapp
# Start the application
CMD ["npm", "start"]
