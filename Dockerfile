# ---------- STAGE 1: Builder ----------
FROM golang:1.21-alpine AS builder

# Install dependencies inclusief ca-certificates voor https
RUN apk add --no-cache git sqlite ca-certificates

WORKDIR /app

# Copy alle bestanden van je project
COPY . .

# Install templ met een vaste versie
RUN go install github.com/a-h/templ/cmd/templ@v0.3.865

# Download alle Go dependencies
RUN go mod tidy && go mod download

# Genereer de templ .go bestanden
RUN /go/bin/templ generate

WORKDIR /app/cmd

# Build je Go applicatie
RUN go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM alpine:latest

# Runtime dependencies
RUN apk add --no-cache sqlite ca-certificates

WORKDIR /root/

# Copy de Go binary van de builder stage
COPY --from=builder /go/bin/app .

CMD ["./app"]
