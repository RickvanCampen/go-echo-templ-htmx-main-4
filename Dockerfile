# ---------- STAGE 1: Builder ----------
FROM golang:1.24 AS builder

RUN apt-get update && apt-get install -y git sqlite3 ca-certificates

WORKDIR /app

# Kopieer alleen go.mod en go.sum (voor cache)
COPY go.mod go.sum ./

# Download Go module dependencies (cached zolang go.mod en go.sum niet veranderen)
RUN go mod tidy && go mod download

# Installeer templ tool (ook gecachet)
RUN go install github.com/a-h/templ/cmd/templ@latest

# Nu de rest van de app code kopiëren
COPY . .

# Genereer templ-code
RUN /go/bin/templ generate

# Build de app met CGO enabled (vereist voor go-sqlite3)
WORKDIR /app/cmd
RUN CGO_ENABLED=1 go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y sqlite3 ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
