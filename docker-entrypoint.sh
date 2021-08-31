#!/bin/sh

set -e

# Change uid/gid of radicale if vars specified
if [ -n "$UID" ] || [ -n "$GID" ]; then
    if [ ! "$UID" = "$(id radicale -u)" ] || [ ! "$GID" = "$(id radicale -g)" ]; then
        # Fail on read-only container
        if grep -e "\s/\s.*\sro[\s,]" /proc/mounts > /dev/null; then
            echo "You specified custom UID/GID (UID: $UID, GID: $GID)."
            echo "UID/GID can only be changed when not running the container with --read-only."
            echo "Please see the README.md for how to proceed and for explanations."
            exit 1
        fi

        if [ -n "$UID" ]; then
            usermod -o -u "$UID" radicale
        fi

        if [ -n "$GID" ]; then
            groupmod -o -g "$GID" radicale
        fi
    fi
fi

# If requested and running as root, mutate the ownership of bind-mounts
if [ "$(id -u)" = "0" ]; then
    echo "INFO fix ownership / permission issues for $(find /data ! -user "radicale" -or ! -perm -u=rw | wc -l) files"
    if ! find /data ! -user "radicale" -exec chown -R "radicale" "{}" \;; then
      echo "ERROR couldn't mutate ownership to radicale, did you provide --cap-add=CHOWN and is the volume writeable?"
      exit 10
    fi
    find /data ! -perm -u=rw -exec chmod u+rw "{}" \;
fi

# Run radicale as the "radicale" user or any other command if provided
if [ "$1" = "radicale" ]; then
    exec su-exec radicale "$@"
else
    exec "$@"
fi
