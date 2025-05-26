# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

# Alleen wat nodig is voor de build
RUN apt-get update && apt-get install -y git ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Alleen dependency files kopiëren voor cache
COPY go.mod go.sum ./
RUN go mod download

# Installeer specifieke templ versie
RUN go install github.com/a-h/templ@v0.2.584

# Rest van de app kopiëren
COPY . .

# Genereer templ-code
RUN /go/bin/templ generate

# Build direct met target-dir
RUN CGO_ENABLED=1 go build -o /go/bin/app ./cmd

# ---------- STAGE 2: Runtime ----------
FROM debian:bookworm-slim

# Alleen wat runtime nodig heeft
RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
