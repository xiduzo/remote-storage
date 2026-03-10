###################
# BUILD FOR LOCAL DEVELOPMENT
###################

FROM node:18.13.0-bullseye AS build

RUN apt-get update && apt-get install -y openssl build-essential python3
RUN npm install -g pnpm

# Create app directory
WORKDIR /app

COPY ./certs /app/certs

# Copy application dependency manifests to the container image.
# A wildcard is used to ensure copying both package.json AND package-lock.json (when available).
# Copying this first prevents re-running pnpm install on every code change.
COPY --chown=node:node ./package*.json ./

RUN pnpm install

# Bundle app source
COPY --chown=node:node . .
# Optionally add your own certs to use https
RUN chown -R node:node /app/certs

# Use the node user from the image (instead of the root user)
USER node

###################
# BUILD FOR PRODUCTION
###################

FROM node:18.13.0-bullseye AS production-build

RUN apt-get update
RUN apt-get install -y openssl build-essential python3
RUN npm install -g pnpm

WORKDIR /app

COPY --chown=node:node ./package*.json /app/

# In order to run `pnpm run build` we need access to the Nest CLI which is a dev dependency.
# In the previous development stage we ran `pnpm install` which installed all dependencies, so we can copy over the node_modules directory from the development image
COPY --chown=node:node --from=build /app/node_modules /app/node_modules
COPY --chown=node:node --from=build /app/certs /app/certs
COPY --chown=node:node ./ ./

# Run the build command which creates the production bundle
RUN pnpm run build

# Set NODE_ENV environment variable

ENV NODE_ENV=production

# Prune to production dependencies only for a smaller final image
# sqlite3 compiles correctly thanks to onlyBuiltDependencies in package.json
RUN pnpm install --prod

###################
# PRODUCTION RUN
###################

FROM node:18.13.0-bullseye AS production

RUN apt-get update && apt-get install -y openssl

WORKDIR /app

# Copy the bundled code from the build stage to the production image
COPY --chown=node:node --from=production-build /app/node_modules /app/node_modules
COPY --chown=node:node --from=production-build /app/dist /app/dist
COPY --chown=node:node --from=production-build /app/certs /app/certs

# Entrypoint runs as root to fix /data permissions (volume mounts are often root-owned),
# then drops to node user. Run with cwd=/data so ./database.sqlite uses the volume.
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
