FROM debian:latest as rtg_deps

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libpng-dev libgd-dev libsnmp-dev libltdl-dev default-libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

FROM rtg_deps as build

ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_WORKERS 8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates git-core autoconf automake build-essential flex bison && \
    rm -rf /var/lib/apt/lists/*

# Build rtg2
RUN mkdir /build && \
    git clone https://github.com/logan2211/RTG2 /build

WORKDIR /build

RUN ./bootstrap.sh && \
    CFLAGS="-g -O2 -fcommon" ./configure --prefix /tmp/target && \
    make && make install

FROM rtg_deps as final

LABEL maintainer="Logan V. <logan2211@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive

ENV TINI_VERSION v0.19.0
ARG TARGETARCH=amd64
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY --from=build /tmp/target /usr/local

RUN ldconfig

ENTRYPOINT ["/tini", "--"]
