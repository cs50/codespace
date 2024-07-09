#!/bin/bash

cleanup() {
  kill -TERM 1
}

# Wait for the rsession process to start
while ! pgrep -x "rsession" > /dev/null; do
  sleep 1
done

# Monitor the rsession process
while true; do
  if pgrep -x "rsession" > /dev/null; then
    sleep 1
  else
    # If the rsession process is not running for more than 10 seconds, terminate the container
    # Restarting R session shouldn't take more than 10 seconds
    sleep 10
    if ! pgrep -x "rsession" > /dev/null; then
      cleanup
    fi
  fi
done
