FROM golang:1.17-alpine as builder

WORKDIR /
RUN apk add --no-cache git 
RUN git clone --depth 1 --branch v0.1.0 https://github.com/17media/configv3.git

WORKDIR /configv3/pusher
RUN go mod download 
RUN go build -o /opt/pusher

FROM alpine:3.9
RUN apk add --no-cache git
COPY --from=builder /opt/pusher /opt/
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
