FROM debian:bookworm-slim AS builder

ARG DMD_VERSION=dmd-2.112.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    unzip \
    xz-utils \
    gcc \
    g++ \
    make \
    libc6-dev \
    pkg-config \
    ca-certificates \
    libssl-dev \
    libevent-dev \
    zlib1g-dev \
    ldc \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-lc"]

RUN mkdir -p /root/dlang \
    && curl -fsS https://dlang.org/install.sh -o /root/dlang/install.sh \
    && bash /root/dlang/install.sh install ${DMD_VERSION}

ENV DLANG_HOME=/root/dlang
ENV PATH="/root/dlang/${DMD_VERSION}/linux/bin64:${PATH}"

WORKDIR /app

COPY dub.json ./
COPY dub.selections.json ./
COPY source ./source
COPY resources ./resources

RUN source /root/dlang/${DMD_VERSION}/activate \
    && dmd --version \
    && ldc2 --version \
    && dub --version \
    && dub build --config=preprocess --build=release --compiler=dmd \
    && ./bin/preprocess \
    && dub build --config=app --build=release --compiler=dmd

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       libcurl4 \
       libevent-2.1-7 \
       openssl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/bin/app /app/app
COPY --from=builder /app/resources/references.bin /app/resources/references.bin
COPY --from=builder /app/resources/mcc_risk.json /app/resources/mcc_risk.json

EXPOSE 8080

ENV PORT=8080

CMD ["/app/app"]