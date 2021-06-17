ARG           FROM_IMAGE_BUILDER=ghcr.io/dubo-dubon-duponey/base:builder-bullseye-2021-06-01@sha256:addbd9b89d8973df985d2d95e22383961ba7b9c04580ac6a7f406a3a9ec4731e
ARG           FROM_IMAGE_RUNTIME=ghcr.io/dubo-dubon-duponey/base:runtime-bullseye-2021-06-01@sha256:a2b1b2f69ed376bd6ffc29e2d240e8b9d332e78589adafadb84c73b778e6bc77

#######################
# Extra builder for healthchecker
#######################
FROM          --platform=$BUILDPLATFORM $FROM_IMAGE_BUILDER                                                             AS builder-healthcheck

ARG           GIT_REPO=github.com/dubo-dubon-duponey/healthcheckers
ARG           GIT_VERSION=51ebf8c
ARG           GIT_COMMIT=51ebf8ca3d255e0c846307bf72740f731e6210c3
ARG           GO_BUILD_SOURCE=./cmd/http
ARG           GO_BUILD_OUTPUT=http-health
ARG           GO_LD_FLAGS="-s -w"
ARG           GO_TAGS="netgo osusergo"

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone --recurse-submodules git://"$GIT_REPO" . && git checkout "$GIT_COMMIT"
ARG           GOOS="$TARGETOS"
ARG           GOARCH="$TARGETARCH"

# hadolint ignore=SC2046
RUN           env GOARM="$(printf "%s" "$TARGETVARIANT" | tr -d v)" go build -trimpath $(if [ "$CGO_ENABLED" = 1 ]; then printf "%s" "-buildmode pie"; fi) \
                -ldflags "$GO_LD_FLAGS" -tags "$GO_TAGS" -o /dist/boot/bin/"$GO_BUILD_OUTPUT" "$GO_BUILD_SOURCE"

#######################
# Goello
#######################
FROM          --platform=$BUILDPLATFORM $FROM_IMAGE_BUILDER                                                             AS builder-goello

ARG           GIT_REPO=github.com/dubo-dubon-duponey/goello
ARG           GIT_VERSION=3799b60
ARG           GIT_COMMIT=3799b6035dd5c4d5d1c061259241a9bedda810d6
ARG           GO_BUILD_SOURCE=./cmd/server
ARG           GO_BUILD_OUTPUT=goello-server
ARG           GO_LD_FLAGS="-s -w"
ARG           GO_TAGS="netgo osusergo"

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone --recurse-submodules git://"$GIT_REPO" . && git checkout "$GIT_COMMIT"
ARG           GOOS="$TARGETOS"
ARG           GOARCH="$TARGETARCH"

# hadolint ignore=SC2046
RUN           env GOARM="$(printf "%s" "$TARGETVARIANT" | tr -d v)" go build -trimpath $(if [ "$CGO_ENABLED" = 1 ]; then printf "%s" "-buildmode pie"; fi) \
                -ldflags "$GO_LD_FLAGS" -tags "$GO_TAGS" -o /dist/boot/bin/"$GO_BUILD_OUTPUT" "$GO_BUILD_SOURCE"

#######################
# Caddy
#######################
FROM          --platform=$BUILDPLATFORM $FROM_IMAGE_BUILDER                                                             AS builder-caddy

# This is 2.4.0
ARG           GIT_REPO=github.com/caddyserver/caddy
ARG           GIT_VERSION=v2.4.0
ARG           GIT_COMMIT=bc2210247861340c644d9825ac2b2860f8c6e12a
ARG           GO_BUILD_SOURCE=./cmd/caddy
ARG           GO_BUILD_OUTPUT=caddy
ARG           GO_LD_FLAGS="-s -w"
ARG           GO_TAGS="netgo osusergo"

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone --recurse-submodules git://"$GIT_REPO" . && git checkout "$GIT_COMMIT"
ARG           GOOS="$TARGETOS"
ARG           GOARCH="$TARGETARCH"

# hadolint ignore=SC2046
RUN           env GOARM="$(printf "%s" "$TARGETVARIANT" | tr -d v)" go build -trimpath $(if [ "$CGO_ENABLED" = 1 ]; then printf "%s" "-buildmode pie"; fi) \
                -ldflags "$GO_LD_FLAGS" -tags "$GO_TAGS" -o /dist/boot/bin/"$GO_BUILD_OUTPUT" "$GO_BUILD_SOURCE"

