# ---------- STAGE 1: Builder ----------
FROM golang:1.21-alpine AS builder

# Install dependencies
RUN apk add --no-cache git sqlite

WORKDIR /app

# Copy code
COPY . .

# Install templ
RUN go install github.com/a-h/templ/cmd/templ@latest

# Download Go deps (after code is copied)
RUN go mod tidy && go mod download

# Run templ to generate .go files
RUN /go/bin/templ generate

WORKDIR /app/cmd

# Build the Go binary
RUN go build -o /go/bin/app

# ---------- STAGE 2: Runtime ----------
FROM alpine:latest

RUN apk add --no-cache sqlite

WORKDIR /root/

COPY --from=builder /go/bin/app .

CMD ["./app"]







