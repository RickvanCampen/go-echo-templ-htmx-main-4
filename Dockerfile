# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

# Install dependencies including gcc and musl-dev for CGO
RUN apt-get update && apt-get install -y git sqlite3 ca-certificates gcc libc6-dev

WORKDIR /app

COPY . .

RUN go install github.com/a-h/templ/cmd/templ@latest

RUN /go/bin/templ generate

RUN go mod tidy && go mod download

WORKDIR /app/cmd

# Zet CGO_ENABLED=1 en build voor Linux
RUN CGO_ENABLED=1 GOOS=linux go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