#######################
# Builder custom
#######################
# XXX mirror is suboptimal - it fails at the first network error, and does not "resume" the state - now favoring docker-aptly instead
#FROM          --platform=$BUILDPLATFORM $FROM_IMAGE_BUILDER                                                             AS xxx-builder-mirror

# April 2020
#ARG           GIT_REPO=github.com/cybozu-go/aptutil
#ARG           GIT_COMMIT=3f82d83844818cdd6a6d7dca3eca0f76d8a3fce5

#WORKDIR       $GOPATH/src/$GIT_REPO
#RUN           git clone --recurse-submodules git://"$GIT_REPO" . && git checkout "$GIT_COMMIT"
# hadolint ignore=SC2046
#RUN           go build -trimpath -ldflags "-s -w" \
#                -o /dist/boot/bin/apt-mirror ./cmd/go-apt-mirror/main.go

#######################
# Main builder
#######################
FROM          --platform=$BUILDPLATFORM $FROM_IMAGE_BUILDER                                                             AS builder-main

ARG           GIT_REPO=github.com/cybozu-go/aptutil
ARG           GIT_VERSION=v1.4.2
ARG           GIT_COMMIT=0fc68affdeb0ca68409a17f2f712ab63b7c70b4a
ARG           GO_BUILD_SOURCE=./cmd/go-apt-cacher/main.go
ARG           GO_BUILD_OUTPUT=apt-cacher
ARG           GO_LD_FLAGS="-s -w"
ARG           GO_TAGS="netgo osusergo"

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone --recurse-submodules git://"$GIT_REPO" . && git checkout "$GIT_COMMIT"
ARG           GOOS="$TARGETOS"
ARG           GOARCH="$TARGETARCH"

# hadolint ignore=SC2046
RUN           env GOARM="$(printf "%s" "$TARGETVARIANT" | tr -d v)" go build -trimpath $(if [ "$CGO_ENABLED" = 1 ]; then printf "%s" "-buildmode pie"; fi) \
                -ldflags "$GO_LD_FLAGS" -tags "$GO_TAGS" -o /dist/boot/bin/"$GO_BUILD_OUTPUT" "$GO_BUILD_SOURCE"

#######################
# Builder assembly
#######################
FROM          $FROM_IMAGE_BUILDER                                                                                       AS builder

COPY          --from=builder-healthcheck /dist/boot/bin /dist/boot/bin
COPY          --from=builder-goello /dist/boot/bin /dist/boot/bin
COPY          --from=builder-caddy /dist/boot/bin /dist/boot/bin
COPY          --from=builder-main /dist/boot/bin /dist/boot/bin

RUN           chmod 555 /dist/boot/bin/*; \
              epoch="$(date --date "$BUILD_CREATED" +%s)"; \
              find /dist/boot/bin -newermt "@$epoch" -exec touch --no-dereference --date="@$epoch" '{}' +;

#######################
# Running image
#######################
FROM          $FROM_IMAGE_RUNTIME                                                                                       AS runtime

COPY          --from=builder --chown=$BUILD_UID:root /dist /

### Front server configuration
# Port to use
ENV           PORT=4443
EXPOSE        4443
# Log verbosity for
ENV           LOG_LEVEL="warn"
# Domain name to serve
ENV           DOMAIN="apt-cache.local"
# Control wether tls is going to be "internal" (eg: self-signed), or alternatively an email address to enable letsencrypt
ENV           TLS="internal"

# Realm in case access is authenticated
ENV           REALM="My Precious Realm"
# Provide username and password here (call the container with the "hash" command to generate a properly encrypted password, otherwise, a random one will be generated)
ENV           USERNAME=""
ENV           PASSWORD=""

### mDNS broadcasting
# Enable/disable mDNS support
ENV           MDNS_ENABLED=false
# Name is used as a short description for the service
ENV           MDNS_NAME="Apt Cache mDNS display name"
# The service will be annonced and reachable at $MDNS_HOST.local
ENV           MDNS_HOST="apt-cache"
# Type to advertise
ENV           MDNS_TYPE="_http._tcp"

# Caddy certs will be stored here
VOLUME        /certs

# Caddy uses this
VOLUME        /tmp

# Apt-cacher will use this
VOLUME        /data

ENV           HEALTHCHECK_URL="http://127.0.0.1:10000/?healthcheck"

HEALTHCHECK   --interval=120s --timeout=30s --start-period=10s --retries=1 CMD http-health || exit 1
