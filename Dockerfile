# Lightweight Linux base image
FROM alpine:3.20

LABEL description="DevOps diagnostic tool"

# bash is the only extra package needed; getent, timeout, awk and nproc
# are already provided by Alpine's busybox and musl-utils
RUN apk add --no-cache bash

WORKDIR /app

# Copy only the application into the image
COPY app/ /app/

RUN chmod +x /app/app.sh

# Run as a non-root user for better security
RUN adduser -D -H appuser
USER appuser

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD ["/app/app.sh", "help"]

# "docker run devops-tool <command>" runs "app.sh <command>"
ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
