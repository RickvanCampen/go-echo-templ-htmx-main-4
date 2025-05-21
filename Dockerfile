# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y git sqlite3 ca-certificates

WORKDIR /app

# Kopieer eerst alleen dependency-bestanden voor betere caching
COPY go.mod go.sum ./
RUN go mod tidy && go mod download

# Kopieer nu de rest van je applicatie
COPY . .

# Installeer templ tool
RUN go install github.com/a-h/templ/cmd/templ@latest

# Genereer templ-bestanden
RUN /go/bin/templ generate

# Build de applicatie met CGO enabled
WORKDIR /app/cmd
RUN CGO_ENABLED=1 go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bookworm-slim

# Installeer runtime dependencies
RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

# Kopieer de binary uit de builder
COPY --from=builder /go/bin/app .

# Start de app
CMD ["./app"]
