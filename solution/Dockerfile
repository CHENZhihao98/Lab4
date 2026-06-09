FROM node:22-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY app.js .

USER node

EXPOSE 3000

CMD ["node", "app.js"]
