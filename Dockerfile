FROM djaydev/krusader:latest

# Your custom commands
RUN apk upgrade --update-cache --available && \
    apk add systemsettings language-pack-kde-fr language-pack-kde-fr-base
#CMD ["/run.sh"]
