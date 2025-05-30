FROM node:18-slim AS base
WORKDIR /app

# Install pnpm first, then copy files (mirroring api-tool-backend)
RUN npm install -g pnpm

COPY package.json /app/package.json
COPY pnpm-lock.yaml /app/pnpm-lock.yaml

RUN pnpm install --frozen-lockfile # Use frozen lockfile for reproducibility

FROM base AS build
# node_modules are already correctly installed in the base stage
COPY . .
RUN ls -la /app
RUN ls -la /app/migrations
RUN pnpm build

FROM node:18-slim AS production
WORKDIR /app

# Install pnpm in the production stage as well, so it can run migrate:up script
RUN npm install -g pnpm

COPY --from=build /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json /app/package.json
COPY --from=base /app/pnpm-lock.yaml /app/pnpm-lock.yaml
COPY --from=build /app/migrations /app/migrations

# Run database migrations
# RUN pnpm migrate:up # Moved to CMD

ENV NODE_ENV=production
EXPOSE 3000

CMD ["sh", "-c", "pnpm migrate:up && node dist/index.js"]
