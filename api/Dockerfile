FROM node:26-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

# running as a user, not root
USER 1000:1000

EXPOSE 3000

CMD ["node", "index.js"]
