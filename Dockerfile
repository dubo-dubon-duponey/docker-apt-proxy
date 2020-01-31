#######################
# Extra builder for healthchecker
#######################
ARG           BUILDER_BASE=dubodubonduponey/base@sha256:b51f084380bc1bd2b665840317b6f19ccc844ee2fc7e700bf8633d95deba2819
ARG           RUNTIME_BASE=dubodubonduponey/base@sha256:d28e8eed3e87e8dc5afdd56367d3cf2da12a0003d064b5c62405afbe4725ee99
# hadolint ignore=DL3006
FROM          --platform=$BUILDPLATFORM $BUILDER_BASE                                                                   AS builder-healthcheck

ARG           GIT_REPO=github.com/dubo-dubon-duponey/healthcheckers
ARG           GIT_VERSION=51ebf8ca3d255e0c846307bf72740f731e6210c3

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone git://$GIT_REPO .
RUN           git checkout $GIT_VERSION
RUN           arch="${TARGETPLATFORM#*/}"; \
              env GOOS=linux GOARCH="${arch%/*}" go build -mod=vendor -v -ldflags "-s -w" -o /dist/boot/bin/http-health ./cmd/http

#######################
# Builder custom
#######################
# hadolint ignore=DL3006
FROM          --platform=$BUILDPLATFORM $BUILDER_BASE                                                                   AS builder

ARG           GIT_REPO=github.com/dubo-dubon-duponey/aptutil
ARG           GIT_VERSION=7f0cb3780c18e7ae5661c7655d4a65318f8c9c06
ARG           GO_LDFLAGS=""

WORKDIR       $GOPATH/src/$GIT_REPO
RUN           git clone git://$GIT_REPO .
RUN           git checkout $GIT_VERSION
RUN           arch="${TARGETPLATFORM#*/}"; \
              env GOOS=linux GOARCH="${arch%/*}" go build -mod=vendor -v -ldflags "-s -w $GO_LDFLAGS" -o /dist/boot/bin/apt-mirror ./cmd/go-apt-mirror/main.go

COPY          --from=builder-healthcheck /dist/boot/bin /dist/boot/bin
RUN           chmod 555 /dist/boot/bin/*

#######################
# Running image
#######################
# hadolint ignore=DL3006
FROM          $RUNTIME_BASE                                                                                             AS runtime

COPY          --from=builder --chown=$BUILD_UID:root /dist .

VOLUME        /data
#VOLUME [ "/var/lib/aptutil", "/var/spool/go-apt-mirror", "/var/spool/go-apt-cacher"]

#EXPOSE 3142

#WORKDIR "/var/lib/aptutil"
