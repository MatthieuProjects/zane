# Install dependencies only when needed
FROM docker.io/node:lts-alpine as deps
WORKDIR /usr/src/app
COPY ./package.json ./
RUN npm install --only=production

FROM docker.io/node:lts-alpine as runner
ENV NODE_ENV production

WORKDIR /usr/src/app
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=deps /usr/src/app/package.json ./package.json
COPY dist/packages/zane-worker .
RUN chown -R node:node .
USER node

CMD [ "node", "main.js"]
