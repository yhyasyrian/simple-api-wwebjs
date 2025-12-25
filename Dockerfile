FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000
# Install nodejs
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y nano vim curl wget git net-tools iputils-ping
RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt-get install -y nodejs
# install chromium
RUN apt-get install -y \
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
    libasound2t64
# init project
WORKDIR /app
COPY . .
RUN npm install
RUN chown -R $UID:$GID /app
EXPOSE 3000
USER $UID:$GID
# Start the application
CMD ["npm", "start"]
