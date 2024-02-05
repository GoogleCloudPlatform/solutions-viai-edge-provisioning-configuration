FROM docker:25.0.2-dind

RUN apk add --no-cache curl bash python3 tar
WORKDIR /root

RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-404.0.0-linux-x86_64.tar.gz && \
        tar -xf /root/google-cloud-cli-404.0.0-linux-x86_64.tar.gz && \
        /root/google-cloud-sdk/install.sh

ENV PATH $PATH:/root/google-cloud-sdk/bin

COPY push-image.sh /push-image.sh

RUN chmod a+x /push-image.sh
ENTRYPOINT ["/push-image.sh"]
