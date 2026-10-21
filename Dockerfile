# Stage 1: Build (runs on native platform, cross-compiles to target)
FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.26.10-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags="-s -w" \
    -trimpath \
    -o docker-credential-acr \
    .

# Stage 2: Runtime
FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/docker-credential-acr /docker-credential-acr

USER 65534:65534

ENTRYPOINT ["/docker-credential-acr"]
