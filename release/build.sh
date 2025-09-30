#!/bin/sh

[ -z "$GOARCH" ] && { echo "GOARCH is not set"; exit 1; }
[ -z "$GOOS" ] && { echo "GOOS is not set"; exit 1; }

export CGO_ENABLED=0

mkdir -p "build/$GOARCH-$GOOS"

go build -ldflags="-s -w" -o "build/$GOARCH-$GOOS/client" gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/webtunnel/main/client
go build -ldflags="-s -w" -o "build/$GOARCH-$GOOS/server" gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/webtunnel/main/server

