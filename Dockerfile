FROM node:lts-bookworm-slim AS build
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies
RUN apt-get update || : && apt-get install -y openssl git
RUN npm install

COPY . .

RUN npm run clean

CMD ["npm", "run", "server", "-p", "4000", "--debug", "--draft"]