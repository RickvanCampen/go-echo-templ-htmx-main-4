# ---------- STAGE 1: Builder ----------
FROM golang:1.24-alpine AS builder

# Dependencies voor build
RUN apk add --no-cache git sqlite ca-certificates

WORKDIR /app

# Kopieer alle bestanden
COPY . .

# Installeer templ tool
RUN go install github.com/a-h/templ/cmd/templ@latest

# Genereer code eerst
RUN /go/bin/templ generate

# Daarna module dependencies netjes ophalen
RUN go mod tidy && go mod download

# Build de applicatie
WORKDIR /app/cmd
RUN go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM alpine:latest

RUN apk add --no-cache sqlite ca-certificates

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]
