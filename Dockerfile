# ---------- STAGE 1: Builder ----------
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git sqlite ca-certificates

WORKDIR /app

COPY . .

RUN go install github.com/a-h/templ/cmd/templ@latest

RUN go mod tidy && go mod download

RUN /go/bin/templ generate

WORKDIR /app/cmd

RUN go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM alpine:latest

RUN apk add --no-cache sqlite ca-certificates

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
