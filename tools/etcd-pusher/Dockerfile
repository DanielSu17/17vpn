FROM golang:1.11-alpine3.9

# HINT: upstream ugorji/go made an breaking change after 8c0409fc
# so we pinned version for temporary workaround.

RUN apk add --no-cache ca-certificates curl git openssh-client && \
    go get github.com/ugorji/go/codec && \
      cd $GOPATH/src/github.com/ugorji/go && \
      git checkout 8c0409fcbb70099c748d71f714529204975f6c3f && \
    go get github.com/BurntSushi/cmd && \
    go get github.com/csigo/config

WORKDIR $GOPATH/src/github.com/csigo/config/pusher
RUN go build -o /opt/pusher

FROM alpine:3.9
RUN apk add --no-cache ca-certificates curl git
COPY --from=0 /opt/pusher /opt/
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
