FROM docker:26.1.4-dind

WORKDIR /app

COPY generate-docker-config.sh /generate-docker-config.sh

RUN chmod a+x /generate-docker-config.sh
ENTRYPOINT ["/generate-docker-config.sh"]
