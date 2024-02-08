FROM docker:25.0.3-dind

WORKDIR /app

COPY generate-docker-config.sh /generate-docker-config.sh

RUN chmod a+x /generate-docker-config.sh
ENTRYPOINT ["/generate-docker-config.sh"]
