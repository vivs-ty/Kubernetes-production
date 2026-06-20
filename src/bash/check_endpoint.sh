#!/bin/bash

check_endpoint() {
    local url=$1

    if [ -z "$url" ]; then
        echo "Error: URL parameter missing"
        return 1
    fi

    # Suppress output, follow redirects, fail silently on server errors, 2 sec timeout
    if curl -sSfL -m 2 "$url" > /dev/null; then
        echo "Connection successful to $url"
        return 0
    else
        echo "Host unreachable or connection failed: $url"
        return 1
    fi
}
