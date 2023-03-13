FROM ubuntu:23.04

RUN apt-get update \
    && apt-get \
    --no-install-recommends \
    --yes \
    install \
    cloud-image-utils \
    cloud-init \
    kpartx \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

ENV WORKDIR /tmp/workdir
WORKDIR ${WORKDIR}

COPY scripts/generate-cloud-init-cidata-iso.sh /generate-cloud-init-cidata-iso.sh

RUN chmod a+x /*.sh
ENTRYPOINT ["/generate-cloud-init-cidata-iso.sh"]
