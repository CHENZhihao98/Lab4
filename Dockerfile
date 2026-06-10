FROM node:24-alpine
WORKDIR /app
COPY . .
RUN chown -R node:node /app
USER node
RUN npm install --omit=dev
CMD ["node", "app.js"]
EXPOSE 3000