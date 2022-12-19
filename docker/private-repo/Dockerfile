FROM docker:20.10.22-dind

WORKDIR /app

COPY generate-docker-config.sh /generate-docker-config.sh

RUN chmod a+x /generate-docker-config.sh
ENTRYPOINT ["/generate-docker-config.sh"]
