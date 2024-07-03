FROM node:lts-bookworm-slim AS build
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies
RUN apt-get update || : && apt-get install -y vim git openssh-client
RUN npm install

# Guide SSH user agent for this specific repo
RUN mkdir ~/.ssh && printf 'Host personal.github.com\n  HostName github.com' >> ~/.ssh/config

COPY . .

RUN npm run clean

CMD ["npm", "run", "server", "-p", "4000", "--debug", "--draft"]