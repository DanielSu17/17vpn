FROM golang:1.16-alpine

ENV GO111MODULE off
RUN apk add --no-cache git && \
    go get github.com/BurntSushi/cmd && \
    go get github.com/17media/configv3

WORKDIR $GOPATH/src/github.com/17media/configv3/pusher
RUN go build -o /opt/pusher

FROM alpine:3.9
RUN apk add --no-cache git
COPY --from=0 /opt/pusher /opt/
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
