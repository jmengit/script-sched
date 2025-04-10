#!/bin/bash
set -e

# ---------------------------
# 1. Set the Timezone
# ---------------------------
echo "Configuring timezone to ${TZ}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo "${TZ}" > /etc/timezone

# # ---------------------------
# # 2. Set Up User for File Permissions (if PUID and PGID provided)
# # ---------------------------
# if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
#     echo "Setting up user 'appuser' with UID=${PUID} and GID=${PGID}"
#     # Create a group named "appgroup" with the provided PGID.
#     addgroup -g "${PGID}" appgroup || true
#     # Create a user named "appuser" with the provided PUID and add to appgroup.
#     adduser -D -u "${PUID}" -G appgroup appuser || true
#     # Ensure /scripts is owned by appuser so files touched here have the desired permissions.
#     chown -R appuser:appgroup /scripts
# else
#     echo "PUID or PGID not provided; running as root."
# fi

# ---------------------------
# 3. Execute Startup Scripts from /scripts
# ---------------------------
echo "Executing startup scripts from /scripts..."
if [ -d /scripts ]; then
  for script in /scripts/*; do
    if [ -x "$script" ]; then
      if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
          echo "Running $script as appuser"
          su-exec appuser /bin/bash "$script"
      else
          echo "Running $script as root"
          /bin/bash "$script"
      fi
    else
      echo "Skipping $script (not executable)"
    fi
  done
else
  echo "Warning: /scripts directory not found."
fi

# ---------------------------
# 4. Set Up and Run Cron (if CRON_SCHEDULE provided)
# ---------------------------
if [ -n "${CRON_SCHEDULE}" ]; then
    echo "Configuring cron job with schedule: ${CRON_SCHEDULE}"
    if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
        CRON_CMD="cd /scripts && for script in *; do [ -x \"\$script\" ] && su-exec appuser /bin/bash \"\$script\"; done"
    else
        CRON_CMD="cd /scripts && for script in *; do [ -x \"\$script\" ] && /bin/bash \"\$script\"; done"
    fi
    echo "${CRON_SCHEDULE} ${CRON_CMD}" > /etc/crontabs/root
    chmod 0644 /etc/crontabs/root

    echo "Starting cron daemon in the foreground..."
    exec crond -f
else
    echo "No CRON_SCHEDULE provided; cron will not be started."
    # Keep the container running for inspection/logging purposes.
    tail -f /dev/null
fi
