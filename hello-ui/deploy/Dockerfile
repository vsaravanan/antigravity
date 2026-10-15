# Dockerfile for hello-ui (Next.js frontend)
# Built on k8master using: buildah bud -t hello-ui:latest -f deploy/Dockerfile .
#
# pnpm install and pnpm run build already happened externally by
# k8master-build-ui.sh before this runs, so this is a single stage -
# no separate builder/runner containers, just package and run.

FROM hello-ui-base:latest

COPY . .

# Install dependencies
RUN pnpm install --frozen-lockfile --ignore-scripts

RUN pnpm build

ENV NODE_ENV=production

EXPOSE 3030
# CMD ["pnpm","start","--","--port","3030"]
CMD ["sh","-c","pnpm start -p ${PORT:-3030}"]
