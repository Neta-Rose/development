# Lambda container image for the plate detector.
#
# The binary is an ordinary net/http server — nothing in `server/` knows it runs on
# Lambda. AWS Lambda Web Adapter is an /opt/extensions binary that speaks the Lambda
# Runtime API and forwards each invocation to the server on $PORT, so this stays a
# plain HTTP service that also runs under `go run .` and in any container host.
#
# The builder stage is pinned to $BUILDPLATFORM and cross-compiles, so building the
# arm64 image on an x86 runner needs no QEMU: the only foreign layer is the final
# one, and nothing in it executes at build time.

FROM --platform=$BUILDPLATFORM public.ecr.aws/docker/library/golang:1.24-alpine AS build
WORKDIR /src
# Copy go.mod and go.sum first to cache dependency downloads.
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 \
    go build -trimpath -ldflags="-s -w" -o /plated .

FROM public.ecr.aws/awsguru/aws-lambda-adapter:1.0.1 AS lwa

# Base images come from public.ecr.aws rather than Docker Hub: no pull rate limits,
# and one less registry for the deploy to depend on.
FROM public.ecr.aws/docker/library/alpine:3.21
COPY --from=lwa /lambda-adapter /opt/extensions/lambda-adapter
COPY --from=build /plated /plated

# /healthz answers 200 unconditionally, including before AI_API_KEY exists —
# so the adapter reports ready even on a deploy whose secret is not wired up yet.
ENV PORT=8080 \
    AWS_LWA_READINESS_CHECK_PATH=/healthz

ENTRYPOINT ["/plated"]
