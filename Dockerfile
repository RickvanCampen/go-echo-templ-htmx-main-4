# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

RUN apt-get update && apt-get install -y git sqlite3 ca-certificates

WORKDIR /app

# Kopieer alleen dependency-files eerst (voor caching)
COPY go.mod go.sum ./

# Download Go dependencies (cached)
RUN go mod tidy && go mod download

# Installeer specifieke versie van templ (sneller & stabieler)
RUN go install github.com/a-h/templ/cmd/templ@v0.2.572

# Nu pas de rest van de code
COPY . .

# Genereer templ-code
RUN /go/bin/templ generate

# Build de app met CGO (voor sqlite3)
WORKDIR /app/cmd
RUN CGO_ENABLED=1 go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
