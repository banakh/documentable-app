FROM node:alpine
LABEL description="Instant high-performance GraphQL API for your PostgreSQL database https://github.com/graphile/postgraphile"

# Install PostGraphile and PostGraphile connection filter plugin
RUN npm install -g postgraphile
RUN npm install -g postgraphile-plugin-connection-filter
RUN npm install -g jaeger-client

# Install custom plugin
COPY ./tracing-plugin /tmp/tracing-plugin
RUN cd /tmp/tracing-plugin && npm pack
RUN npm install -g /tmp/tracing-plugin/tracing-plugin-0.0.1.tgz
RUN rm -rf /tmp/tracing-plugin

EXPOSE 5000
ENTRYPOINT ["postgraphile", "-n", "0.0.0.0"]
