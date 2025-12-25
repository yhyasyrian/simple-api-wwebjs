FROM ubuntu:24.10

ARG UID=1000
ARG GID=1000
# Install nodejs
RUN apt update -y && apt upgrade -y && apt install -y nano vim curl wget git net-tools iputils-ping
RUN curl -sL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource_setup.sh
RUN bash /tmp/nodesource_setup.sh
RUN apt install nodejs
# install chromium
RUN apt install -y gconf-service libgbm-dev libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget
# init project
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
RUN chown -R $UID:$GID /app
EXPOSE 3000
USER $UID:$GID
# Start the application
CMD ["npm", "start"]
