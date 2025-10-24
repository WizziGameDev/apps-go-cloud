# Stage 1: Build
FROM golang:1.25.1-alpine AS builder

WORKDIR /app

# Copy go.mod & go.sum, download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build binary
RUN go build -o main .

# Stage 2: Run Build to docker image
FROM alpine:latest

WORKDIR /root/

# Copy binary dari builder
COPY --from=builder /app/main .

# Set environment variable default
ENV PORT=8000

# Expose port
EXPOSE 8000

# Jalankan aplikasi
CMD ["./main"]
