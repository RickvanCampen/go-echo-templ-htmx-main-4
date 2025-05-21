# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

# Installeer dependencies voor build
RUN apt-get update && apt-get install -y git sqlite3 ca-certificates

WORKDIR /app

# Kopieer alle bestanden
COPY . .

# Installeer templ tool
RUN go install github.com/a-h/templ/cmd/templ@latest

# Genereer code eerst
RUN /go/bin/templ generate

# Download module dependencies
RUN go mod tidy && go mod download

# Build de applicatie met CGO enabled (nodig voor go-sqlite3)
WORKDIR /app/cmd
RUN CGO_ENABLED=1 go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bullseye-slim

# Installeer runtime dependencies
RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

# Kopieer de applicatie van de builder stage
COPY --from=builder /go/bin/app .

CMD ["./app"]
