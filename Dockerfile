# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

RUN apt-get update && apt-get install -y git sqlite3 ca-certificates

WORKDIR /app

# Kopieer alleen go.mod en go.sum eerst (voor caching van dependencies)
COPY go.mod go.sum ./

# Download modules (zal gecached worden zolang go.mod en go.sum niet veranderen)
RUN go mod tidy && go mod download

# Nu de rest van de code kopiëren
COPY . .

# Installeer templ tool
RUN go install github.com/a-h/templ/cmd/templ@latest

# Genereer code eerst
RUN /go/bin/templ generate

# Build de applicatie met CGO enabled
WORKDIR /app/cmd
RUN CGO_ENABLED=1 go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
