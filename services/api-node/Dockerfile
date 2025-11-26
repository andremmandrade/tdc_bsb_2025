FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
# Install all deps (including dev) for tests; use npm install since lockfile absent
RUN npm install
COPY src ./src
COPY tests ./tests
# Run unit tests; fail build if they fail
RUN npm test
# Remove dev dependencies to slim the final image
RUN npm prune --omit=dev

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=3000
COPY --from=build /app /app
EXPOSE 3000
CMD ["node", "src/server.js"]