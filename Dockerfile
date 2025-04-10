# Use an official Alpine image
FROM alpine:3.18

# Install required packages:
# - bash, python3: for running scripts
# - tzdata: for timezone configuration
# - curl: for additional HTTP capabilities
# - cronie: for cron daemon
# - su-exec: to drop privileges and run commands as a non-root user
# - docker-cli: to interact with the Docker host (e.g., to restart containers)
RUN apk update && \
    apk add --no-cache bash python3 tzdata curl cronie su-exec docker-cli

# Set default environment variables. These can be overridden at runtime.
ENV CRON_SCHEDULE="* * * * *" \
    TZ="UTC" \
    PUID=1000 \
    PGID=1000

# Copy the entrypoint script into the image and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Declare a volume for mounting your scripts (host folder mapped to /scripts)
VOLUME ["/scripts"]

# Set the entrypoint script so it runs at container startup
ENTRYPOINT ["/entrypoint.sh"]
