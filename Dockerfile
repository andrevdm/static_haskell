FROM alpine AS base

RUN apk update && \
    apk add bash perl alpine-sdk wget curl libc-dev xz


################################################################################
# Intermediate layer that assembles 'stack' tooling
FROM base AS stack

ENV STACK_VERSION=1.9.3
ENV STACK_SHA256="c9bf6d371b51de74f4bfd5b50965966ac57f75b0544aebb59ade22195d0b7543  stack-${STACK_VERSION}-linux-x86_64-static.tar.gz"

RUN echo "Downloading stack" &&\
    cd /tmp &&\
    wget -P /tmp/ "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64-static.tar.gz" &&\
    if ! echo -n "${STACK_SHA256}" | sha256sum -c -; then \
        echo "stack-${STACK_VERSION} checksum failed" >&2 &&\
        exit 1 ;\
    fi ;\
    tar -xvzf /tmp/stack-${STACK_VERSION}-linux-x86_64-static.tar.gz &&\
    cp -L /tmp/stack-${STACK_VERSION}-linux-x86_64-static/stack /usr/bin/stack &&\
    rm /tmp/stack-${STACK_VERSION}-linux-x86_64-static.tar.gz &&\
    rm -rf /tmp/stack-${STACK_VERSION}-linux-x86_64-static
################################################################################


FROM stack

ENV GHC_VERSION=8.6.5
ENV GHC_INSTALL_PATH=/opt/ghc

RUN wget https://github.com/redneb/ghc-alt-libc/releases/download/ghc-${GHC_VERSION}-musl/ghc-${GHC_VERSION}-x86_64-unknown-linux-musl.tar.xz && \
    tar xf ghc-${GHC_VERSION}-x86_64-unknown-linux-musl.tar.xz

RUN apk update && \
    apk add bash perl alpine-sdk wget

WORKDIR ghc-${GHC_VERSION}

RUN ./configure --prefix=${GHC_INSTALL_PATH} && \
        make install

RUN apk add --no-cache vim emacs curl git libc-dev xz coreutils automake python3 zlib-dev shadow gmp-dev

ENV PATH=${GHC_INSTALL_PATH}/bin:$PATH

COPY --from=stack /usr/bin/stack /usr/bin/stack
RUN stack config set system-ghc --global true
